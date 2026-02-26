#!/bin/bash
set -e

# Create necessary directories if they don't exist
mkdir -p /home/node/.openclaw/identity
mkdir -p /home/node/.openclaw/workspace
mkdir -p /home/node/.openclaw/sessions
mkdir -p /home/node/.openclaw/credentials

# Execute the main command
exec "$@"
