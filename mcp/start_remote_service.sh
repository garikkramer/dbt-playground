#!/usr/bin/env bash
# Script to launch standalone remote dbt Semantic Layer MCP server

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( dirname "$SCRIPT_DIR" )"

HOST="${MCP_HOST:-0.0.0.0}"
PORT="${MCP_PORT:-8000}"
TRANSPORT="${MCP_TRANSPORT:-streamable-http}"

echo "=========================================================="
echo " Starting Standalone Remote dbt Semantic Layer MCP Server"
echo " Host: $HOST"
echo " Port: $PORT"
echo " Transport: $TRANSPORT"
if [ "$TRANSPORT" = "streamable-http" ]; then
    echo " Endpoint: http://$HOST:$PORT/mcp"
else
    echo " Endpoint: http://$HOST:$PORT/sse"
fi
echo "=========================================================="

# Run Python FastMCP server
exec "$PROJECT_DIR/.venv/bin/python" "$SCRIPT_DIR/server.py" --transport "$TRANSPORT" --host "$HOST" --port "$PORT" "$@"
