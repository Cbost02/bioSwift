//
//  TouchPadView.swift
//  tap_count_test
//
//  Created by Cromwell on 1/23/26.
//

import SwiftUI
import UIKit

struct TouchPadView: UIViewRepresentable {

    var onTouch: (String, CGPoint, TimeInterval) -> Void

    final class PadView: UIView {
        var onTouch: ((String, CGPoint, TimeInterval) -> Void)?

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let t = touches.first else { return }
            onTouch?("began", t.location(in: self), t.timestamp)
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let t = touches.first else { return }
            onTouch?("moved", t.location(in: self), t.timestamp)
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let t = touches.first else { return }
            onTouch?("ended", t.location(in: self), t.timestamp)
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let t = touches.first else { return }
            onTouch?("cancelled", t.location(in: self), t.timestamp)
        }
    }

    func makeUIView(context: Context) -> PadView {
        let v = PadView()
        v.onTouch = onTouch
        v.backgroundColor = UIColor.secondarySystemBackground
        v.layer.cornerRadius = 16
        v.isMultipleTouchEnabled = false  // keep it simple for now
        return v
    }

    func updateUIView(_ uiView: PadView, context: Context) {}
}
