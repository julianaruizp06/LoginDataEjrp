import csv
from typing import Dict, Iterator

def read_csv_rows(path: str) -> Iterator[Dict[str, str]]:
    with open(path, "r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            yield row