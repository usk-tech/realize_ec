#!/bin/bash

STORE_NAME=${1:-radika}

case $STORE_NAME in
  radika)
    export APP_PORT=3000 DB_PORT=5432
    echo "🍛 Starting Radika on http://localhost:3000"
    ;;
  shrimpshells)
    export APP_PORT=3001 DB_PORT=5433
    echo "🦐 Starting ShrimpShells on http://localhost:3001"
    ;;
  khukh_khuleg)
    export APP_PORT=3002 DB_PORT=5434
    echo "🥟 Starting Khukh Khuleg on http://localhost:3002"
    ;;
  *)
    echo "❌ Unknown store: $STORE_NAME"
    echo "Usage: ./bin/start_store.sh [radika|shrimpshells|khukh_khuleg]"
    exit 1
    ;;
esac

export STORE_NAME=$STORE_NAME
docker-compose up
