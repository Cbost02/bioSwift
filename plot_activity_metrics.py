from __future__ import annotations

import argparse
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


DEFAULT_METRICS = [
    "duration",
    "path_length",
    "mean_speed",
    "max_speed",
    "tap_count",
    "mean_tap_interval",
    "yaw_range",
    "pitch_range",
    "roll_range",
]


def available_metrics(data_frame: pd.DataFrame, requested_metrics: list[str]) -> list[str]:
    usable_metrics: list[str] = []
    for metric_name in requested_metrics:
        if metric_name in data_frame.columns and pd.api.types.is_numeric_dtype(data_frame[metric_name]):
            if data_frame[metric_name].notna().any():
                usable_metrics.append(metric_name)
    return usable_metrics



def save_bar_chart(summary_frame: pd.DataFrame, metric_name: str, output_dir: Path) -> None:
    chart_frame = summary_frame[["activity", metric_name]].dropna().sort_values(metric_name).reset_index(drop=True)
    if chart_frame.empty:
        return

    plt.figure(figsize=(9, 5))
    plt.bar(chart_frame["activity"], chart_frame[metric_name])
    plt.title(f"Average {metric_name.replace('_', ' ').title()} by Activity")
    plt.xlabel("Activity")
    plt.ylabel(metric_name.replace("_", " ").title())
    plt.xticks(rotation=20)
    plt.tight_layout()
    plt.savefig(output_dir / f"bar_{metric_name}.png", dpi=200, bbox_inches="tight")
    plt.close()



def save_error_bar_chart(summary_frame: pd.DataFrame, metric_name: str, output_dir: Path) -> None:
    mean_column = metric_name
    std_column = f"{metric_name}_std"

    if std_column not in summary_frame.columns:
        return

    chart_frame = summary_frame[["activity", mean_column, std_column]].dropna(subset=[mean_column]).sort_values(mean_column).reset_index(drop=True)
    if chart_frame.empty:
        return

    error_values = chart_frame[std_column].fillna(0.0)

    plt.figure(figsize=(9, 5))
    plt.bar(chart_frame["activity"], chart_frame[mean_column], yerr=error_values, capsize=6)
    plt.title(f"Average {metric_name.replace('_', ' ').title()} by Activity")
    plt.xlabel("Activity")
    plt.ylabel(metric_name.replace("_", " ").title())
    plt.xticks(rotation=20)
    plt.tight_layout()
    plt.savefig(output_dir / f"bar_{metric_name}_with_std.png", dpi=200, bbox_inches="tight")
    plt.close()



def build_summary_from_session_metrics(session_metrics: pd.DataFrame, metrics: list[str]) -> pd.DataFrame:
    aggregations: dict[str, list[str]] = {metric_name: ["mean", "std", "min", "max", "count"] for metric_name in metrics}

    summary_frame = session_metrics.groupby("activity").agg(aggregations)
    summary_frame.columns = [
        f"{column_name}_{stat_name}" for column_name, stat_name in summary_frame.columns.to_flat_index()
    ]
    summary_frame = summary_frame.reset_index()

    renamed_columns = {}
    for metric_name in metrics:
        mean_column = f"{metric_name}_mean"
        if mean_column in summary_frame.columns:
            renamed_columns[mean_column] = metric_name

    summary_frame = summary_frame.rename(columns=renamed_columns)
    return summary_frame



def run_pipeline(input_csv: Path, output_dir: Path, metrics: list[str]) -> None:
    if not input_csv.exists():
        raise FileNotFoundError(f"Input file not found: {input_csv}")

    session_metrics = pd.read_csv(input_csv)
    if session_metrics.empty:
        raise ValueError("The input session metrics CSV is empty.")
    if "activity" not in session_metrics.columns:
        raise ValueError("The input CSV must contain an 'activity' column.")

    metrics_to_plot = available_metrics(session_metrics, metrics)
    if not metrics_to_plot:
        raise ValueError("None of the requested metrics were found as usable numeric columns.")

    output_dir.mkdir(parents=True, exist_ok=True)

    summary_frame = build_summary_from_session_metrics(session_metrics, metrics_to_plot)
    summary_frame.to_csv(output_dir / "activity_plot_summary.csv", index=False)

    for metric_name in metrics_to_plot:
        save_bar_chart(summary_frame, metric_name, output_dir)
        save_error_bar_chart(summary_frame, metric_name, output_dir)

    print("Bar chart generation complete.")
    print(f"Metrics plotted: {', '.join(metrics_to_plot)}")
    print(f"Output directory: {output_dir}")



def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create bar charts from Signals to Pathways session metrics"
    )
    parser.add_argument(
        "--input-csv",
        type=Path,
        required=True,
        help="Path to session_metrics.csv",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        required=True,
        help="Directory where bar charts will be saved",
    )
    parser.add_argument(
        "--metrics",
        nargs="*",
        default=DEFAULT_METRICS,
        help="Optional list of metric column names to plot",
    )
    return parser.parse_args()


if __name__ == "__main__":
    arguments = parse_args()
    run_pipeline(arguments.input_csv, arguments.output_dir, arguments.metrics)
