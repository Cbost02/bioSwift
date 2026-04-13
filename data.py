from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


def load_json_payload(file_path: Path) -> dict[str, Any]:
    with file_path.open("r", encoding="utf-8") as input_file:
        payload = json.load(input_file)

    if not isinstance(payload, dict):
        raise ValueError(f"Expected a JSON object in {file_path}")

    return payload


def detect_schema(payload: dict[str, Any], file_path: Path) -> str:
    samples = payload.get("samples")
    if not isinstance(samples, list) or not samples:
        raise ValueError(f"{file_path.name}: missing or empty 'samples' list")

    first_sample = samples[0]
    if not isinstance(first_sample, dict):
        raise ValueError(f"{file_path.name}: sample entries must be objects")

    sample_keys = set(first_sample.keys())

    if {"yaw", "roll", "pitch", "time"}.issubset(sample_keys):
        return "orientation"

    if {"x", "y", "time", "phase"}.issubset(sample_keys):
        return "path"

    if {"x", "y", "time"}.issubset(sample_keys):
        return "tapping"

    raise ValueError(
        f"{file_path.name}: unsupported schema. Sample keys = {sorted(sample_keys)}"
    )


def infer_activity(schema: str, file_path: Path, payload: dict[str, Any]) -> str:
    if "activity" in payload:
        return str(payload["activity"]).strip().lower()

    file_name = file_path.name.lower()

    if schema == "orientation":
        return "orientation"
    if "zigzag" in file_name:
        return "zigzag"
    if "swiping" in file_name or "swipe" in file_name:
        return "swiping"
    if "tapping" in file_name or "tap" in file_name:
        return "tapping"

    return schema


def flatten_path_session(file_path: Path, payload: dict[str, Any]) -> tuple[dict[str, Any], pd.DataFrame]:
    activity = infer_activity("path", file_path, payload)
    started_at = str(payload.get("startedAt", "unknown")).strip()
    platform = str(payload.get("platform", "unknown")).strip().lower()

    rows: list[dict[str, Any]] = []
    for sample in payload["samples"]:
        rows.append(
            {
                "source_file": file_path.name,
                "schema": "path",
                "activity": activity,
                "started_at": started_at,
                "platform": platform,
                "phase": str(sample.get("phase", "unknown")).strip().lower(),
                "x": float(sample["x"]),
                "y": float(sample["y"]),
                "time": float(sample["time"]),
            }
        )

    session_df = pd.DataFrame(rows).sort_values("time").reset_index(drop=True)

    metadata = {
        "source_file": file_path.name,
        "schema": "path",
        "activity": activity,
        "started_at": started_at,
        "platform": platform,
    }

    return metadata, session_df


def flatten_tapping_session(file_path: Path, payload: dict[str, Any]) -> tuple[dict[str, Any], pd.DataFrame]:
    activity = infer_activity("tapping", file_path, payload)
    started_at = str(payload.get("startedAt", "unknown")).strip()
    platform = str(payload.get("platform", "unknown")).strip().lower()

    rows: list[dict[str, Any]] = []
    for sample in payload["samples"]:
        rows.append(
            {
                "source_file": file_path.name,
                "schema": "tapping",
                "activity": activity,
                "started_at": started_at,
                "platform": platform,
                "x": float(sample["x"]),
                "y": float(sample["y"]),
                "time": float(sample["time"]),
            }
        )

    session_df = pd.DataFrame(rows).sort_values("time").reset_index(drop=True)

    metadata = {
        "source_file": file_path.name,
        "schema": "tapping",
        "activity": activity,
        "started_at": started_at,
        "platform": platform,
    }

    return metadata, session_df


def flatten_orientation_session(file_path: Path, payload: dict[str, Any]) -> tuple[dict[str, Any], pd.DataFrame]:
    activity = infer_activity("orientation", file_path, payload)
    started_at = str(payload.get("startedAt", "unknown")).strip()
    platform = str(payload.get("platform", "unknown")).strip().lower()

    rows: list[dict[str, Any]] = []
    for sample in payload["samples"]:
        rows.append(
            {
                "source_file": file_path.name,
                "schema": "orientation",
                "activity": activity,
                "started_at": started_at,
                "platform": platform,
                "yaw": float(sample["yaw"]),
                "pitch": float(sample["pitch"]),
                "roll": float(sample["roll"]),
                "time": float(sample["time"]),
            }
        )

    session_df = pd.DataFrame(rows).sort_values("time").reset_index(drop=True)

    metadata = {
        "source_file": file_path.name,
        "schema": "orientation",
        "activity": activity,
        "started_at": started_at,
        "platform": platform,
    }

    return metadata, session_df


