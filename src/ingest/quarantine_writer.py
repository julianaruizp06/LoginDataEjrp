import json
import os
from datetime import datetime, timezone
from typing import Any, Dict, List

def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

def write_quarantine(base_dir: str, dataset: str, batch_id: str, reason: List[str], raw_record: Dict[str, Any]) -> str:
    ingest_date = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    out_dir = os.path.join(base_dir, "evidence", "samples", "quarantine", dataset, f"ingest_date={ingest_date}", f"batch_id={batch_id}")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "records.jsonl")

    payload = {
        "dataset": dataset,
        "source": "local",
        "schema_version": "1.0",
        "batch_id": batch_id,
        "ingest_ts": utc_now_iso(),
        "reason": reason,
        "raw_record": raw_record
    }
    with open(out_path, "a", encoding="utf-8") as f:
        f.write(json.dumps(payload, ensure_ascii=False) + "\n")
    return out_path