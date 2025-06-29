#!/bin/bash
# Setup environment variables for PNPM GitHub packages
# Source this file: source scripts/setup-env.sh

if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
    echo "✅ Environment variables loaded from .env"
    echo "NODE_AUTH_TOKEN is $(if [ -z "$NODE_AUTH_TOKEN" ]; then echo "not set"; else echo "set"; fi)"
else
    echo "⚠️  No .env file found"
fi