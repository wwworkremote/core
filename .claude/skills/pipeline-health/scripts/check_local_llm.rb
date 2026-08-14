# frozen_string_literal: true

#
# Check both local llama-server endpoints (chat + embed) are reachable, and
# that the embed server's actual output dimension matches this app's
# vector(N) schema. Run with:
#   bin/rails runner .claude/skills/pipeline-health/scripts/check_local_llm.rb
#
# Two separate llama-server instances are expected on this box: OLLAMA_API_BASE
# (chat, no --embeddings) and OLLAMA_EMBED_API_BASE (dedicated embed model).
# A dimension mismatch here means every embedding save will fail validation
# even though the HTTP call itself succeeds -- see JobBoards::Embedder and
# Resume::ProfileEmbedder. This is a zdots-managed service; if it's broken,
# `zdots-issue`, don't reconfigure it from here. Makes no writes.

require "net/http"
require "json"

def section(title)
  puts "\n=== #{title} ==="
  yield
end

def probe_chat(base)
  uri = URI("#{base}/models")
  res = Net::HTTP.get_response(uri)
  puts "#{base}/models -> #{res.code}"
rescue StandardError => e
  puts "#{base}/models -> unreachable (#{e.class}: #{e.message})"
end

def post_embedding_probe(base)
  uri = URI("#{base}/embeddings")
  req = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
  req.body = { input: "dimension probe", model: "local" }.to_json
  Net::HTTP.start(uri.host, uri.port) { |http| http.request(req) }
end

def embedding_dims_from(res)
  JSON.parse(res.body).dig("data", 0, "embedding")&.size
end

def report_embed_dims(base, res)
  return puts("#{base}/embeddings -> #{res.code} (not 200, can't probe dims)") unless res.code == "200"

  dims = embedding_dims_from(res)
  puts "#{base}/embeddings -> 200, #{dims} dims"
  dims
end

def probe_embed_dims(base)
  report_embed_dims(base, post_embedding_probe(base))
rescue StandardError => e
  puts "#{base}/embeddings -> unreachable (#{e.class}: #{e.message})"
  nil
end

chat_base = ENV.fetch("OLLAMA_API_BASE", "http://localhost:11500/v1")
embed_base = ENV.fetch("OLLAMA_EMBED_API_BASE", "http://localhost:11501/v1")

section("Chat server (#{chat_base})") { probe_chat(chat_base) }

live_dims = nil
section("Embed server (#{embed_base})") { live_dims = probe_embed_dims(embed_base) }

section("Schema vs live dimension") do
  schema_dims = JobPosting.columns_hash["embedding"]&.limit
  puts "JobPosting.embedding column: vector(#{schema_dims})"
  puts "Live embed server output:    #{live_dims || 'unknown'} dims"
  if live_dims && schema_dims && live_dims != schema_dims
    puts "MISMATCH -- every embedding save will fail ActiveRecord validation " \
         "until these match. See docs/extension-workflow.md or file a zdots-issue " \
         "if the embed server's model changed."
  elsif live_dims && schema_dims
    puts "OK -- dimensions match."
  end
end

section("Embedding coverage (JobPosting)") do
  total = JobPosting.count
  with_embedding = JobPosting.where.not(embedding: nil).count
  puts "#{with_embedding} / #{total} have an embedding"
end
