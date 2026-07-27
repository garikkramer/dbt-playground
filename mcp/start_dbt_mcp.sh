#!/bin/bash
export DBT_PROJECT_DIR="/Users/igor.dmitriev/repo/dbt-playground"
export DBT_PATH="/Users/igor.dmitriev/repo/dbt-playground/.venv/bin/dbt"
export DISABLE_SEMANTIC_LAYER="true"
export DISABLE_DISCOVERY="true"
export DISABLE_ADMIN_API="true"
export DISABLE_SQL="true"

exec /Users/igor.dmitriev/repo/dbt-playground/.venv/bin/dbt-mcp "$@"
