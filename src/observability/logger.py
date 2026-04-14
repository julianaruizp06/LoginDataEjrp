import json
from datetime import datetime, timezone
from typing import Any, Dict

def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

def log_jsonl(path: str, level: str, message: str, **fields: Any) -> None:
    record: Dict[str, Any] = {"ts_utc": utc_now_iso(), "level": level, "message": message, **fields}
    with open(path, "a", encoding="utf-8") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")