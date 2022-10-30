# frozen_string_literal: true

NODES = %w[node01 node02 node03 node04 node05].freeze

# role :web, NODES
role :app, NODES
# role :cron, NODES
