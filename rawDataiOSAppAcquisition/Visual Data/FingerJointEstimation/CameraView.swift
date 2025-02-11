//
//  ContentView.swift
//  FingerJointAngleEstimationTest
//
//  Created by Irnu Suryohadi Kusumo on 03.06.24.
//

import SwiftUI
import Vision

struct HandSkeletonShape: Shape {
    var jointPoints: [VNHumanHandPoseObservation.JointName: CGPoint]
    
    private let connections: [(VNHumanHandPoseObservation.JointName, VNHumanHandPoseObservation.JointName)] = [
        // Thumb
        (.wrist, .thumbCMC), (.thumbCMC, .thumbMP), (.thumbMP, .thumbIP), (.thumbIP, .thumbTip),
        // Index finger
        (.wrist, .indexMCP), (.indexMCP, .indexPIP), (.indexPIP, .indexDIP), (.indexDIP, .indexTip),
        // Middle finger
        (.wrist, .middleMCP), (.middleMCP, .middlePIP), (.middlePIP, .middleDIP), (.middleDIP, .middleTip),
        // Ring finger
        (.wrist, .ringMCP), (.ringMCP, .ringPIP), (.ringPIP, .ringDIP), (.ringDIP, .ringTip),
        // Little finger
        (.wrist, .littleMCP), (.littleMCP, .littlePIP), (.littlePIP, .littleDIP), (.littleDIP, .littleTip)
    ]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for connection in connections {
            if let point1 = jointPoints[connection.0], let point2 = jointPoints[connection.1] {
                path.move(to: CGPoint(x: point1.x * rect.width, y: point1.y * rect.height))
                path.addLine(to: CGPoint(x: point2.x * rect.width, y: point2.y * rect.height))
            }
        }
        return path
    }
}

struct CameraView: View {
    @StateObject private var cameraViewModel = CameraViewModel()
    @State private var showingInfo = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let currentFrame = cameraViewModel.currentFrame {
                    Image(decorative: currentFrame, scale: 1.0)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    Color.black
                }
                
                HandSkeletonShape(jointPoints: cameraViewModel.jointPoints)
                    .stroke(Color.white, lineWidth: 3)
                
                ForEach(cameraViewModel.jointPoints.keys.sorted(by: { $0.rawValue.rawValue < $1.rawValue.rawValue }), id: \.self) { jointName in
                    if let point = cameraViewModel.jointPoints[jointName] {
                        ZStack {
                            Circle()
                                .fill(Color.cyan)
                                .frame(width: 12, height: 12)
                        }
                        .position(x: point.x * geometry.size.width, y: point.y * geometry.size.height)
                    }
                }
                /*
                VStack {
                    if cameraViewModel.countdown > 0 {
                        Text("\(cameraViewModel.countdown)")
                            .font(.system(size: 350))
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if cameraViewModel.isRecording {
                            cameraViewModel.stopRecording()
                        } else {
                            cameraViewModel.startRecording()
                        }
                    }) {
                        Text(cameraViewModel.isRecording ? "Stop" : "Start")
                            .padding()
                            .background(cameraViewModel.isRecording ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }
                */
            }
            .onAppear {
                cameraViewModel.setupCamera()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingInfo.toggle() }) {
                    Image(systemName: "info.circle")
                }
                .sheet(isPresented: $showingInfo) {
                    VStack {
                        Text("Vision Finger Estimation Demo")
                            .font(.largeTitle)
                            .multilineTextAlignment(.center)
                            .padding()
                        Text("Using Apple's Vision framework, this view demonstrates figner joints estimation, showing joints and connections in real-time using computer vision technology.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                        AnimatedSwipeDownCloseView()
                    }
                    .padding()
                }
            }
        }
    }
}
