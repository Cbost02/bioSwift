//
//  OrientationView.swift
//  tap_count_test
//
//  Created by Cromwell on 3/6/26.
//

import SwiftUI
import CoreMotion

struct OrientationSample: Codable {
    let time: Double
    let pitch: Double
    let roll: Double
    let yaw: Double
}

struct OrientationSessionExport: Codable {
    let startedAt: Date
    let countdownDuration: Int
    let recordingDuration: Int
    let sampleCount: Int
    let samples: [OrientationSample]
}

struct OrientationView: View {
    private let motionManager = CMMotionManager()

    @State private var isCountingDown = false
    @State private var isRecording = false

    @State private var countdownValue = 5
    @State private var statusText = "Press Start to begin"

    @State private var samples: [OrientationSample] = []
    @State private var startTime = Date()

    @State private var currentPitch: Double = 0
    @State private var currentRoll: Double = 0
    @State private var currentYaw: Double = 0

    @State private var lastExportURL: URL? = nil
    @State private var exportStatus: String = ""

    let countdownDuration = 5
    let recordingDuration = 10
    let sampleRateHz = 10.0

    var body: some View {
        VStack(spacing: 20) {
            Text("Orientation Activity")
                .font(.title2)

            Text(statusText)
                .font(.headline)
                .multilineTextAlignment(.center)

            if isCountingDown {
                Text("\(countdownValue)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.orange)
            }

            VStack(spacing: 8) {
                Text("Pitch: \(String(format: "%.3f", currentPitch))")
                Text("Roll: \(String(format: "%.3f", currentRoll))")
                Text("Yaw: \(String(format: "%.3f", currentYaw))")
            }
            .font(.headline)

            Button("Start Session") {
                beginSession()
            }
            .disabled(isCountingDown || isRecording)
            .buttonStyle(.borderedProminent)

            Button("Export Session") {
                exportSession()
            }
            .disabled(samples.isEmpty || isCountingDown || isRecording)
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

            List(samples.indices, id: \.self) { i in
                Text(
                    "t=\(String(format: "%.3f", samples[i].time)) " +
                    "p=\(String(format: "%.2f", samples[i].pitch)) " +
                    "r=\(String(format: "%.2f", samples[i].roll)) " +
                    "y=\(String(format: "%.2f", samples[i].yaw))"
                )
                .font(.caption)
                .lineLimit(1)
            }
        }
        .padding()
        .navigationTitle("Orientation")
        .background(Color(.systemGroupedBackground))
        .onDisappear {
            stopMotionUpdates()
        }
    }

    // MARK: - Session Flow

    func beginSession() {
        samples.removeAll()
        lastExportURL = nil
        exportStatus = ""
        currentPitch = 0
        currentRoll = 0
        currentYaw = 0

        isCountingDown = true
        isRecording = false
        countdownValue = countdownDuration
        statusText = "Hold the phone steady.\nRecording begins soon."

        runCountdown()
    }

    func runCountdown() {
        if countdownValue > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                countdownValue -= 1
                runCountdown()
            }
        } else {
            isCountingDown = false
            startRecording()
        }
    }

    func startRecording() {
        statusText = "Recording... Hold the phone still."
        isRecording = true
        startTime = Date()

        motionManager.deviceMotionUpdateInterval = 1.0 / sampleRateHz

        motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
            guard let motion = motion, isRecording else { return }

            let elapsed = Date().timeIntervalSince(startTime)

            let pitch = motion.attitude.pitch
            let roll = motion.attitude.roll
            let yaw = motion.attitude.yaw

            currentPitch = pitch
            currentRoll = roll
            currentYaw = yaw

            samples.append(
                OrientationSample(
                    time: elapsed,
                    pitch: pitch,
                    roll: roll,
                    yaw: yaw
                )
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Double(recordingDuration)) {
            stopRecording()
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        isRecording = false
        stopMotionUpdates()
        statusText = "Session complete. You may now export the data."
    }

    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }

    // MARK: - Export

    func exportSession() {
        let session = OrientationSessionExport(
            startedAt: startTime,
            countdownDuration: countdownDuration,
            recordingDuration: recordingDuration,
            sampleCount: samples.count,
            samples: samples
        )

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            encoder.dateEncodingStrategy = .iso8601

            let data = try encoder.encode(session)

            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let filename = "orientation_session_" + ISO8601DateFormatter().string(from: Date()) + ".json"
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
        OrientationView()
    }
}
