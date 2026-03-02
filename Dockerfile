# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.3.4
FROM ruby:${RUBY_VERSION}-slim

# Rails app lives here
WORKDIR /rails

# Set development environment
ENV RAILS_ENV="development" \
    BUNDLE_PATH="/usr/local/bundle"

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev nodejs yarn pkg-config curl && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
# We copy Gemfile only first to allow regeneration of lockfile if missing
COPY Gemfile ./
COPY blorgh ./blorgh

# Generate a fresh lockfile if it doesn't exist and install gems
RUN bundle lock --add-platform aarch64-linux x86_64-linux && \
    bundle install

# Copy application code
COPY . .

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default
EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
