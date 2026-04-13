from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

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


def base_metadata(file_path: Path, payload: dict[str, Any], schema: str) -> dict[str, Any]:
    return {
        "source_file": file_path.name,
        "schema": schema,
        "activity": infer_activity(schema, file_path, payload),
        "started_at": str(payload.get("startedAt", "unknown")).strip(),
        "platform": str(payload.get("platform", "unknown")).strip().lower(),
        "reported_sample_count": int(payload.get("sampleCount", len(payload.get("samples", [])))),
        "reported_session_duration": float(payload.get("sessionDuration", np.nan)),
    }


def process_path_file(file_path: Path, payload: dict[str, Any]) -> dict[str, Any]:
    metadata = base_metadata(file_path, payload, "path")

    session_df = pd.DataFrame(payload["samples"]).copy()
    session_df["x"] = pd.to_numeric(session_df["x"], errors="coerce")
    session_df["y"] = pd.to_numeric(session_df["y"], errors="coerce")
    session_df["time"] = pd.to_numeric(session_df["time"], errors="coerce")
    session_df["phase"] = session_df.get("phase", "unknown")
    session_df = session_df.dropna(subset=["x", "y", "time"]).sort_values("time").reset_index(drop=True)

    session_df["dt"] = session_df["time"].diff()
    session_df["dx"] = session_df["x"].diff()
    session_df["dy"] = session_df["y"].diff()
    session_df["step_distance"] = np.sqrt(
        session_df["dx"].fillna(0.0) ** 2 + session_df["dy"].fillna(0.0) ** 2
    )
    session_df["speed"] = session_df["step_distance"] / session_df["dt"]
    session_df["speed"] = session_df["speed"].replace([np.inf, -np.inf], np.nan)

    first_row = session_df.iloc[0]
    last_row = session_df.iloc[-1]

    net_dx = float(last_row["x"] - first_row["x"])
    net_dy = float(last_row["y"] - first_row["y"])
    net_displacement = float(np.sqrt(net_dx ** 2 + net_dy ** 2))
    path_length = float(session_df["step_distance"].sum())
    duration = float(last_row["time"] - first_row["time"]) if len(session_df) > 1 else 0.0
    straightness_ratio = net_displacement / path_length if path_length > 0 else np.nan

    return {
        **metadata,
        "sample_count": int(len(session_df)),
        "first_time": float(session_df["time"].min()),
        "last_time": float(session_df["time"].max()),
        "duration": duration,
        "x_start": float(first_row["x"]),
        "y_start": float(first_row["y"]),
        "x_end": float(last_row["x"]),
        "y_end": float(last_row["y"]),
        "x_range": float(session_df["x"].max() - session_df["x"].min()),
        "y_range": float(session_df["y"].max() - session_df["y"].min()),
        "path_length": path_length,
        "net_displacement": net_displacement,
        "straightness_ratio": float(straightness_ratio) if not pd.isna(straightness_ratio) else np.nan,
        "mean_speed": float(session_df["speed"].dropna().mean()) if not session_df["speed"].dropna().empty else np.nan,
        "max_speed": float(session_df["speed"].dropna().max()) if not session_df["speed"].dropna().empty else np.nan,
        "speed_std": float(session_df["speed"].dropna().std()) if not session_df["speed"].dropna().empty else np.nan,
        "began_count": int((session_df["phase"].astype(str).str.lower() == "began").sum()),
        "moved_count": int((session_df["phase"].astype(str).str.lower() == "moved").sum()),
        "ended_count": int((session_df["phase"].astype(str).str.lower() == "ended").sum()),
    }


