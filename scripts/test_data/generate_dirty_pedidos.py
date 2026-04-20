import argparse
import csv
import random
from pathlib import Path

BAD_STATES = ["DESCONOCIDO", "ERRADO", "PENDIENTE_X"]
DATE_BAD_VALUES = ["fecha_mala", "", "2025/99/99", "no-date"]
MONTO_BAD_VALUES = ["abc", "", "-100"]
EMPTY_VALUES = ["", " ", "NULL"]


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


def dirty_one_row(row, headers, used_ids):
    row = dict(row)
    error_type = random.choice([
        "monto_invalido",
        "monto_negativo",
        "fecha_invalida",
        "estado_invalido",
        "id_cliente_vacio",
        "id_producto_vacio",
        "id_pedido_duplicado",
    ])

    if error_type == "monto_invalido" and "monto" in headers:
        row["monto"] = random.choice(MONTO_BAD_VALUES[:2])  # abc o vacío
    elif error_type == "monto_negativo" and "monto" in headers:
        row["monto"] = "-100"
    elif error_type == "fecha_invalida" and "fecha" in headers:
        row["fecha"] = random.choice(DATE_BAD_VALUES)
    elif error_type == "estado_invalido" and "estado" in headers:
        row["estado"] = random.choice(BAD_STATES)
    elif error_type == "id_cliente_vacio" and "id_cliente" in headers:
        row["id_cliente"] = random.choice(EMPTY_VALUES)
    elif error_type == "id_producto_vacio" and "id_producto" in headers:
        row["id_producto"] = random.choice(EMPTY_VALUES)
    elif error_type == "id_pedido_duplicado" and "id_pedido" in headers and used_ids:
        row["id_pedido"] = random.choice(list(used_ids))

    return row, error_type


def main():
    parser = argparse.ArgumentParser(description="Genera una ingesta de pedidos con data sucia.")
    parser.add_argument("--input", default="assets/data/raw/pedidos.csv")
    parser.add_argument("--output", default="tmp/test_data/pedidos_data_sucia.csv")
    parser.add_argument("--limit", type=int, default=10)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--dirty-ratio", type=float, default=0.4)
    args = parser.parse_args()

    random.seed(args.seed)

    headers, rows = read_csv(args.input)
    sampled = sample_rows(rows, args.limit)
    used_ids = {r.get("id_pedido") for r in sampled if r.get("id_pedido")}

    dirty_count = max(1, int(len(sampled) * args.dirty_ratio))
    chosen_indexes = random.sample(range(len(sampled)), min(dirty_count, len(sampled)))

    applied = []
    for idx in chosen_indexes:
        sampled[idx], error_type = dirty_one_row(sampled[idx], headers, used_ids)
        applied.append((idx, error_type))

    write_csv(args.output, headers, sampled)

    print("Archivo generado:", args.output)
    print("Filas generadas:", len(sampled))
    print("Errores aplicados:")
    for idx, err in applied:
        print(f"  fila {idx}: {err}")


if __name__ == "__main__":
    main()