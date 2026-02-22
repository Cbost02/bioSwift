# Signals to Pathways: Interpreting Mobile Motor Data Through Bioinformatics

Signals to Pathways is a mobile research platform for collecting high-resolution human motor control data via interactive touch tasks, designed to support reproducible analysis through normalized, anonymized JSON exports.

## Features

- Zig-zag tracing capture
- Normalized coordinates
- JSON Export
- Privacy/anonymization stance

## Data Format

Each activity exports anonymized JSON containing timestamped touch samples.
A typical sample includes:

- `time` — elapsed time (seconds)
- `x`, `y` — normalized coordinates ∈ [0, 1]
- `phase` — touch phase (`began`, `moved`, `ended`)

This format is designed for downstream feature extraction
(e.g., velocity, smoothness, deviation) and statistical analysis.

## Roadmap

- [x] iOS zig-zag tracing prototype
- [x] Normalized touch sampling + JSON export
- [ ] Android (Flutter) parity for zig-zag tracing
- [ ] Additional motor tasks (tapping, swiping)
- [ ] Feature extraction & analysis pipeline

## Tech Stack

- iOS: SwiftUI + touch sampling + file export
- (Development in progress) Android: Flutter + gesture sampling + export


## Run locally

- requirements: Xcode version
- open .xcodeproj / scheme
- run on device
