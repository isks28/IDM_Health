//
//  fingerDataManager.swift
//  FingerJointAngleEstimationTest
//
//  Created by Irnu Suryohadi Kusumo on 07.06.24.
//

import AVFoundation
import Vision
import SwiftUI
import Combine
import Foundation

class CameraViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var currentFrame: CGImage?
    @Published var jointAngles: [VNHumanHandPoseObservation.JointName: CGFloat] = [:]
    @Published var jointPoints: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
    @Published var isRecording = false
    @Published var countdown = 0
    
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    
    private var cancellables = Set<AnyCancellable>()
    private var timer: AnyCancellable?
    private var countdownTimer: AnyCancellable?
    private var recordedAngles: [[String: CGFloat]] = []
    
    override init() {
        super.init()
        setupCamera()
    }
    
    public func setupCamera() {
        session.sessionPreset = .high
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
    
    func startRecording() {
            isRecording = false
            countdown = 3
            countdownTimer?.cancel()
            
            // 3-second countdown before starting to record
            countdownTimer = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    if self.countdown > 1 {
                        self.countdown -= 1
                    } else {
                        self.countdown = 0
                        self.isRecording = true
                        self.countdownTimer?.cancel()
                    }
                }
    }
    
    func stopRecording() {
        isRecording = false
        saveToCSV()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
        let context = CIContext()
        
        // Apply the correct transformation
        let transform = CGAffineTransform(rotationAngle: -.pi / 2)
            .translatedBy(x: -ciImage.extent.height, y: 0)
            .scaledBy(x: 1, y: -1)
        
        let orientedImage = ciImage.transformed(by: transform)
        
        guard let cgImage = context.createCGImage(orientedImage, from: orientedImage.extent) else { return }
        
        DispatchQueue.main.async {
            self.currentFrame = cgImage
            self.estimateHandPose(from: cgImage)
        }
    }
    
    private func estimateHandPose(from cgImage: CGImage) {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([handPoseRequest])
            if let observation = handPoseRequest.results?.first {
                processObservation(observation)
            }
        } catch {
            print("Failed to perform hand pose request: \(error.localizedDescription)")
        }
    }
    
    private func processObservation(_ observation: VNHumanHandPoseObservation) {
        do {
            let jointNames: [VNHumanHandPoseObservation.JointName] = [
                .wrist,
                .thumbCMC, .thumbMP, .thumbIP, .thumbTip,
                .indexMCP, .indexPIP, .indexDIP, .indexTip,
                .middleMCP, .middlePIP, .middleDIP, .middleTip,
                .ringMCP, .ringPIP, .ringDIP, .ringTip,
                .littleMCP, .littlePIP, .littleDIP, .littleTip
            ]
            
            var jointPoints: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
            for jointName in jointNames {
                let point = try observation.recognizedPoint(jointName)
                jointPoints[jointName] = CGPoint(x: point.location.x, y: 1 - point.location.y)
            }
            
            DispatchQueue.main.async {
                self.jointPoints = jointPoints
                self.calculateAllJointAngles(jointPoints: jointPoints)
            }
        } catch {
            print("Error recognizing points: \(error.localizedDescription)")
        }
    }
    
    private func calculateAllJointAngles(jointPoints: [VNHumanHandPoseObservation.JointName: CGPoint]) {
        var angles: [VNHumanHandPoseObservation.JointName: CGFloat] = [:]
        
        // Calculate angles for each finger
        // Thumb
        if let thumbTip = jointPoints[.thumbTip],
           let thumbIP = jointPoints[.thumbIP],
           let thumbMP = jointPoints[.thumbMP],
           let thumbCMC = jointPoints[.thumbCMC] {
            angles[.thumbIP] = angleBetweenPoints(thumbTip, thumbIP, thumbMP)
            angles[.thumbMP] = angleBetweenPoints(thumbIP, thumbMP, thumbCMC)
        }
        
        // Index
        if let indexTip = jointPoints[.indexTip],
           let indexDIP = jointPoints[.indexDIP],
           let indexPIP = jointPoints[.indexPIP],
           let indexMCP = jointPoints[.indexMCP] {
            angles[.indexDIP] = angleBetweenPoints(indexTip, indexDIP, indexPIP)
            angles[.indexPIP] = angleBetweenPoints(indexDIP, indexPIP, indexMCP)
        }
        
        // Middle
        if let middleTip = jointPoints[.middleTip],
           let middleDIP = jointPoints[.middleDIP],
           let middlePIP = jointPoints[.middlePIP],
           let middleMCP = jointPoints[.middleMCP] {
            angles[.middleDIP] = angleBetweenPoints(middleTip, middleDIP, middlePIP)
            angles[.middlePIP] = angleBetweenPoints(middleDIP, middlePIP, middleMCP)
        }
        
        // Ring
        if let ringTip = jointPoints[.ringTip],
           let ringDIP = jointPoints[.ringDIP],
           let ringPIP = jointPoints[.ringPIP],
           let ringMCP = jointPoints[.ringMCP] {
            angles[.ringDIP] = angleBetweenPoints(ringTip, ringDIP, ringPIP)
            angles[.ringPIP] = angleBetweenPoints(ringDIP, ringPIP, ringMCP)
        }
        
        // Little
        if let littleTip = jointPoints[.littleTip],
           let littleDIP = jointPoints[.littleDIP],
           let littlePIP = jointPoints[.littlePIP],
           let littleMCP = jointPoints[.littleMCP] {
            angles[.littleDIP] = angleBetweenPoints(littleTip, littleDIP, littlePIP)
            angles[.littlePIP] = angleBetweenPoints(littleDIP, littlePIP, littleMCP)
        }
        
        self.jointAngles = angles
        
        if isRecording {
            recordAngles(angles: angles)
        }
    }
    
    private func recordAngles(angles: [VNHumanHandPoseObservation.JointName: CGFloat]) {
        var recordedAnglesForCurrentFrame: [String: CGFloat] = [:]
        for (jointName, angle) in angles {
            recordedAnglesForCurrentFrame[jointName.rawValue.rawValue] = angle
        }
        recordedAngles.append(recordedAnglesForCurrentFrame)
    }
    
    private func saveToCSV() {
            let fileName = "recorded_angles.csv"
            guard let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) else { return }
            
            let jointNames: [VNHumanHandPoseObservation.JointName] = [
                .thumbIP, .thumbMP, .indexDIP, .indexPIP, .middleDIP, .middlePIP, .ringDIP, .ringPIP, .littleDIP, .littlePIP
            ]
            
        var csvText = jointNames.map { $0.rawValue.rawValue }.joined(separator: ",") + "\n"
            
            for frame in recordedAngles {
                let line = jointNames.map { jointName in
                    frame[jointName.rawValue.rawValue] != nil ? "\(frame[jointName.rawValue.rawValue]!)" : ""
                }.joined(separator: ",")
                csvText.append(line + "\n")
            }
            
            do {
                try csvText.write(to: path, atomically: true, encoding: .utf8)
            } catch {
                print("Failed to write CSV file: \(error.localizedDescription)")
            }
            
            recordedAngles.removeAll()
        }
    
    private func angleBetweenPoints(_ pointA: CGPoint, _ pointB: CGPoint, _ pointC: CGPoint) -> CGFloat {
        let vector1 = CGVector(dx: pointA.x - pointB.x, dy: pointA.y - pointB.y)
        let vector2 = CGVector(dx: pointC.x - pointB.x, dy: pointC.y - pointB.y)
        
        let dotProduct = vector1.dx * vector2.dx + vector1.dy * vector2.dy
        let magnitude1 = sqrt(vector1.dx * vector1.dx + vector1.dy * vector1.dy)
        let magnitude2 = sqrt(vector2.dx * vector2.dx + vector2.dy * vector2.dy)
        
        let angle = acos(dotProduct / (magnitude1 * magnitude2))
        return angle * (180 / .pi) // Convert to degrees
    }
}