def process_tapping_file(file_path: Path, payload: dict[str, Any]) -> dict[str, Any]:
    metadata = base_metadata(file_path, payload, "tapping")

    session_df = pd.DataFrame(payload["samples"]).copy()
    session_df["x"] = pd.to_numeric(session_df["x"], errors="coerce")
    session_df["y"] = pd.to_numeric(session_df["y"], errors="coerce")
    session_df["time"] = pd.to_numeric(session_df["time"], errors="coerce")
    session_df = session_df.dropna(subset=["x", "y", "time"]).sort_values("time").reset_index(drop=True)

    session_df["tap_interval"] = session_df["time"].diff()

    intervals = session_df["tap_interval"].dropna()

    return {
        **metadata,
        "sample_count": int(len(session_df)),
        "tap_count": int(len(session_df)),
        "first_time": float(session_df["time"].min()),
        "last_time": float(session_df["time"].max()),
        "duration": float(session_df["time"].max() - session_df["time"].min()) if len(session_df) > 1 else 0.0,
        "x_range": float(session_df["x"].max() - session_df["x"].min()),
        "y_range": float(session_df["y"].max() - session_df["y"].min()),
        "mean_tap_interval": float(intervals.mean()) if not intervals.empty else np.nan,
        "min_tap_interval": float(intervals.min()) if not intervals.empty else np.nan,
        "max_tap_interval": float(intervals.max()) if not intervals.empty else np.nan,
        "tap_interval_std": float(intervals.std()) if not intervals.empty else np.nan,
    }


def process_orientation_file(file_path: Path, payload: dict[str, Any]) -> dict[str, Any]:
    metadata = base_metadata(file_path, payload, "orientation")

    session_df = pd.DataFrame(payload["samples"]).copy()
    for column in ["yaw", "pitch", "roll", "time"]:
        session_df[column] = pd.to_numeric(session_df[column], errors="coerce")

    session_df = session_df.dropna(subset=["yaw", "pitch", "roll", "time"]).sort_values("time").reset_index(drop=True)

    def stats(prefix: str) -> dict[str, float]:
        series = session_df[prefix]
        return {
            f"{prefix}_mean": float(series.mean()),
            f"{prefix}_std": float(series.std()),
            f"{prefix}_min": float(series.min()),
            f"{prefix}_max": float(series.max()),
            f"{prefix}_range": float(series.max() - series.min()),
        }

    return {
        **metadata,
        "sample_count": int(len(session_df)),
        "first_time": float(session_df["time"].min()),
        "last_time": float(session_df["time"].max()),
        "duration": float(session_df["time"].max() - session_df["time"].min()) if len(session_df) > 1 else 0.0,
        **stats("yaw"),
        **stats("pitch"),
        **stats("roll"),
    }


def run_pipeline(input_dir: Path, output_csv: Path) -> None:
    json_files = sorted(input_dir.rglob("*.json"))
    if not json_files:
        raise FileNotFoundError(f"No JSON files found in {input_dir}")

    metric_rows: list[dict[str, Any]] = []

    for file_path in json_files:
        try:
            payload = load_json_payload(file_path)
            schema = detect_schema(payload, file_path)

            if schema == "path":
                metric_rows.append(process_path_file(file_path, payload))
            elif schema == "tapping":
                metric_rows.append(process_tapping_file(file_path, payload))
            elif schema == "orientation":
                metric_rows.append(process_orientation_file(file_path, payload))

        except Exception as error:
            print(f"Skipping {file_path.name}: {error}")

    if not metric_rows:
        raise ValueError("No supported JSON files were processed.")

    metrics_df = pd.DataFrame(metric_rows)
    output_csv.parent.mkdir(parents=True, exist_ok=True)
    metrics_df.to_csv(output_csv, index=False)

    print("Metrics extraction complete.")
    print(f"Sessions processed: {len(metrics_df)}")
    print(f"Saved to: {output_csv}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Extract session-level metrics from Signals to Pathways JSON exports"
    )
    parser.add_argument(
        "--input-dir",
        type=Path,
        required=True,
        help="Directory containing exported JSON files",
    )
    parser.add_argument(
        "--output-csv",
        type=Path,
        required=True,
        help="Path to save the session metrics CSV",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    run_pipeline(args.input_dir, args.output_csv)