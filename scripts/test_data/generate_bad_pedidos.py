import argparse
from pathlib import Path
import random
import pandas as pd


def make_missing_column(df: pd.DataFrame, col: str) -> pd.DataFrame:
    if col not in df.columns:
        raise ValueError(f"Column '{col}' not found. Available: {list(df.columns)}")
    return df.drop(columns=[col])


def make_dirty_data(df: pd.DataFrame) -> pd.DataFrame:
    dirty = df.copy()
    n = len(dirty)
    if n < 12:
        raise ValueError("Input file is too small to generate a meaningful dirty-data sample.")

    # fixed rows for reproducibility and easier demo
    idx = list(range(min(12, n)))

    # Missing critical values
    dirty.loc[idx[0], "monto"] = None
    dirty.loc[idx[1], "fecha"] = None
    dirty.loc[idx[2], "id_cliente"] = None

    # Invalid numeric / date / enum values
    dirty.loc[idx[3], "monto"] = -999.99
    dirty.loc[idx[4], "monto"] = "abc"
    dirty.loc[idx[5], "fecha"] = "fecha_mala"
    dirty.loc[idx[6], "estado"] = "DESCONOCIDO"

    # Duplicated business key
    dirty.loc[idx[7], "id_pedido"] = dirty.loc[idx[8], "id_pedido"]

    # Broken identifiers / whitespace / malformed values
    dirty.loc[idx[9], "id_producto"] = ""
    dirty.loc[idx[10], "id_cliente"] = "   "
    dirty.loc[idx[11], "fecha"] = "2025/99/99 25:61:61"

    return dirty


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate invalid or dirty variants of pedidos.csv for controlled pipeline-failure tests."
    )
    parser.add_argument(
        "--input",
        required=True,
        help="Path to the source pedidos CSV, e.g. assets/data/raw/pedidos.csv",
    )
    parser.add_argument(
        "--outdir",
        default=".",
        help="Directory where the generated files will be saved.",
    )
    parser.add_argument(
        "--drop-column",
        default="monto",
        help="Critical column to remove for the missing-column scenario.",
    )
    args = parser.parse_args()

    src = Path(args.input)
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    df = pd.read_csv(src)

    missing_col_df = make_missing_column(df, args.drop_column)
    dirty_df = make_dirty_data(df)

    missing_col_path = outdir / "pedidos_ingesta_invalida_sin_monto.csv"
    dirty_path = outdir / "pedidos_ingesta_data_sucia.csv"

    missing_col_df.to_csv(missing_col_path, index=False)
    dirty_df.to_csv(dirty_path, index=False)

    print("Files generated successfully:")
    print(f"- {missing_col_path}")
    print(f"- {dirty_path}")
    print("\nSuggested use:")
    print("1) Missing-column scenario: replace pedidos.csv with pedidos_ingesta_invalida_sin_monto.csv")
    print("2) Dirty-data scenario: replace pedidos.csv with pedidos_ingesta_data_sucia.csv")


if __name__ == "__main__":
    main()
