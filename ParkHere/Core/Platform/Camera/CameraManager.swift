//
//  CameraManager.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 26/05/26.
//

import AVFoundation
import Combine
import CoreLocation
import UIKit

final class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let photoOutput = AVCapturePhotoOutput()

    private var currentInput: AVCaptureDeviceInput?
    private var photoCaptureProcessor: PhotoCaptureProcessor?

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    @Published var zoomFactor: CGFloat = 1.0
    @Published var minZoomFactor: CGFloat = 1.0
    @Published var maxZoomFactor: CGFloat = 1.0
    @Published var zoomFactors: [CGFloat] = [1.0]

    @Published var flashMode: CameraFlashMode = .off
    @Published var isFlashAvailable = false
    @Published var isTorchOn = false

    private var sessionIsConfigured = false
    private var shouldRunSession = false
    private let maxDisplayZoomFactor: CGFloat = 10.0

    override init() {
        super.init()

        checkPermissionAndSetup()
    }

    var shouldShowSettingsButton: Bool {
        cameraAuthorizationStatus == .denied || cameraAuthorizationStatus == .restricted
    }

    private func checkPermissionAndSetup() {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        cameraAuthorizationStatus = authorizationStatus
        
        switch authorizationStatus {
        case .authorized:
            errorMessage = nil

            if !sessionIsConfigured {
                configureSessionAsync(position: .back)
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else {
                    DispatchQueue.main.async {
                        self?.cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                        self?.errorMessage = "Camera access is off. Enable it in Settings to capture landmark photos."
                    }

                    return
                }

                DispatchQueue.main.async {
                    self?.cameraAuthorizationStatus = .authorized
                    self?.errorMessage = nil
                }

                self?.configureSessionAsync(position: .back)
            }
        case .denied, .restricted:
            errorMessage = "Camera access is off. Enable it in Settings to capture landmark photos."
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

            if !session.outputs.contains(photoOutput) {
                guard session.canAddOutput(photoOutput) else {
                    publishError("Cannot add camera output.")

                    return
                }

                session.addOutput(photoOutput)
            }

            sessionIsConfigured = true
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
        let displayMultiplier = device.displayVideoZoomFactorMultiplier
        let maxZoom = cappedMaxDeviceZoom(for: device, displayMultiplier: displayMultiplier)
        let defaultCameraZoom: CGFloat = 1.0
        let defaultDeviceZoom = deviceZoomFactor(forCameraZoom: defaultCameraZoom, displayMultiplier: displayMultiplier)
        let clampedDefaultDeviceZoom = min(max(defaultDeviceZoom, device.minAvailableVideoZoomFactor), maxZoom)
        let hasFlash = device.hasFlash && !photoOutput.supportedFlashModes.isEmpty
        let availableZoomFactors = makeZoomFactors(for: device, maxZoom: maxZoom, displayMultiplier: displayMultiplier)

        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = clampedDefaultDeviceZoom
            device.unlockForConfiguration()
        } catch {
            publishError(error.localizedDescription)
        }

        DispatchQueue.main.async { [weak self] in
            self?.cameraPosition = position
            self?.cameraAuthorizationStatus = .authorized
            self?.errorMessage = nil
            self?.zoomFactor = self?.cameraZoomFactor(fromDeviceZoom: clampedDefaultDeviceZoom, displayMultiplier: displayMultiplier) ?? defaultCameraZoom
            self?.minZoomFactor = self?.cameraZoomFactor(fromDeviceZoom: device.minAvailableVideoZoomFactor, displayMultiplier: displayMultiplier) ?? defaultCameraZoom
            self?.maxZoomFactor = self?.cameraZoomFactor(fromDeviceZoom: maxZoom, displayMultiplier: displayMultiplier) ?? maxZoom
            self?.zoomFactors = availableZoomFactors
            self?.isFlashAvailable = hasFlash

            if !hasFlash {
                self?.flashMode = .off
            }

            self?.isTorchOn = false
        }
    }

    private func cappedMaxDeviceZoom(for device: AVCaptureDevice, displayMultiplier: CGFloat) -> CGFloat {
        guard displayMultiplier > 0 else {
            return min(device.maxAvailableVideoZoomFactor, maxDisplayZoomFactor)
        }

        return min(device.maxAvailableVideoZoomFactor, maxDisplayZoomFactor / displayMultiplier)
    }

    private func deviceZoomFactor(forCameraZoom cameraZoom: CGFloat, displayMultiplier: CGFloat) -> CGFloat {
        guard displayMultiplier > 0 else { return cameraZoom }
        return cameraZoom / displayMultiplier
    }

    private func cameraZoomFactor(fromDeviceZoom deviceZoom: CGFloat, displayMultiplier: CGFloat) -> CGFloat {
        guard displayMultiplier > 0 else { return deviceZoom }
        return deviceZoom * displayMultiplier
    }

    private func makeZoomFactors(
        for device: AVCaptureDevice,
        maxZoom: CGFloat,
        displayMultiplier: CGFloat
    ) -> [CGFloat] {
        let minCameraZoom = cameraZoomFactor(fromDeviceZoom: device.minAvailableVideoZoomFactor, displayMultiplier: displayMultiplier)
        let maxCameraZoom = cameraZoomFactor(fromDeviceZoom: maxZoom, displayMultiplier: displayMultiplier)
        let preferredZooms: [CGFloat] = [0.5, 1.0, 2.0]
        let availabilityTolerance: CGFloat = 0.05
        let candidates = preferredZooms
            .map(normalizedZoomButtonFactor)
            .filter {
                $0 >= minCameraZoom - availabilityTolerance
                    && $0 <= maxCameraZoom + availabilityTolerance
            }
        let uniqueCandidates = candidates.reduce(into: [CGFloat]()) { result, factor in
            guard !result.contains(where: { abs($0 - factor) < 0.05 }) else { return }
            result.append(factor)
        }
        .sorted()

        return uniqueCandidates.isEmpty ? [normalizedZoomButtonFactor(minCameraZoom)] : uniqueCandidates
    }

    private func normalizedZoomButtonFactor(_ factor: CGFloat) -> CGFloat {
        let rounded = (factor * 10).rounded() / 10
        let nearestInteger = rounded.rounded()

        if abs(rounded - nearestInteger) < 0.05 {
            return nearestInteger
        }

        return rounded
    }

    func startSession() {
        checkPermissionAndSetup()

        sessionQueue.async { [weak self] in
            guard let self else { return }

            shouldRunSession = true

            guard
                AVCaptureDevice.authorizationStatus(for: .video) == .authorized,
                self.sessionIsConfigured,
                !self.session.isRunning
            else { return }

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

            let displayMultiplier = device.displayVideoZoomFactorMultiplier
            let maxDeviceZoom = cappedMaxDeviceZoom(for: device, displayMultiplier: displayMultiplier)
            let requestedDeviceZoom = deviceZoomFactor(forCameraZoom: factor, displayMultiplier: displayMultiplier)
            let clampedDeviceZoom = min(max(requestedDeviceZoom, device.minAvailableVideoZoomFactor), maxDeviceZoom)

            do {
                try device.lockForConfiguration()

                if animated {
                    device.ramp(toVideoZoomFactor: clampedDeviceZoom, withRate: 5.0)
                } else {
                    device.videoZoomFactor = clampedDeviceZoom
                }

                device.unlockForConfiguration()

                DispatchQueue.main.async {
                    self.zoomFactor = self.cameraZoomFactor(fromDeviceZoom: clampedDeviceZoom, displayMultiplier: displayMultiplier)
                    self.minZoomFactor = self.cameraZoomFactor(fromDeviceZoom: device.minAvailableVideoZoomFactor, displayMultiplier: displayMultiplier)
                    self.maxZoomFactor = self.cameraZoomFactor(fromDeviceZoom: maxDeviceZoom, displayMultiplier: displayMultiplier)
                }
            } catch {
                publishError(error.localizedDescription)
            }
        }
    }

    func focus(at devicePoint: CGPoint) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.currentInput?.device else { return }

            do {
                try device.lockForConfiguration()

                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = devicePoint

                    if device.isFocusModeSupported(.autoFocus) {
                        device.focusMode = .autoFocus
                    } else if device.isFocusModeSupported(.continuousAutoFocus) {
                        device.focusMode = .continuousAutoFocus
                    }
                }

                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = devicePoint

                    if device.isExposureModeSupported(.autoExpose) {
                        device.exposureMode = .autoExpose
                    } else if device.isExposureModeSupported(.continuousAutoExposure) {
                        device.exposureMode = .continuousAutoExposure
                    }
                }

                device.unlockForConfiguration()
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

    func takePhoto(location: CLLocation? = nil, completion: @escaping (UIImage, CLLocation?) -> Void) {
        guard !isLoading else { return }

        let selectedFlashMode = flashMode.avFlashMode

        isLoading = true
        errorMessage = nil

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

                        completion(image, location)
                    case .failure(let message):
                        self.errorMessage = message.localizedDescription
                    }
                }
            }

            self.photoCaptureProcessor = processor
            self.photoOutput.capturePhoto(with: settings, delegate: processor)
        }
    }

    private func publishError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = message
        }
    }
}
