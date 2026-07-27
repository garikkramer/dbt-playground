import subprocess
from pathlib import Path
from typing import Any, Dict, List, Optional

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
MF_PATH = PROJECT_ROOT / ".venv" / "bin" / "mf"


def run_mf_command(cmd_args: List[str]) -> str:
    """Executes a MetricFlow CLI command and returns standard output."""
    if not MF_PATH.exists():
        raise FileNotFoundError(f"MetricFlow executable not found at {MF_PATH}")

    full_cmd = [str(MF_PATH)] + cmd_args
    result = subprocess.run(
        full_cmd,
        cwd=str(PROJECT_ROOT),
        capture_output=True,
        text=True,
        check=True
    )
    return result.stdout.strip()


def query_metrics(
    metrics: List[str],
    group_by: Optional[List[str]] = None,
    where: Optional[str] = None,
    order: Optional[List[str]] = None,
    limit: Optional[int] = None
) -> str:
    """Queries metrics using MetricFlow CLI."""
    args = ["query", "--metrics", ",".join(metrics)]

    if group_by:
        args.extend(["--group-by", ",".join(group_by)])
    if where:
        args.extend(["--where", where])
    if order:
        args.extend(["--order", ",".join(order)])
    if limit:
        args.extend(["--limit", str(limit)])

    return run_mf_command(args)


def get_metrics_compiled_sql(
    metrics: List[str],
    group_by: Optional[List[str]] = None,
    where: Optional[str] = None,
    order: Optional[List[str]] = None
) -> str:
    """Returns compiled SQL for a metric query using MetricFlow explain."""
    args = ["query", "--metrics", ",".join(metrics), "--explain"]

    if group_by:
        args.extend(["--group-by", ",".join(group_by)])
    if where:
        args.extend(["--where", where])
    if order:
        args.extend(["--order", ",".join(order)])

    output = run_mf_command(args)
    return output


def get_dimension_values(
    dimension: str,
    limit: Optional[int] = 100
) -> str:
    """Queries distinct values of a dimension using MetricFlow."""
    args = ["query", "--group-by", dimension]
    if limit:
        args.extend(["--limit", str(limit)])
    return run_mf_command(args)
