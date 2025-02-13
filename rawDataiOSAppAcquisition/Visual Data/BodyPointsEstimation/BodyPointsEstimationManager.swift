//
//  BodyPointsEstimationManager.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 11.02.25.
//

import AVFoundation
import Vision
import SwiftUI
import Combine
import Foundation

class BodyPointsEstimationManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var currentFrame: CGImage?
    @Published var jointPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var bodyPoseRequest = VNDetectHumanBodyPoseRequest()
    
    @Published var isRecording = false
    @Published var countdown = 0
    private var countdownTimer: AnyCancellable?
    private var recordedJointPoints: [[VNHumanBodyPoseObservation.JointName: CGPoint]] = []
    
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
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
        let context = CIContext()
        
        let transform = CGAffineTransform(rotationAngle: -.pi / 2)
            .translatedBy(x: -ciImage.extent.height, y: 0)
            .scaledBy(x: 1, y: -1)
        
        let orientedImage = ciImage.transformed(by: transform)
        
        guard let cgImage = context.createCGImage(orientedImage, from: orientedImage.extent) else { return }
        
        DispatchQueue.main.async {
            self.currentFrame = cgImage
            self.estimateBodyPose(from: cgImage)
            
            if self.isRecording {
                self.recordedJointPoints.append(self.jointPoints)
            }
        }
    }
    
    private func estimateBodyPose(from cgImage: CGImage) {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([bodyPoseRequest])
            if let observation = bodyPoseRequest.results?.first {
                processObservation(observation)
            }
        } catch {
            print("Failed to perform body pose request: \(error.localizedDescription)")
        }
    }
    
    private func processObservation(_ observation: VNHumanBodyPoseObservation) {
        do {
            let recognizedPoints = try observation.recognizedPoints(.all)
            var jointPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
            
            for (jointName, point) in recognizedPoints where point.confidence > 0.3 {
                jointPoints[jointName] = CGPoint(x: point.location.x, y: 1 - point.location.y)
            }
            
            DispatchQueue.main.async {
                self.jointPoints = jointPoints
            }
        } catch {
            print("Error recognizing body points: \(error.localizedDescription)")
        }
    }
    
    enum JointAngle: String, CaseIterable {
        case rightShoulderFlexionExtension = "Left Shoulder Flexion/Extension"
        case rightShoulderAbductionAdduction = "Left Shoulder Abduction/Adduction"
        case leftShoulderFlexionExtension = "Right Shoulder Flexion/Extension"
        case leftShoulderAbductionAdduction = "Right Shoulder Abduction/Adduction"
        case rightElbowFlexionExtension = "Left Elbow Flexion/Extension"
        case leftElbowFlexionExtension = "Right Elbow Flexion/Extension"
        case rightHipFlexionExtension = "Left Hip Flexion/Extension"
        case rightHipAbductionAdduction = "Left Hip Abduction/Adduction"
        case leftHipFlexionExtension = "Right Hip Flexion/Extension"
        case leftHipAbductionAdduction = "Right Hip Abduction/Adduction"
        case rightKneeFlexionExtension = "Left Knee Flexion/Extension"
        case leftKneeFlexionExtension = "Right Knee Flexion/Extension"
    }

    func calculateAngle(for jointAngle: JointAngle) -> Double? {
        guard let neck = jointPoints[.neck],
              let hip = jointPoints[.root] else { return nil }

        let NeckRootPlaneVector = CGPoint(x: hip.x - neck.x, y: hip.y - neck.y)

        switch jointAngle {
        case .rightShoulderFlexionExtension, .leftShoulderFlexionExtension,
             .rightElbowFlexionExtension, .leftElbowFlexionExtension,
             .rightHipFlexionExtension, .leftHipFlexionExtension,
             .rightKneeFlexionExtension, .leftKneeFlexionExtension:
            return calculateAngleBetween(joint1: jointStartPoint(for: jointAngle), joint2: jointEndPoint(for: jointAngle), referenceVector: NeckRootPlaneVector)

        case .rightShoulderAbductionAdduction, .leftShoulderAbductionAdduction,
             .rightHipAbductionAdduction, .leftHipAbductionAdduction:
            return calculateAngleBetween(joint1: jointStartPoint(for: jointAngle), joint2: jointEndPoint(for: jointAngle), referenceVector: NeckRootPlaneVector)
        }
    }
    
    private func jointStartPoint(for jointAngle: JointAngle) -> VNHumanBodyPoseObservation.JointName {
        switch jointAngle {
        case .rightShoulderFlexionExtension, .rightShoulderAbductionAdduction: return .rightShoulder
        case .leftShoulderFlexionExtension, .leftShoulderAbductionAdduction: return .leftShoulder
        case .rightElbowFlexionExtension: return .rightElbow
        case .leftElbowFlexionExtension: return .leftElbow
        case .rightHipFlexionExtension, .rightHipAbductionAdduction: return .rightHip
        case .leftHipFlexionExtension, .leftHipAbductionAdduction: return .leftHip
        case .rightKneeFlexionExtension: return .rightKnee
        case .leftKneeFlexionExtension: return .leftKnee
        }
    }

    private func jointEndPoint(for jointAngle: JointAngle) -> VNHumanBodyPoseObservation.JointName {
        switch jointAngle {
        case .rightShoulderFlexionExtension, .rightShoulderAbductionAdduction: return .rightElbow
        case .leftShoulderFlexionExtension, .leftShoulderAbductionAdduction: return .leftElbow
        case .rightElbowFlexionExtension: return .rightWrist
        case .leftElbowFlexionExtension: return .leftWrist
        case .rightHipFlexionExtension, .rightHipAbductionAdduction: return .rightKnee
        case .leftHipFlexionExtension, .leftHipAbductionAdduction: return .leftKnee
        case .rightKneeFlexionExtension: return .rightAnkle
        case .leftKneeFlexionExtension: return .leftAnkle
        }
    }

    private func calculateAngleBetween(joint1: VNHumanBodyPoseObservation.JointName, joint2: VNHumanBodyPoseObservation.JointName, referenceVector: CGPoint) -> Double? {
        guard let point1 = jointPoints[joint1], let point2 = jointPoints[joint2] else { return nil }

        let limbVector = CGPoint(x: point2.x - point1.x, y: point2.y - point1.y)

        let dotProduct = (limbVector.x * referenceVector.x) + (limbVector.y * referenceVector.y)
        let magnitudeLimb = sqrt(pow(limbVector.x, 2) + pow(limbVector.y, 2))
        let magnitudeReference = sqrt(pow(referenceVector.x, 2) + pow(referenceVector.y, 2))

        guard magnitudeLimb != 0 && magnitudeReference != 0 else { return nil }

        let angle = acos(max(min(dotProduct / (magnitudeLimb * magnitudeReference), 1.0), -1.0))

        return angle * (180.0 / .pi)
    }
    
    func startRecording() {
        isRecording = false
        countdown = 3
        countdownTimer?.cancel()
        
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
        saveRecordedData()
    }
    
    func saveRecordedData() {
        // Ensure there are recorded joint points to process
        guard !recordedJointPoints.isEmpty else {
            print("No recorded joint points to save.")
            return
        }

        // Define the CSV header
        var csvString = "Frame"
        for angle in JointAngle.allCases {
            csvString.append(",\(angle.rawValue)")
        }
        csvString.append("\n")

        // Iterate through recorded joint points and calculate angles
        for (index, jointPoints) in recordedJointPoints.enumerated() {
            self.jointPoints = jointPoints // Set the current joint points
            var row = "\(index + 1)" // Frame number
            for angle in JointAngle.allCases {
                if let calculatedAngle = calculateAngle(for: angle) {
                    row.append(",\(calculatedAngle)")
                } else {
                    row.append(",N/A") // If angle can't be calculated
                }
            }
            csvString.append("\(row)\n")
        }

        // Get the path to the documents directory
        let fileManager = FileManager.default
        do {
            let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileURL = documentsURL.appendingPathComponent("Body_Joints_Angles.csv")

            // Write the CSV string to the file
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("CSV file saved successfully at \(fileURL.path)")
        } catch {
            print("Error saving CSV file: \(error.localizedDescription)")
        }
    }
}
