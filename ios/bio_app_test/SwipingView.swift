//
//  SwipingView.swift
//  tap_count_test
//
//  Created by Cromwell on 3/6/26.
//

import SwiftUI


// Swiping Schema
struct SwipeSample: Codable
{
    let time: Double
    let x: Double
    let y: Double
    let phase: String
}


struct SwipeSessionExport: Codable
{
    let startedAt: Date
    let swipeCount: Int
    let samples: [SwipeSample]
}

struct SwipingView: View {
    @State private var swipeCount: Int = 0
    @State private var isRunning: Bool = false

    @State private var samples: [SwipeSample] = []
    @State private var startTime = Date()

    @State private var dragStart: CGPoint? = nil
    @State private var dragCurrent: CGPoint? = nil

    @State private var lastExportURL: URL? = nil
    @State private var exportStatus: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Swipe Count: \(swipeCount)")
                .font(.title2)

            Button(isRunning ? "Reset Session" : "Start Session") {
                swipeCount = 0
                isRunning = true
                samples.removeAll()
                startTime = Date()
                dragStart = nil
                dragCurrent = nil
                lastExportURL = nil
                exportStatus = ""
            }
            .buttonStyle(.borderedProminent)

            Button("Stop Session") {
                isRunning = false
                dragStart = nil
                dragCurrent = nil
            }
            .disabled(!isRunning)
            .buttonStyle(.bordered)

            Button("Export Session") {
                exportSession()
            }
            .disabled(samples.isEmpty)
            .buttonStyle(.bordered)

            Text(exportStatus)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let url = lastExportURL {
                ShareLink(item: url) {
                    Text("Share Export File")
                }
            }

            Spacer()

            GeometryReader { geo in
                ZStack {
                    Rectangle()
                        .fill(Color.white)
                        .border(Color.black, width: 1)

                    Text("Swipe Here")
                        .font(.title3)
                        .foregroundStyle(.black)

                    if let start = dragStart, let current = dragCurrent {
                        Path { path in
                            path.move(to: start)
                            path.addLine(to: current)
                        }
                        .stroke(Color.blue, lineWidth: 4)

                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .position(current)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            guard isRunning else { return }

                            let width = geo.size.width
                            let height = geo.size.height
                            guard width > 0, height > 0 else { return }

                            let point = value.location
                            let normalizedX = max(0.0, min(1.0, point.x / width))
                            let normalizedY = max(0.0, min(1.0, point.y / height))
                            let elapsed = Date().timeIntervalSince(startTime)

                            if dragStart == nil {
                                dragStart = value.startLocation
                                samples.append(
                                    SwipeSample(
                                        time: elapsed,
                                        x: normalizedX,
                                        y: normalizedY,
                                        phase: "began"
                                    )
                                )
                            } else {
                                samples.append(
                                    SwipeSample(
                                        time: elapsed,
                                        x: normalizedX,
                                        y: normalizedY,
                                        phase: "moved"
                                    )
                                )
                            }

                            dragCurrent = value.location
                        }
                        .onEnded { value in
                            guard isRunning else { return }

                            let width = geo.size.width
                            let height = geo.size.height
                            guard width > 0, height > 0 else { return }

                            let point = value.location
                            let normalizedX = max(0.0, min(1.0, point.x / width))
                            let normalizedY = max(0.0, min(1.0, point.y / height))
                            let elapsed = Date().timeIntervalSince(startTime)

                            samples.append(
                                SwipeSample(
                                    time: elapsed,
                                    x: normalizedX,
                                    y: normalizedY,
                                    phase: "ended"
                                )
                            )

                            swipeCount += 1
                            dragStart = nil
                            dragCurrent = nil
                        }
                )
            }
            .frame(height: 300)

            Spacer()

            List(samples.indices, id: \.self) { i in
                Text(
                    "Sample \(i + 1): t=\(String(format: "%.3f", samples[i].time))s " +
                    "(\(String(format: "%.3f", samples[i].x)), \(String(format: "%.3f", samples[i].y))) " +
                    "\(samples[i].phase)"
                )
                .font(.caption)
                .lineLimit(1)
            }
        }
        .padding()
        .navigationTitle("Swiping Activity")
        .background(Color(.systemGroupedBackground))
    }

    func exportSession() {
        let session = SwipeSessionExport(
            startedAt: startTime,
            swipeCount: swipeCount,
            samples: samples
        )

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            encoder.dateEncodingStrategy = .iso8601

            let data = try encoder.encode(session)

            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let filename = "swiping_session_" + ISO8601DateFormatter().string(from: Date()) + ".json"
            let url = docs.appendingPathComponent(filename)

            try data.write(to: url, options: [.atomic])

            lastExportURL = url
            exportStatus = "Exported: \(filename)"
        } catch {
            exportStatus = "Export failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        SwipingView()
    }
}
