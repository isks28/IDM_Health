//
//  PhotosAndVideoManager.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 16.01.25.
//

import AVFoundation
import SwiftUI

class PhotosAndVideoManager: NSObject, ObservableObject {
    private var captureSession: AVCaptureSession!
    private var videoOutput: AVCaptureMovieFileOutput!
    private var photoOutput: AVCapturePhotoOutput!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    @Published var isRecording = false
    @Published var capturedPhoto: UIImage? = nil
    
    override init() {
        super.init()
        configureSession()
    }
    
    private func configureSession() {
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            fatalError("Unable to configure video input.")
        }
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        // Add audio input
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice) {
            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            }
        }
        
        // Add photo output
        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            photoOutput.isHighResolutionCaptureEnabled = true
            captureSession.addOutput(photoOutput)
        }
        
        // Add video output
        videoOutput = AVCaptureMovieFileOutput()
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.commitConfiguration()
    }
    
    func startSession() {
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
    
    func stopSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
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
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        if previewLayer == nil {
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
        }
        
        // Adjust frame to 4:3 aspect ratio
        let screenWidth = UIScreen.main.bounds.width
        let previewHeight = screenWidth * 16 / 9
        previewLayer.frame = CGRect(x: 0, y: (UIScreen.main.bounds.height - previewHeight) / 2, width: screenWidth, height: previewHeight)
        
        return previewLayer
    }
    
    private func savePhoto(_ image: UIImage) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let photoURL = documentsDirectory.appendingPathComponent("\(UUID().uuidString).jpg")
        
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            try? imageData.write(to: photoURL)
            print("Photo saved to: \(photoURL)")
        }
    }
    
    private func saveVideo(_ url: URL) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
        
        do {
            try FileManager.default.moveItem(at: url, to: destinationURL)
            print("Video saved to: \(destinationURL)")
        } catch {
            print("Error saving video: \(error.localizedDescription)")
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension PhotosAndVideoManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }
        
        DispatchQueue.main.async {
            self.capturedPhoto = image
            self.savePhoto(image)
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension PhotosAndVideoManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Video recording error: \(error.localizedDescription)")
            return
        }
        
        DispatchQueue.main.async {
            self.saveVideo(outputFileURL)
        }
    }
}
