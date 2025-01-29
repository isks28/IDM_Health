//
//  PhotosAndVideoManager.swift
//  rawDataiOSAppAcquisition
//

import AVFoundation
import SwiftUI

class PhotosAndVideoManager: NSObject, ObservableObject {
    private var captureSession: AVCaptureSession!
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private var videoOutput: AVCaptureMovieFileOutput!
    private var photoOutput: AVCapturePhotoOutput!
    
    @Published var isRecording = false
    @Published var capturedPhoto: UIImage? = nil
    @Published var capturedVideoURL: URL? = nil
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentCameraOrientation: AVCaptureDevice.Position = .back
    
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
                if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraOrientation) {
                    let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                    
                    for input in captureSession.inputs {
                        captureSession.removeInput(input)
                    }
                    
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
        sessionQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }

    func stopSession() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func switchCamera() {
        let newPosition: AVCaptureDevice.Position = (currentCameraOrientation == .back) ? .front : .back
        
        guard let newVideoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
            print("Unable to access camera at position: \(newPosition)")
            return
        }
        
        do {
            let newVideoInput = try AVCaptureDeviceInput(device: newVideoDevice)
            
            captureSession.beginConfiguration()
            
            if let currentVideoInput = captureSession.inputs.first(where: { ($0 as? AVCaptureDeviceInput)?.device.hasMediaType(.video) == true }) {
                captureSession.removeInput(currentVideoInput)
            }
            
            if captureSession.canAddInput(newVideoInput) {
                captureSession.addInput(newVideoInput)
                currentCameraOrientation = newPosition
            } else {
                print("Failed to add new video input")
            }
            
            captureSession.commitConfiguration()
        } catch {
            print("Error switching cameras: \(error.localizedDescription)")
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
        let cameraPosition = currentCameraOrientation == .front ? "Front Camera" : "Back Camera"
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found.")
            return
        }
        
        let photoDirectory = documentsDirectory
            .appendingPathComponent("Visual Data")
            .appendingPathComponent("Photo")
            .appendingPathComponent(cameraPosition)
        
        do {
            try FileManager.default.createDirectory(at: photoDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create directory: \(error.localizedDescription)")
            return
        }
        
        let photoURL = photoDirectory.appendingPathComponent("\(UUID().uuidString).jpg")
        
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            do {
                try imageData.write(to: photoURL, options: [.atomic, .completeFileProtection])
                print("Photo saved to: \(photoURL.path)")
            } catch {
                print("Failed to save photo: \(error.localizedDescription)")
            }
        }
    }
    
    func saveVideo(_ url: URL) {
        let cameraPosition = currentCameraOrientation == .front ? "Front Camera" : "Back Camera"
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found.")
            return
        }
        
        let videoDirectory = documentsDirectory
            .appendingPathComponent("Visual Data")
            .appendingPathComponent("Video")
            .appendingPathComponent(cameraPosition)
        
        do {
            try FileManager.default.createDirectory(at: videoDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create directory: \(error.localizedDescription)")
            return
        }
        
        let destinationURL = videoDirectory.appendingPathComponent(url.lastPathComponent)
        
        do {
            try FileManager.default.moveItem(at: url, to: destinationURL)
            print("Video saved to: \(destinationURL.path)")
        } catch {
            print("Failed to save video: \(error.localizedDescription)")
        }
    }
    func toggleFlash(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch,
              currentCameraOrientation == .back else { return }

        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Torch could not be used: \(error.localizedDescription)")
        }
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