def add_path_derived_columns(session_df: pd.DataFrame) -> pd.DataFrame:
    result_df = session_df.copy()

    result_df["dt"] = result_df["time"].diff()
    result_df["dx"] = result_df["x"].diff()
    result_df["dy"] = result_df["y"].diff()

    result_df["step_distance"] = np.sqrt(
        result_df["dx"].fillna(0.0) ** 2 + result_df["dy"].fillna(0.0) ** 2
    )

    result_df["speed"] = result_df["step_distance"] / result_df["dt"]
    result_df["speed"] = result_df["speed"].replace([np.inf, -np.inf], np.nan).fillna(0.0)

    return result_df


def add_tapping_derived_columns(session_df: pd.DataFrame) -> pd.DataFrame:
    result_df = session_df.copy()
    result_df["tap_interval"] = result_df["time"].diff()
    return result_df


def save_path_trace_plot(session_df: pd.DataFrame, metadata: dict[str, Any], output_dir: Path) -> None:
    plt.figure(figsize=(7, 7))
    plt.plot(session_df["x"], session_df["y"], marker="o", markersize=2)
    plt.scatter(session_df.iloc[0]["x"], session_df.iloc[0]["y"], s=60, label="Start")
    plt.scatter(session_df.iloc[-1]["x"], session_df.iloc[-1]["y"], s=60, label="End")
    plt.title(f"Trace Path\n{metadata['activity']} | {metadata['source_file']}")
    plt.xlabel("x")
    plt.ylabel("y")
    plt.xlim(0, 1)
    plt.ylim(0, 1)
    plt.gca().invert_yaxis()
    plt.legend()
    plt.tight_layout()
    plt.savefig(output_dir / f"{Path(metadata['source_file']).stem}_trace.png", dpi=200, bbox_inches="tight")
    plt.close()


def save_time_series_plot(
    session_df: pd.DataFrame,
    metadata: dict[str, Any],
    column_name: str,
    y_label: str,
    output_dir: Path,
) -> None:
    plt.figure(figsize=(9, 5))
    plt.plot(session_df["time"], session_df[column_name], marker="o")
    plt.title(f"{column_name.replace('_', ' ').title()} Over Time\n{metadata['activity']} | {metadata['source_file']}")
    plt.xlabel("Time (s)")
    plt.ylabel(y_label)
    plt.tight_layout()
    plt.savefig(output_dir / f"{Path(metadata['source_file']).stem}_{column_name}.png", dpi=200, bbox_inches="tight")
    plt.close()


def save_tapping_scatter_plot(session_df: pd.DataFrame, metadata: dict[str, Any], output_dir: Path) -> None:
    plt.figure(figsize=(7, 7))
    plt.scatter(session_df["x"], session_df["y"])
    for index, row in session_df.iterrows():
        plt.annotate(str(index + 1), (row["x"], row["y"]), fontsize=8)

    plt.title(f"Tap Locations\n{metadata['activity']} | {metadata['source_file']}")
    plt.xlabel("x")
    plt.ylabel("y")
    plt.xlim(0, 1)
    plt.ylim(0, 1)
    plt.gca().invert_yaxis()
    plt.tight_layout()
    plt.savefig(output_dir / f"{Path(metadata['source_file']).stem}_tap_locations.png", dpi=200, bbox_inches="tight")
    plt.close()


def process_path_file(file_path: Path, payload: dict[str, Any], output_dir: Path) -> dict[str, Any]:
    metadata, session_df = flatten_path_session(file_path, payload)
    session_df = add_path_derived_columns(session_df)

    save_path_trace_plot(session_df, metadata, output_dir)
    save_time_series_plot(session_df, metadata, "x", "x", output_dir)
    save_time_series_plot(session_df, metadata, "y", "y", output_dir)
    save_time_series_plot(session_df, metadata, "speed", "speed", output_dir)

    session_df.to_csv(output_dir / f"{Path(metadata['source_file']).stem}_flattened.csv", index=False)

    return {
        "source_file": metadata["source_file"],
        "schema": metadata["schema"],
        "activity": metadata["activity"],
        "platform": metadata["platform"],
        "sample_count": int(len(session_df)),
        "path_length": float(session_df["step_distance"].sum()),
        "mean_speed": float(session_df["speed"].mean()),
        "max_speed": float(session_df["speed"].max()),
        "first_time": float(session_df["time"].min()),
        "last_time": float(session_df["time"].max()),
    }


