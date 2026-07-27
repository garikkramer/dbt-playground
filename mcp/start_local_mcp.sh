#!/usr/bin/env bash
# Startup script for Local dbt Semantic Layer MCP server in stdio mode

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( dirname "$SCRIPT_DIR" )"

# Run Python FastMCP server in stdio mode for local process clients
exec "$PROJECT_DIR/.venv/bin/python" "$SCRIPT_DIR/server.py" --transport stdio "$@"
