//
//  PhotosAndVideoManager.swift
//  rawDataiOSAppAcquisition
//

import AVFoundation
import SwiftUI

class PhotosAndVideoManager: NSObject, ObservableObject {
    private var captureSession: AVCaptureSession!
    private var videoOutput: AVCaptureMovieFileOutput!
    private var photoOutput: AVCapturePhotoOutput!
    
    @Published var isRecording = false
    @Published var capturedPhoto: UIImage? = nil
    @Published var capturedVideoURL: URL? = nil
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init() {
        super.init()
        configureSession()
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        if previewLayer == nil {
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspect
        }
        return previewLayer!
    }
    
    private func configureSession() {
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        
        do {
            if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if captureSession.canAddInput(videoInput) {
                    captureSession.addInput(videoInput)
                }
                
                try videoDevice.lockForConfiguration()
                if let format = videoDevice.formats.first(where: {
                    let description = $0.formatDescription
                    let dimensions = CMVideoFormatDescriptionGetDimensions(description)
                    return dimensions.width == 1280 && dimensions.height == 720 && $0.videoSupportedFrameRateRanges.contains(where: { $0.maxFrameRate >= 60 })
                }) {
                    videoDevice.activeFormat = format
                    videoDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 60)
                    videoDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 60)
                    print("Configured 1280x720 @ 60 FPS")
                } else {
                    print("1280x720 @ 60 FPS format not supported")
                }
                videoDevice.unlockForConfiguration()
            }

            if let audioDevice = AVCaptureDevice.default(for: .audio) {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if captureSession.canAddInput(audioInput) {
                    captureSession.addInput(audioInput)
                }
            }
        } catch {
            print("Error configuring input devices: \(error.localizedDescription)")
            return
        }
        
        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        videoOutput = AVCaptureMovieFileOutput()
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        if captureSession.canSetSessionPreset(.hd1280x720) {
            captureSession.sessionPreset = .hd1280x720
        } else {
            print("720p resolution not supported.")
        }
        
        captureSession.commitConfiguration()
    }
    
    func startSession() {
        guard captureSession != nil else {
            print("Capture session is not configured.")
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                print("Capture session started.")
            }
        }
    }

    func stopSession() {
        guard captureSession != nil else {
            print("Capture session is not configured.")
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                print("Capture session stopped.")
            }
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        videoOutput.startRecording(to: outputURL, recordingDelegate: self)
    }
    
    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        videoOutput.stopRecording()
    }
    
    func capturePhoto() {
        let photoSettings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    func savePhoto(_ image: UIImage) {
        // Save photo logic
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let photoURL = documentsDirectory.appendingPathComponent("\(UUID().uuidString).jpg")
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            try? imageData.write(to: photoURL)
            print("Photo saved to: \(photoURL)")
        }
    }
    
    func saveVideo(_ url: URL) {
        // Save video logic
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.moveItem(at: url, to: destinationURL)
        print("Video saved to: \(destinationURL)")
    }
}

extension PhotosAndVideoManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }
        
        DispatchQueue.main.async {
            self.capturedPhoto = image
        }
    }
}

extension PhotosAndVideoManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async {
            self.capturedVideoURL = outputFileURL
        }
    }
}
