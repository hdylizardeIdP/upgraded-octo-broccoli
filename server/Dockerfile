# Rails API Dockerfile
FROM ruby:3.3.6-alpine

# Install dependencies
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    tzdata \
    git \
    nodejs \
    npm

WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install

# Copy application code
COPY . .

# Create directories for Rails
RUN mkdir -p tmp/pids

# Expose port
EXPOSE 3000

# Start server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
