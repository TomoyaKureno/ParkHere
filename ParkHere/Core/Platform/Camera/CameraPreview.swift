//
//  CameraPreview.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 29/05/26.
//

import AVFoundation
import SwiftUI
import UIKit

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let onTapToFocus: ((CGPoint, CGPoint) -> Void)?

    init(
        session: AVCaptureSession,
        onTapToFocus: ((CGPoint, CGPoint) -> Void)? = nil
    ) {
        self.session = session
        self.onTapToFocus = onTapToFocus
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewView.session = session
        view.videoPreviewView.videoGravity = .resizeAspectFill
        view.onTapToFocus = onTapToFocus

        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.onTapToFocus = onTapToFocus
    }

    final class PreviewView: UIView {
        var onTapToFocus: ((CGPoint, CGPoint) -> Void)?
        private var focusIndicatorLayer: CAShapeLayer?

        override init(frame: CGRect) {
            super.init(frame: frame)

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            addGestureRecognizer(tapGesture)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        var videoPreviewView: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            videoPreviewView.frame = bounds
        }

        @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
            let viewPoint = gesture.location(in: self)
            let devicePoint = videoPreviewView.captureDevicePointConverted(fromLayerPoint: viewPoint)

            showFocusIndicator(at: viewPoint)
            onTapToFocus?(devicePoint, viewPoint)
        }

        private func showFocusIndicator(at point: CGPoint) {
            focusIndicatorLayer?.removeFromSuperlayer()

            let size: CGFloat = 72
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            let indicatorLayer = CAShapeLayer()
            indicatorLayer.bounds = rect
            indicatorLayer.position = point
            indicatorLayer.path = UIBezierPath(ovalIn: rect).cgPath
            indicatorLayer.fillColor = UIColor.clear.cgColor
            indicatorLayer.strokeColor = UIColor.systemYellow.cgColor
            indicatorLayer.lineWidth = 1.5
            indicatorLayer.opacity = 0

            layer.addSublayer(indicatorLayer)
            focusIndicatorLayer = indicatorLayer

            let fadeIn = CABasicAnimation(keyPath: "opacity")
            fadeIn.fromValue = 0
            fadeIn.toValue = 1
            fadeIn.duration = 0.15
            fadeIn.timingFunction = CAMediaTimingFunction(name: .easeOut)

            let scale = CAKeyframeAnimation(keyPath: "transform")
            scale.values = [
                CATransform3DMakeScale(1.35, 1.35, 1),
                CATransform3DMakeScale(0.88, 0.88, 1),
                CATransform3DIdentity
            ]
            scale.keyTimes = [0, 0.72, 1]
            scale.duration = 0.28
            scale.timingFunctions = [
                CAMediaTimingFunction(name: .easeOut),
                CAMediaTimingFunction(name: .easeInEaseOut)
            ]

            indicatorLayer.opacity = 1
            indicatorLayer.add(fadeIn, forKey: "focusIndicatorFadeIn")
            indicatorLayer.add(scale, forKey: "focusIndicatorScale")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self, weak indicatorLayer] in
                guard let self, let indicatorLayer, self.focusIndicatorLayer === indicatorLayer else { return }

                CATransaction.begin()
                CATransaction.setCompletionBlock {
                    indicatorLayer.removeFromSuperlayer()
                    if self.focusIndicatorLayer === indicatorLayer {
                        self.focusIndicatorLayer = nil
                    }
                }

                let fadeOut = CABasicAnimation(keyPath: "opacity")
                fadeOut.fromValue = indicatorLayer.opacity
                fadeOut.toValue = 0
                fadeOut.duration = 0.2
                fadeOut.timingFunction = CAMediaTimingFunction(name: .easeIn)
                indicatorLayer.opacity = 0
                indicatorLayer.add(fadeOut, forKey: "focusIndicatorFadeOut")

                CATransaction.commit()
            }
        }
    }
}
