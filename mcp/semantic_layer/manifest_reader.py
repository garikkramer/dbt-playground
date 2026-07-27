import json
import os
import subprocess
from pathlib import Path
from typing import Any, Dict, List, Optional

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
MANIFEST_PATH = PROJECT_ROOT / "target" / "manifest.json"
DBT_PATH = PROJECT_ROOT / ".venv" / "bin" / "dbt"


def ensure_manifest() -> Dict[str, Any]:
    """Ensures target/manifest.json exists and returns parsed dict."""
    if not MANIFEST_PATH.exists():
        if DBT_PATH.exists():
            subprocess.run([str(DBT_PATH), "parse"], cwd=str(PROJECT_ROOT), check=True)
        else:
            raise FileNotFoundError(f"manifest.json not found at {MANIFEST_PATH}")
    
    with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def get_all_metrics(search: Optional[str] = None) -> List[Dict[str, Any]]:
    """Returns all metrics defined in the manifest, optionally filtered by search substring."""
    manifest = ensure_manifest()
    metrics_dict = manifest.get("metrics", {})
    results = []

    for unique_id, metric in metrics_dict.items():
        name = metric.get("name", "")
        label = metric.get("label", "")
        description = metric.get("description", "")
        metric_type = metric.get("type", "")

        if search:
            search_lower = search.lower()
            if search_lower not in name.lower() and search_lower not in label.lower() and search_lower not in description.lower():
                continue

        # Find associated semantic model to extract dimensions and entities
        depends_on_nodes = metric.get("depends_on", {}).get("nodes", [])
        dimensions = []
        entities = []
        for node_id in depends_on_nodes:
            if node_id.startswith("semantic_model."):
                sem_model = manifest.get("semantic_models", {}).get(node_id, {})
                for dim in sem_model.get("dimensions", []):
                    dimensions.append({
                        "name": dim.get("name"),
                        "type": dim.get("type"),
                        "description": dim.get("description")
                    })
                for ent in sem_model.get("entities", []):
                    entities.append({
                        "name": ent.get("name"),
                        "type": ent.get("type"),
                        "description": ent.get("description")
                    })

        results.append({
            "name": name,
            "label": label,
            "description": description,
            "type": metric_type,
            "dimensions": dimensions,
            "entities": entities
        })

    return results


def get_all_saved_queries() -> List[Dict[str, Any]]:
    """Returns saved queries from manifest."""
    manifest = ensure_manifest()
    saved_queries = manifest.get("saved_queries", {})
    results = []
    for unique_id, sq in saved_queries.items():
        results.append({
            "name": sq.get("name"),
            "description": sq.get("description"),
            "query_params": sq.get("query_params", {})
        })
    return results


def get_dimensions_for_target(metric_name: Optional[str] = None, semantic_model_name: Optional[str] = None) -> List[Dict[str, Any]]:
    """Returns dimensions associated with a metric or semantic model."""
    manifest = ensure_manifest()
    results = []

    if semantic_model_name:
        for unique_id, sem_model in manifest.get("semantic_models", {}).items():
            if sem_model.get("name") == semantic_model_name:
                for dim in sem_model.get("dimensions", []):
                    results.append({
                        "name": dim.get("name"),
                        "type": dim.get("type"),
                        "description": dim.get("description"),
                        "semantic_model": sem_model.get("name")
                    })
        return results

    # If metric_name is provided or search across all
    for unique_id, metric in manifest.get("metrics", {}).items():
        if metric_name and metric.get("name") != metric_name:
            continue

        depends_on_nodes = metric.get("depends_on", {}).get("nodes", [])
        for node_id in depends_on_nodes:
            if node_id.startswith("semantic_model."):
                sem_model = manifest.get("semantic_models", {}).get(node_id, {})
                for dim in sem_model.get("dimensions", []):
                    results.append({
                        "name": dim.get("name"),
                        "type": dim.get("type"),
                        "description": dim.get("description"),
                        "metric": metric.get("name"),
                        "semantic_model": sem_model.get("name")
                    })

    return results


def get_entities_for_target(semantic_model_name: Optional[str] = None) -> List[Dict[str, Any]]:
    """Returns entities defined in semantic models."""
    manifest = ensure_manifest()
    results = []

    for unique_id, sem_model in manifest.get("semantic_models", {}).items():
        if semantic_model_name and sem_model.get("name") != semantic_model_name:
            continue

        for ent in sem_model.get("entities", []):
            results.append({
                "name": ent.get("name"),
                "type": ent.get("type"),
                "description": ent.get("description"),
                "expr": ent.get("expr"),
                "semantic_model": sem_model.get("name")
            })

    return results
