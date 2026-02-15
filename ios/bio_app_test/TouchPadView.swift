import SwiftUI
import UIKit

final class TouchPadUIView: UIView {

    var onTouch: ((String, CGPoint, TimeInterval) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = false
        isUserInteractionEnabled = true
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func emit(_ phase: String, _ touch: UITouch) {
        let p = touch.location(in: self)              // local coordinates (safe)
        let t = touch.timestamp                       // TimeInterval
        onTouch?(phase, p, t)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        emit("began", touch)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        emit("moved", touch)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        emit("ended", touch)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        emit("cancelled", touch)
    }
}

struct TouchPadView: UIViewRepresentable {

    let handler: (String, CGPoint, TimeInterval) -> Void

    func makeUIView(context: Context) -> TouchPadUIView {
        let v = TouchPadUIView()
        v.onTouch = handler
        return v
    }

    func updateUIView(_ uiView: TouchPadUIView, context: Context) {
        // keep closure up-to-date across SwiftUI updates
        uiView.onTouch = handler
    }
}

