# Dockerfile for Standalone dbt Semantic Layer MCP Service
FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy project files
COPY . /app

# Install python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Environment variables
ENV MCP_HOST=0.0.0.0
ENV MCP_PORT=8000
ENV MCP_TRANSPORT=sse

# Parse dbt manifest on startup if needed
RUN dbt parse || true

# Expose port
EXPOSE 8000

# Run remote MCP service
CMD ["python", "mcp/server.py", "--transport", "sse", "--host", "0.0.0.0", "--port", "8000"]
