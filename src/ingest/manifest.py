import json
import os
from datetime import datetime, timezone
from typing import Any, Dict

def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

def write_manifest(base_dir: str, dataset: str, batch_id: str, stats: Dict[str, Any]) -> str:
    out_dir = os.path.join(base_dir, "evidence", "samples", "_system", "metadata", "manifests", dataset)
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, f"manifest_{batch_id}.json")

    payload = {"dataset": dataset, "batch_id": batch_id, "ingest_ts": utc_now_iso(), "stats": stats}
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
    return out_path