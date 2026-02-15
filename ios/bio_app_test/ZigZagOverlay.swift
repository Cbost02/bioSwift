import SwiftUI

struct ZigZagOverlay: View {
    var segmentCount: Int = 10
    var amplitudeRatio: CGFloat = 0.25   // relative to usable height
    var marginRatio: CGFloat = 0.12      // relative to min(w,h)
    var lineWidth: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let points = makePoints(in: geo.size)

            ZStack {
                // Zig-zag path
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    for p in points.dropFirst() {
                        path.addLine(to: p)
                    }
                }
                .stroke(
                    Color.black,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

                // Start / End markers
                if let start = points.first, let end = points.last {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .position(start)

                    Circle()
                        .fill(Color.blue)
                        .frame(width: 14, height: 14)
                        .position(end)

                    Text("START")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                        .position(x: start.x, y: start.y - 18)

                    Text("END")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                        .position(x: end.x, y: end.y - 18)
                }
            }
        }
    }

    private func makePoints(in size: CGSize) -> [CGPoint] {
        let w = size.width
        let h = size.height
        let margin = min(w, h) * marginRatio

        let usableW = max(1, w - 2 * margin)
        let usableH = max(1, h - 2 * margin)

        let dx = usableW / CGFloat(max(1, segmentCount))
        let centerY = margin + usableH / 2
        let amp = usableH * amplitudeRatio * 0.5  // stays inside margins

        var points: [CGPoint] = []
        points.reserveCapacity(segmentCount + 1)

        // Start at top, then bottom, alternating
        for i in 0...segmentCount {
            let x = margin + dx * CGFloat(i)
            let yOffset: CGFloat = (i % 2 == 0) ? -amp : amp
            let y = centerY + yOffset
            points.append(CGPoint(x: x, y: y))
        }

        return points
    }
}

