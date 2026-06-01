//
//  PhotoCaptureProcessor.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 01/06/26.
//

import UIKit
import AVFoundation
import Foundation

enum PhotoCaptureProcessorError: LocalizedError {
    case failedToConvertPhotoToImageData
    
    var errorDescription: String? {
        switch self {
        case .failedToConvertPhotoToImageData:
            return "Failed to convert photo to image data"
        }
    }
}

nonisolated final class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Result<Data, Error>) -> Void
    
    init(completion: @escaping (Result<Data, Error>) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: (any Error)?
    ) {
        if let error {
            completion(.failure(error))
            
            return
        }
        
        guard let data = photo.fileDataRepresentation() else {
            completion(.failure(PhotoCaptureProcessorError.failedToConvertPhotoToImageData))
            
            return
        }
        
        completion(.success(data))
    }
}
