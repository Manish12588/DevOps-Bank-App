#!/bin/sh
set -e

case "$ROLE" in
  frontend)
    echo "Starting Nginx (frontend)..."
    exec nginx -g "daemon off;"
    ;;
  backend)
    echo "Starting Node.js (backend)..."
    exec node /app/server.js
    ;;
  *)
    echo "ERROR: ROLE env var must be 'frontend' or 'backend'. Got: '${ROLE}'"
    exit 1
    ;;
esac
