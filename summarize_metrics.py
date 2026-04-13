from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import pandas as pd


def run_summary(input_csv: Path, output_csv: Path) -> None:
    if not input_csv.exists():
        raise FileNotFoundError(f"Input file not found: {input_csv}")

    df = pd.read_csv(input_csv)

    if df.empty:
        raise ValueError("The input metrics CSV is empty.")

    if "activity" not in df.columns:
        raise ValueError("The input CSV must contain an 'activity' column.")

    numeric_columns = df.select_dtypes(include=[np.number]).columns.tolist()

    if not numeric_columns:
        raise ValueError("No numeric columns were found to summarize.")

    summary_df = (
        df.groupby("activity")[numeric_columns]
        .agg(["count", "mean", "std", "min", "max"])
        .round(4)
    )

    summary_df.columns = [
        f"{column}_{stat}"
        for column, stat in summary_df.columns.to_flat_index()
    ]

    summary_df = summary_df.reset_index()

    output_csv.parent.mkdir(parents=True, exist_ok=True)
    summary_df.to_csv(output_csv, index=False)

    print("Activity summary complete.")
    print(f"Activities summarized: {len(summary_df)}")
    print(f"Saved to: {output_csv}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Summarize Signals to Pathways session metrics by activity"
    )
    parser.add_argument(
        "--input-csv",
        type=Path,
        required=True,
        help="Path to session_metrics.csv",
    )
    parser.add_argument(
        "--output-csv",
        type=Path,
        required=True,
        help="Path to save the activity summary CSV",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    run_summary(args.input_csv, args.output_csv)