def process_tapping_file(file_path: Path, payload: dict[str, Any], output_dir: Path) -> dict[str, Any]:
    metadata, session_df = flatten_tapping_session(file_path, payload)
    session_df = add_tapping_derived_columns(session_df)

    save_tapping_scatter_plot(session_df, metadata, output_dir)
    save_time_series_plot(session_df, metadata, "x", "x", output_dir)
    save_time_series_plot(session_df, metadata, "y", "y", output_dir)
    save_time_series_plot(session_df, metadata, "tap_interval", "tap interval (s)", output_dir)

    session_df.to_csv(output_dir / f"{Path(metadata['source_file']).stem}_flattened.csv", index=False)

    return {
        "source_file": metadata["source_file"],
        "schema": metadata["schema"],
        "activity": metadata["activity"],
        "platform": metadata["platform"],
        "sample_count": int(len(session_df)),
        "mean_tap_interval": float(session_df["tap_interval"].dropna().mean()) if session_df["tap_interval"].dropna().any() else np.nan,
        "min_tap_interval": float(session_df["tap_interval"].dropna().min()) if session_df["tap_interval"].dropna().any() else np.nan,
        "max_tap_interval": float(session_df["tap_interval"].dropna().max()) if session_df["tap_interval"].dropna().any() else np.nan,
        "first_time": float(session_df["time"].min()),
        "last_time": float(session_df["time"].max()),
    }


def process_orientation_file(file_path: Path, payload: dict[str, Any], output_dir: Path) -> dict[str, Any]:
    metadata, session_df = flatten_orientation_session(file_path, payload)

    save_time_series_plot(session_df, metadata, "yaw", "yaw", output_dir)
    save_time_series_plot(session_df, metadata, "pitch", "pitch", output_dir)
    save_time_series_plot(session_df, metadata, "roll", "roll", output_dir)

    session_df.to_csv(output_dir / f"{Path(metadata['source_file']).stem}_flattened.csv", index=False)

    return {
        "source_file": metadata["source_file"],
        "schema": metadata["schema"],
        "activity": metadata["activity"],
        "platform": metadata["platform"],
        "sample_count": int(len(session_df)),
        "yaw_mean": float(session_df["yaw"].mean()),
        "pitch_mean": float(session_df["pitch"].mean()),
        "roll_mean": float(session_df["roll"].mean()),
        "first_time": float(session_df["time"].min()),
        "last_time": float(session_df["time"].max()),
    }


def run_pipeline(input_dir: Path, output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)

    json_files = sorted(input_dir.rglob("*.json"))
    if not json_files:
        raise FileNotFoundError(f"No JSON files found in {input_dir}")

    summary_rows: list[dict[str, Any]] = []

    for file_path in json_files:
        try:
            payload = load_json_payload(file_path)
            schema = detect_schema(payload, file_path)

            if schema == "path":
                summary_rows.append(process_path_file(file_path, payload, output_dir))
            elif schema == "tapping":
                summary_rows.append(process_tapping_file(file_path, payload, output_dir))
            elif schema == "orientation":
                summary_rows.append(process_orientation_file(file_path, payload, output_dir))

        except Exception as error:
            print(f"Skipping {file_path.name}: {error}")

    if not summary_rows:
        raise ValueError("No supported JSON files were processed.")

    summary_df = pd.DataFrame(summary_rows)
    summary_df.to_csv(output_dir / "session_summary.csv", index=False)

    print("Visualization pipeline complete.")
    print(f"Sessions processed: {len(summary_df)}")
    print(f"Output directory: {output_dir}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Visualize Signals to Pathways JSON exports"
    )
    parser.add_argument(
        "--input-dir",
        type=Path,
        required=True,
        help="Directory containing exported JSON files",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        required=True,
        help="Directory where plots and CSVs will be saved",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    run_pipeline(args.input_dir, args.output_dir)