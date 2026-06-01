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
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewView.session = session
        view.videoPreviewView.videoGravity = .resizeAspectFill
        
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {}
    
    final class PreviewView: UIView {
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
    }
}
