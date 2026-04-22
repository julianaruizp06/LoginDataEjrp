import argparse
import csv
import random
from pathlib import Path


def read_csv(input_path: str):
    with open(input_path, "r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        headers = reader.fieldnames or []
    return headers, rows


def write_csv(output_path: str, headers, rows):
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=headers)
        writer.writeheader()
        writer.writerows(rows)


def sample_rows(rows, limit: int):
    if limit >= len(rows):
        return [dict(r) for r in rows]
    return [dict(r) for r in random.sample(rows, limit)]


def main():
    parser = argparse.ArgumentParser(description="Genera una ingesta de pedidos sin la columna monto.")
    parser.add_argument("--input", default="assets/data/raw/pedidos.csv")
    parser.add_argument("--output", default="tmp/test_data/pedidos_sin_monto.csv")
    parser.add_argument("--limit", type=int, default=10)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    random.seed(args.seed)

    headers, rows = read_csv(args.input)

    if "monto" not in headers:
        raise ValueError("El archivo base no contiene la columna 'monto'.")

    sampled = sample_rows(rows, args.limit)
    new_headers = [h for h in headers if h != "monto"]

    new_rows = []
    for row in sampled:
        new_rows.append({k: v for k, v in row.items() if k != "monto"})

    write_csv(args.output, new_headers, new_rows)

    print("Archivo generado:", args.output)
    print("Filas generadas:", len(sampled))
    print("Columna removida: monto")


if __name__ == "__main__":
    main()