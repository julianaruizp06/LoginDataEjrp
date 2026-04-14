import json
import time
from typing import Any, Dict

class Metrics:
    def __init__(self) -> None:
        self.counters: Dict[str, int] = {}
        self.timers: Dict[str, float] = {}

    def inc(self, key: str, value: int = 1) -> None:
        self.counters[key] = self.counters.get(key, 0) + value

    def start(self, key: str) -> None:
        self.timers[key] = time.time()

    def stop_ms(self, key: str) -> int:
        if key not in self.timers:
            return 0
        return int((time.time() - self.timers[key]) * 1000)

    def dump(self, path: str, extra: Dict[str, Any] = None) -> None:
        payload = {"counters": self.counters}
        if extra:
            payload.update(extra)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False, indent=2)