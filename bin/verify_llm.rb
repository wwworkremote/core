#!/usr/bin/env ruby
# frozen_string_literal: true

# bin/verify_llm.rb — Live validation of the llama.cpp inference server.
#
# Tests four layers in order:
#   1. Server health  — GET /health
#   2. Model alias    — GET /v1/models → 'local' must be present
#   3. Inference      — POST /v1/chat/completions, expects sentinel token
#   4. Embeddings     — POST /v1/embeddings, expects float vector
#
# Exits 0 only if all checks pass. Use in CI or pre-deploy:
#   ruby bin/verify_llm.rb || exit 1
#
# Usage:
#   ruby bin/verify_llm.rb            # default endpoint
#   OLLAMA_API_BASE=http://host:8080/v1 ruby bin/verify_llm.rb

require 'net/http'
require 'json'
require 'benchmark'
require 'uri'

BASE = (ENV.fetch('OLLAMA_API_BASE', 'http://127.0.0.1:8080/v1')).sub(%r{/v1/?$}, '')
MODEL = 'local'.freeze
SENTINEL = 'NEURAL_LINK_ESTABLISHED'.freeze
INFERENCE_TIMEOUT_S = 90  # cold start loads GGUF weights into Metal; allow extra headroom
EMBED_TIMEOUT_S     = 30
PASS = "\e[32mPASS\e[0m".freeze
FAIL = "\e[31mFAIL\e[0m".freeze

failures = []

def post_json(url, body, timeout)
  uri  = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.read_timeout = timeout
  req  = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
  req.body = body.to_json
  http.request(req)
end

def get_json(url, timeout = 5)
  uri  = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.read_timeout = timeout
  http.get(uri.path)
end

puts "=== llama.cpp Live Validation ==="
puts "Endpoint : #{BASE}"
puts "Model    : #{MODEL}"
puts

# ── 1. Health ──────────────────────────────────────────────────────────────
print "1. Health check (/health) ... "
begin
  res  = get_json("#{BASE}/health")
  data = JSON.parse(res.body) rescue {}
  if res.code == '200' && (data['status'] == 'ok' || data['status'] == 'loading model')
    puts PASS
  else
    puts "#{FAIL} (HTTP #{res.code}: #{res.body.strip.slice(0, 80)})"
    failures << "health"
  end
rescue => e
  puts "#{FAIL} (#{e.class}: #{e.message})"
  failures << "health"
end

# ── 2. Model alias ─────────────────────────────────────────────────────────
print "2. Model alias  (/v1/models) ... "
begin
  res  = get_json("#{BASE}/v1/models")
  data = JSON.parse(res.body) rescue {}
  ids  = Array(data['data']).map { |m| m['id'] }
  if ids.include?(MODEL)
    puts "#{PASS} (#{ids.join(', ')})"
  else
    puts "#{FAIL} — alias '#{MODEL}' not found; got: #{ids.inspect}"
    failures << "alias"
  end
rescue => e
  puts "#{FAIL} (#{e.class}: #{e.message})"
  failures << "alias"
end

# ── 3. Inference ───────────────────────────────────────────────────────────
print "3. Inference    (/v1/chat/completions) ... "
latency = nil
begin
  payload = {
    model: MODEL,
    messages: [
      { role: 'user',
        content: "Respond with the single token '#{SENTINEL}' and nothing else." }
    ],
    temperature: 0.0,
    max_tokens: 16,
    stream: false
  }
  latency = Benchmark.realtime do
    @infer_res = post_json("#{BASE}/v1/chat/completions", payload, INFERENCE_TIMEOUT_S)
  end
  data    = JSON.parse(@infer_res.body) rescue {}
  content = data.dig('choices', 0, 'message', 'content').to_s.strip
  if @infer_res.code == '200' && content.include?(SENTINEL)
    puts "#{PASS} (#{latency.round(2)}s — '#{content.slice(0, 40)}')"
  else
    puts "#{FAIL} (HTTP #{@infer_res.code}, response: '#{content.slice(0, 80)}')"
    failures << "inference"
  end
rescue Net::ReadTimeout
  puts "#{FAIL} (timeout after #{INFERENCE_TIMEOUT_S}s)"
  failures << "inference"
rescue => e
  puts "#{FAIL} (#{e.class}: #{e.message})"
  failures << "inference"
end

# ── 4. Embeddings ──────────────────────────────────────────────────────────
print "4. Embeddings   (/v1/embeddings) ... "
begin
  payload = { model: MODEL, input: "test embedding probe" }
  embed_latency = Benchmark.realtime do
    @embed_res = post_json("#{BASE}/v1/embeddings", payload, EMBED_TIMEOUT_S)
  end
  data      = JSON.parse(@embed_res.body) rescue {}
  embedding = data.dig('data', 0, 'embedding')
  if @embed_res.code == '200' && embedding.is_a?(Array) && embedding.length > 0
    puts "#{PASS} (#{embed_latency.round(2)}s — #{embedding.length}-dim vector, " \
         "first value: #{embedding[0].round(6)})"
  elsif @embed_res.code == '501'
    puts "#{FAIL} — server not started with --embeddings flag"
    failures << "embeddings"
  else
    puts "#{FAIL} (HTTP #{@embed_res.code}: #{@embed_res.body.to_s.slice(0, 80)})"
    failures << "embeddings"
  end
rescue Net::ReadTimeout
  puts "#{FAIL} (timeout after #{EMBED_TIMEOUT_S}s)"
  failures << "embeddings"
rescue => e
  puts "#{FAIL} (#{e.class}: #{e.message})"
  failures << "embeddings"
end

# ── Summary ────────────────────────────────────────────────────────────────
puts
if failures.empty?
  puts "\e[32m✓ All checks passed\e[0m  (inference #{latency&.round(2)}s)"
  exit 0
else
  puts "\e[31m✗ #{failures.length} check(s) failed: #{failures.join(', ')}\e[0m"
  puts "  Fix: llama-ctl status && llama-ctl restart"
  exit 1
end
