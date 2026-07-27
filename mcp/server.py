import argparse
import os
import sys
from pathlib import Path
from typing import List, Optional

# Add mcp parent directory to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent))

from mcp.server.fastmcp import FastMCP
from semantic_layer.manifest_reader import (
    get_all_metrics,
    get_all_saved_queries,
    get_dimensions_for_target,
    get_entities_for_target,
)
from semantic_layer.metricflow_runner import (
    get_dimension_values as run_get_dimension_values,
    get_metrics_compiled_sql as run_get_metrics_compiled_sql,
    query_metrics as run_query_metrics,
)


def parse_args():
    parser = argparse.ArgumentParser(description="dbt Semantic Layer MCP Server (Remote & Stdio)")
    parser.add_argument(
        "--transport",
        choices=["sse", "streamable-http", "stdio"],
        default=os.environ.get("MCP_TRANSPORT", "sse"),
        help="Transport mode (default: sse)"
    )
    parser.add_argument(
        "--host",
        default=os.environ.get("MCP_HOST", "0.0.0.0"),
        help="Host interface to bind to (default: 0.0.0.0)"
    )
    parser.add_argument(
        "--port",
        type=int,
        default=int(os.environ.get("MCP_PORT", 8000)),
        help="Port to listen on for HTTP/SSE (default: 8000)"
    )
    return parser.parse_args()


args = parse_args()

mcp = FastMCP(
    "local-dbt-semantic-layer",
    host=args.host,
    port=args.port
)


@mcp.tool()
def list_metrics(search: Optional[str] = None) -> list:
    """Lists all available semantic metrics in the dbt project.
    
    Args:
        search: Optional substring to search by metric name, label, or description.
    """
    return get_all_metrics(search=search)


@mcp.tool()
def list_saved_queries() -> list:
    """Lists all saved queries defined in the dbt project."""
    return get_all_saved_queries()


@mcp.tool()
def get_dimensions(
    metric_name: Optional[str] = None,
    semantic_model_name: Optional[str] = None
) -> list:
    """Gets available dimensions for a metric or semantic model.
    
    Args:
        metric_name: Optional metric name to filter dimensions for.
        semantic_model_name: Optional semantic model name to filter dimensions for.
    """
    return get_dimensions_for_target(
        metric_name=metric_name,
        semantic_model_name=semantic_model_name
    )


@mcp.tool()
def get_entities(semantic_model_name: Optional[str] = None) -> list:
    """Gets entities (primary/foreign keys) defined in semantic models.
    
    Args:
        semantic_model_name: Optional semantic model name to filter entities for.
    """
    return get_entities_for_target(semantic_model_name=semantic_model_name)


@mcp.tool()
def get_dimension_values(dimension: str, limit: int = 100) -> str:
    """Gets unique values for a given dimension using MetricFlow.
    
    Args:
        dimension: Full dimension name (e.g. 'profit_record__nation').
        limit: Max rows to return (default: 100).
    """
    return run_get_dimension_values(dimension=dimension, limit=limit)


@mcp.tool()
def query_metrics(
    metrics: List[str],
    group_by: Optional[List[str]] = None,
    where: Optional[str] = None,
    order: Optional[List[str]] = None,
    limit: Optional[int] = None
) -> str:
    """Calculates and queries metrics using MetricFlow CLI against the data warehouse.
    
    Args:
        metrics: List of metric names to calculate (e.g. ['q9_total_profit']).
        group_by: List of dimensions or entities to group by (e.g. ['profit_record__nation']).
        where: Filter expression (e.g. "{{ Dimension('profit_record__nation') }} = 'GERMANY'").
        order: List of order fields (e.g. ['-q9_total_profit']).
        limit: Max rows to return.
    """
    return run_query_metrics(
        metrics=metrics,
        group_by=group_by,
        where=where,
        order=order,
        limit=limit
    )


@mcp.tool()
def get_metrics_compiled_sql(
    metrics: List[str],
    group_by: Optional[List[str]] = None,
    where: Optional[str] = None,
    order: Optional[List[str]] = None
) -> str:
    """Generates the compiled SQL query for a metric calculation without executing it.
    
    Args:
        metrics: List of metric names to query (e.g. ['q9_total_profit']).
        group_by: List of dimensions or entities to group by (e.g. ['profit_record__nation']).
        where: Filter expression.
        order: List of order fields.
    """
    return run_get_metrics_compiled_sql(
        metrics=metrics,
        group_by=group_by,
        where=where,
        order=order
    )


if __name__ == "__main__":
    if args.transport == "stdio":
        mcp.run(transport="stdio")
    elif args.transport == "streamable-http":
        mcp.run(transport="streamable-http")
    else:
        print(f"Starting standalone MCP SSE server listening on http://{args.host}:{args.port}/sse ...", file=sys.stderr)
        mcp.run(transport="sse")
