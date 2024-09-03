//
//  cameraBasedManager.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import UIKit
import AVFoundation

class CameraBasedManager: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    private let captureSession = AVCaptureSession()
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var videoOutput: AVCaptureMovieFileOutput?
    private var photoOutput: AVCapturePhotoOutput?

    var onPhotoCaptured: ((UIImage) -> Void)?
    var onVideoRecorded: ((URL) -> Void)?
    var aspectRatio: CGFloat = 4/3

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCaptureSession()
        configurePreviewLayer()
    }
    
    private func configureCaptureSession() {
        captureSession.sessionPreset = .photo
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput) else { return }
        
        captureSession.addInput(videoInput)
        
        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput!) {
            captureSession.addOutput(photoOutput!)
        }
        
        videoOutput = AVCaptureMovieFileOutput()
        if captureSession.canAddOutput(videoOutput!) {
            captureSession.addOutput(videoOutput!)
        }
        
        captureSession.startRunning()
    }
    
    private func configurePreviewLayer() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspect
        videoPreviewLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer)
    }
    
    func takePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    func startRecording() {
        guard let videoOutput = videoOutput else { return }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        videoOutput.startRecording(to: tempURL, recordingDelegate: self)
    }
    
    func stopRecording() {
        videoOutput?.stopRecording()
    }
    
    private func savePhotoToDocuments(_ image: UIImage) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            return
        }

        let filename = UUID().uuidString + ".jpg"
        let fileURL = documentsDirectory.appendingPathComponent(filename)

        guard let data = image.jpegData(compressionQuality: 1.0) else { return }

        do {
            try data.write(to: fileURL)
            print("Saved photo to: \(fileURL.path)")
            onPhotoCaptured?(image)
        } catch {
            print("Failed to save photo: \(error)")
        }
    }

    private func saveVideoToDocuments(_ videoURL: URL) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            return
        }

        let filename = UUID().uuidString + ".mp4"
        let fileURL = documentsDirectory.appendingPathComponent(filename)

        do {
            try FileManager.default.moveItem(at: videoURL, to: fileURL)
            print("Saved video to: \(fileURL.path)")
            onVideoRecorded?(fileURL)
        } catch {
            print("Failed to save video: \(error)")
        }
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video: \(error)")
            return
        }
        
        saveVideoToDocuments(outputFileURL)
    }
}

extension CameraBasedManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else {
            print("Error processing photo data")
            return
        }
        
        savePhotoToDocuments(image)
    }
}
