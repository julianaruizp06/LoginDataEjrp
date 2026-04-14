import json
from datetime import datetime
from typing import Any, Dict, List

def _is_number(v: str) -> bool:
    try:
        float(v)
        return True
    except Exception:
        return False

def _is_iso_utc(v: str) -> bool:
    try:
        if v.endswith("Z"):
            datetime.fromisoformat(v.replace("Z", "+00:00"))
        else:
            datetime.fromisoformat(v)
        return True
    except Exception:
        return False

def load_contract(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def validate_row(contract: Dict[str, Any], row: Dict[str, str]) -> List[str]:
    errors: List[str] = []
    req = contract.get("required_fields", [])
    types = contract.get("field_types", {})
    allowed = contract.get("allowed_values", {})

    for k in req:
        if k not in row or row[k] is None or str(row[k]).strip() == "":
            errors.append(f"missing_required:{k}")

    for k, t in types.items():
        if k not in row or str(row[k]).strip() == "":
            continue
        val = str(row[k]).strip()
        if t == "number" and not _is_number(val):
            errors.append(f"type_mismatch:{k}:number")
        if t == "datetime_utc_iso" and not _is_iso_utc(val):
            errors.append(f"type_mismatch:{k}:datetime_utc_iso")

    for k, allowed_list in allowed.items():
        if k in row and str(row[k]).strip() != "":
            if str(row[k]).strip() not in allowed_list:
                errors.append(f"invalid_value:{k}")

    return errors