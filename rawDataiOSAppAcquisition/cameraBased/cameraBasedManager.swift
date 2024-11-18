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
    var useFrontCamera = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCaptureSession()
        configurePreviewLayer()
    }
    
    private func configureCaptureSession() {
        captureSession.sessionPreset = .photo
        updateCameraPosition()

        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput!) {
            captureSession.addOutput(photoOutput!)
        }
        
        videoOutput = AVCaptureMovieFileOutput()
        if captureSession.canAddOutput(videoOutput!) {
            captureSession.addOutput(videoOutput!)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    private func configurePreviewLayer() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspect
        videoPreviewLayer.frame = view.bounds
        view.layer.addSublayer(videoPreviewLayer)
    }
    
    func updateCameraPosition() {
        captureSession.beginConfiguration()
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        
        let position: AVCaptureDevice.Position = useFrontCamera ? .front : .back
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput) else { return }
        
        captureSession.addInput(videoInput)
        captureSession.commitConfiguration()
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

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video: \(error)")
            return
        }
        
        onVideoRecorded?(outputFileURL)
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
        
        onPhotoCaptured?(image)  
    }
}
