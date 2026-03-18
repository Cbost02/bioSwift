//
//  TappingView.swift
//  tap_count_test
//
//  Created by Cromwell on 3/6/26.
//

import SwiftUI

struct TapSample: Codable {
    let time: Double
    let x: Double
    let y: Double
}

struct TapSessionExport: Codable {
    let startedAt: Date
    let tapCount: Int
    let samples: [TapSample]
}

struct TappingView: View {
    @State private var tapCount: Int = 0
    @State private var isRunning: Bool = false

    @State private var samples: [TapSample] = []
    @State private var startTime = Date()

    @State private var lastExportURL: URL? = nil
    @State private var exportStatus: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Tap Count: \(tapCount)")
                .font(.title2)

            Button(isRunning ? "Reset Session" : "Start Session") {
                tapCount = 0
                isRunning = true
                samples.removeAll()
                startTime = Date()
                lastExportURL = nil
                exportStatus = ""
            }
            .buttonStyle(.borderedProminent)

            Button("Stop Session") {
                isRunning = false
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
                Rectangle()
                    .fill(Color.white)
                    .border(Color.black, width: 1)
                    .overlay(
                        Text("Tap Here")
                            .font(.title3)
                            .foregroundStyle(.black)
                    )
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                guard isRunning else { return }

                                let localPoint = value.location
                                let width = geo.size.width
                                let height = geo.size.height

                                guard width > 0, height > 0 else { return }

                                let normalizedX = max(0.0, min(1.0, localPoint.x / width))
                                let normalizedY = max(0.0, min(1.0, localPoint.y / height))
                                let elapsed = Date().timeIntervalSince(startTime)

                                samples.append(
                                    TapSample(
                                        time: elapsed,
                                        x: normalizedX,
                                        y: normalizedY
                                    )
                                )

                                tapCount += 1
                            }
                    )
            }
            .frame(height: 300)

            Spacer()

            List(samples.indices, id: \.self) { i in
                Text(
                    "Tap \(i + 1): t=\(String(format: "%.3f", samples[i].time))s " +
                    "(\(String(format: "%.3f", samples[i].x)), \(String(format: "%.3f", samples[i].y)))"
                )
                .font(.caption)
                .lineLimit(1)
            }
        }
        .padding()
        .navigationTitle("Tapping Activity")
        .background(Color(.systemGroupedBackground))
    }

    func exportSession() {
        let session = TapSessionExport(
            startedAt: startTime,
            tapCount: tapCount,
            samples: samples
        )

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            encoder.dateEncodingStrategy = .iso8601

            let data = try encoder.encode(session)

            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let filename = "tapping_session_" + ISO8601DateFormatter().string(from: Date()) + ".json"
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
        TappingView()
    }
}
