//
//  CameraManager.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 16.01.25.
//

import AVFoundation
import SwiftUI

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var isSessionRunning = false

    override init() {
        super.init()
        configureSession()
    }

    private func configureSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            // Add video input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.session.canAddInput(videoDeviceInput) else {
                print("Unable to add video input.")
                return
            }
            self.session.addInput(videoDeviceInput)

            // Add audio input
            guard let audioDevice = AVCaptureDevice.default(for: .audio),
                  let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice),
                  self.session.canAddInput(audioDeviceInput) else {
                print("Unable to add audio input.")
                return
            }
            self.session.addInput(audioDeviceInput)

            // Add photo output
            guard self.session.canAddOutput(self.photoOutput) else {
                print("Unable to add photo output.")
                return
            }
            self.session.addOutput(self.photoOutput)

            // Add movie output
            guard self.session.canAddOutput(self.movieOutput) else {
                print("Unable to add movie output.")
                return
            }
            self.session.addOutput(self.movieOutput)

            self.session.commitConfiguration()
            self.startSession()
        }
    }

    func startSession() {
        sessionQueue.async {
            if !self.isSessionRunning {
                self.session.startRunning()
                self.isSessionRunning = true
            }
        }
    }

    func stopSession() {
        sessionQueue.async {
            if self.isSessionRunning {
                self.session.stopRunning()
                self.isSessionRunning = false
            }
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func startRecording() {
        let outputFileName = UUID().uuidString
        let outputFilePath = NSTemporaryDirectory().appending("\(outputFileName).mov")
        let fileURL = URL(fileURLWithPath: outputFilePath)
        movieOutput.startRecording(to: fileURL, recordingDelegate: self)
    }

    func stopRecording() {
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else {
            print("Error capturing photo: \(String(describing: error))")
            return
        }
        saveMediaToAppDirectory(data: imageData, mediaType: .photo)
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        guard error == nil else {
            print("Error recording movie: \(String(describing: error))")
            return
        }
        saveMediaToAppDirectory(fileURL: outputFileURL, mediaType: .video)
    }
}

