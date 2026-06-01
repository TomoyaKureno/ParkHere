//
//  CameraManager.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 26/05/26.
//

import AVFoundation
import Combine
import UIKit

final class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let photoOutput = AVCapturePhotoOutput()
    
    private var currentInput: AVCaptureDeviceInput?
    private var photoCaptureProcessor: PhotoCaptureProcessor?

    @Published var cameraState: CameraState = .takePhoto
    @Published var capturedImages: [UIImage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    @Published var zoomFactor: CGFloat = 1.0
    @Published var minZoomFactor: CGFloat = 1.0
    @Published var maxZoomFactor: CGFloat = 1.0
    
    @Published var flashMode: CameraFlashMode = .off
    @Published var isFlashAvailable = false
    @Published var isTorchOn = false
    
    private var sessionIsConfigured = false
    private var shouldRunSession = false

    override init() {
        super.init()
        
        checkPermissionAndSetup()
    }
    
    private func checkPermissionAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSessionAsync(position: .back)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else {
                    DispatchQueue.main.async {
                        self?.errorMessage = "Camera access is denied."
                    }
                    
                    return
                }
                
                self?.configureSessionAsync(position: .back)
            }
        case .denied, .restricted:
            errorMessage = "Camera permission denied or restricted."
        @unknown default:
            errorMessage = "Unknown camera permission status."
        }
    }
    
    private func configureSessionAsync(position: AVCaptureDevice.Position) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            
            self.configureSession(position: position)
            
            if self.shouldRunSession, !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    private func configureSession(position: AVCaptureDevice.Position) {
        guard !sessionIsConfigured else { return }
        
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        session.sessionPreset = .photo
        
        if let currentInput {
            session.removeInput(currentInput)
            self.currentInput = nil
        }
        
        guard let camera = makeCamera(position: position) else {
            publishError("Camera device not found.")
            
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            
            guard session.canAddInput(input) else {
                publishError("Cannot add camera input.")
                
                return
            }
            
            session.addInput(input)
            currentInput = input
            
            if session.outputs.contains(photoOutput) {
                guard session.canAddOutput(photoOutput) else {
                    publishError("Cannot add camera output.")
                    
                    return
                }
                
                session.addOutput(photoOutput)
            }
            
            publishCameraCapabilities(for: camera, position: position)
        } catch {
            publishError(error.localizedDescription)
        }
    }
    
    private func makeCamera(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if position == .back {
            return AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) ??
                AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) ??
                AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        } else {
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        }
    }
    
    private func publishCameraCapabilities(
        for device: AVCaptureDevice,
        position: AVCaptureDevice.Position
    ) {
        let maxZoom = min(device.maxAvailableVideoZoomFactor, 10.0)
        let hasFlash = device.hasFlash && !photoOutput.supportedFlashModes.isEmpty
        
        DispatchQueue.main.async { [weak self] in
            self?.cameraPosition = position
            self?.zoomFactor = 1.0
            self?.minZoomFactor = 1.0
            self?.maxZoomFactor = maxZoom
            self?.isFlashAvailable = hasFlash
            
            if !hasFlash {
                self?.flashMode = .off
            }
            
            self?.isTorchOn = false
            
            self?.sessionIsConfigured = true
        }
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            
            shouldRunSession = true
            
            guard self.sessionIsConfigured, !self.session.isRunning else { return }
            
            self.session.startRunning()
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            
            shouldRunSession = false
            
            guard self.session.isRunning else { return }
            
            self.session.stopRunning()
        }
    }
    
    func switchCamera() {
        let newPosition: AVCaptureDevice.Position = cameraPosition == .back ? .front : .back
        
        sessionQueue.async { [weak self] in
            self?.configureSession(position: newPosition)
            
            if self?.session.isRunning == false {
                self?.session.startRunning()
            }
        }
    }
    
    func setZoomFactor(_ factor: CGFloat, animated: Bool = false) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.currentInput?.device else { return }
            
            let maxZoom = min(device.maxAvailableVideoZoomFactor, 10.0)
            let clampedFactor = min(max(factor, 1.0), maxZoom)
            
            do {
                try device.lockForConfiguration()
                
                if animated {
                    device.ramp(toVideoZoomFactor: clampedFactor, withRate: 5.0)
                } else {
                    device.videoZoomFactor = clampedFactor
                }
                
                device.unlockForConfiguration()
                
                DispatchQueue.main.async {
                    self.zoomFactor = clampedFactor
                    self.maxZoomFactor = maxZoom
                }
            } catch {
                publishError(error.localizedDescription)
            }
        }
    }
    
    func setFlashMode(_ mode: CameraFlashMode) {
        guard isFlashAvailable else {
            flashMode = .off
            
            return
        }
        
        flashMode = mode
    }
    
    func cycleFlashMode() {
        switch flashMode {
        case .off:
            setFlashMode(.on)
        case .on:
            setFlashMode(.auto)
        case .auto:
            setFlashMode(.off)
        }
    }
    
    func setTorch(_ isOn: Bool) {
        sessionQueue.async { [weak self] in
            guard
                let self,
                let device = self.currentInput?.device,
                device.hasTorch,
                device.isTorchModeSupported(.on)
            else { return }
            
            do {
                try device.lockForConfiguration()
                
                if isOn {
                    try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                } else {
                    device.torchMode = .off
                }
                
                device.unlockForConfiguration()
                
                DispatchQueue.main.async {
                    self.isTorchOn = isOn
                }
            } catch {
                publishError(error.localizedDescription)
            }
        }
    }
    
    func takePhoto() {
        let selectedFlashMode = flashMode.avFlashMode
        
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
        }
        
        sessionQueue.async { [weak self] in
            guard let self else { return }
            
            let settings = AVCapturePhotoSettings()
            
            if self.photoOutput.supportedFlashModes.contains(selectedFlashMode) {
                settings.flashMode = selectedFlashMode
            }
            
            let processor = PhotoCaptureProcessor { [weak self] result in
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    
                    self.isLoading = false
                    self.photoCaptureProcessor = nil
                    
                    switch result {
                    case .success(let data):
                        guard let image = UIImage(data: data) else {
                            self.errorMessage = "Failed to convert photo to image."
                            
                            return
                        }
                        
                        self.cameraState = .previewPhoto(image: image)
                        
                    case .failure(let message):
                        self.errorMessage = message.localizedDescription
                    }
                }
            }
            
            self.photoCaptureProcessor = processor
            self.photoOutput.capturePhoto(with: settings, delegate: processor)
        }
    }
    
    func saveImage(newImage: UIImage) {
        capturedImages.append(newImage)
    }
    
    private func publishError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = message
        }
    }
}
