#!/bin/sh
# validate-secrets.sh - Validates that required secrets are set and not empty

set -e

# Check if SECRET_KEY_BASE is set and not empty
if [ -z "$SECRET_KEY_BASE" ]; then
  echo "ERROR: SECRET_KEY_BASE is not set or is empty!"
  echo "Please copy .env.example to .env and set SECRET_KEY_BASE to a secure value."
  echo "Generate one with: openssl rand -hex 64"
  exit 1
fi

# Check if JWT_SECRET is set and not empty
if [ -z "$JWT_SECRET" ]; then
  echo "ERROR: JWT_SECRET is not set or is empty!"
  echo "Please copy .env.example to .env and set JWT_SECRET to a secure value."
  echo "Generate one with: openssl rand -hex 64"
  exit 1
fi

# Warn if using development/example secrets in production
if [ "$RAILS_ENV" = "production" ] && echo "$SECRET_KEY_BASE" | grep -q "development"; then
  echo "WARNING: You are using a development SECRET_KEY_BASE in production!"
  echo "This is a serious security risk. Generate a new secret with: openssl rand -hex 64"
  exit 1
fi

if [ "$RAILS_ENV" = "production" ] && echo "$JWT_SECRET" | grep -q "development"; then
  echo "WARNING: You are using a development JWT_SECRET in production!"
  echo "This is a serious security risk. Generate a new secret with: openssl rand -hex 64"
  exit 1
fi

echo "✓ Secret validation passed"

# Execute the command passed to this script
exec "$@"
