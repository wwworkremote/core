# frozen_string_literal: true

# Screening-answer generation ranks a profile's experiences against the
# question before building a prompt. Term overlap can't do that job -- it has
# no morphology ("servers" misses "server") and no semantics ("MCP server
# tooling" misses "agentic workflows") -- so the ranking runs on embeddings,
# the same way every other semantic match in this app already does.
class AddEmbeddingToWorkExperiences < ActiveRecord::Migration[8.1]
  def change
    add_column :work_experiences, :embedding, :vector, limit: 768
  end
end
