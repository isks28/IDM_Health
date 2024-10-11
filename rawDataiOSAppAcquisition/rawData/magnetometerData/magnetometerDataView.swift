//
//  magnetometerDataView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI
import LocalAuthentication
import UserNotifications

struct magnetometerDataView: View {
    @StateObject private var motionManager = MagnetometerManager()
    @State private var isRecording = false
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var isRecordingRealTime = false
    @State private var isRecordingInterval = false
    @State private var samplingRate: Double = 60.0 // Default sampling rate
    @State private var canControlSamplingRate = false
    @State private var showingAuthenticationError = false
    
    var body: some View {
        VStack {
            Text("Magnetometer Data Acquisition")
                .font(.title)
                .foregroundStyle(Color.mint)
                .padding(.top, 5)
            Spacer()
            
            if motionManager.magnetometerData.last != nil {
                Text("Magnetometer Data")
                    .font(.title2)
                    .foregroundStyle(Color.pink)
                    .padding()
            } else {
                Text("No Data")
                    .padding()
            }
            
            // Simple Graph View
            VStack {
                if motionManager.magnetometerData.last != nil {
                    Text("X-Axis")
                        .font(.title3)
                        .foregroundStyle(Color.gray)
                }
                MagnetometerGraphView(dataPoints: motionManager.magnetometerDataPointsX, lineColor: .red.opacity(0.5))
                    .frame(height: 90)
                
                if motionManager.magnetometerData.last != nil {
                    Text("Y-Axis")
                        .font(.title3)
                        .foregroundStyle(Color.gray)
                }
                MagnetometerGraphView(dataPoints: motionManager.magnetometerDataPointsY, lineColor: .green.opacity(0.5))
                    .frame(height: 90)
                
                if motionManager.magnetometerData.last != nil {
                    Text("Z-Axis")
                        .font(.title3)
                        .foregroundStyle(Color.gray)
                }
                MagnetometerGraphView(dataPoints: motionManager.magnetometerDataPointsZ, lineColor: .blue.opacity(0.5))
                    .frame(height: 90)
            }
            
            if !isRecording && !isRecordingInterval && !isRecordingRealTime {
                VStack {
                    Toggle(isOn: $canControlSamplingRate) {
                        Text("Enable Sampling Rate Control")
                        Text("Default: 60Hz")
                            .font(.caption2)
                    }
                    .onChange(of: canControlSamplingRate) { _, newValue in
                        if newValue {
                            authenticateUser { success in
                                if !success {
                                    canControlSamplingRate = false
                                    showingAuthenticationError = true
                                } else {
                                    showingAuthenticationError = false
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            
            if canControlSamplingRate && !isRecording && !isRecordingInterval && !isRecordingRealTime {
                VStack {
                    Text("Sampling Rate: \(Int(samplingRate)) Hz")
                    Slider(value: $samplingRate, in: 5...100, step: 5)
                        .padding()
                        .onChange(of: samplingRate) { oldRate, newRate in
                            motionManager.updateSamplingRate(rate: newRate)
                        }
                }
            }
            
            if showingAuthenticationError && !isRecording && !isRecordingInterval && !isRecordingRealTime {
                Text("Authentication Failed. Unable to control sampling rate.")
                    .foregroundColor(.red)
                    .font(.caption2)
            }
            
            HStack {
                Toggle("Real-Time", isOn: $isRecordingRealTime)
                    .onChange(of: isRecordingRealTime) { _, newValue in
                        isRecording = false
                        motionManager.stopMagnetometerDataCollection()
                        motionManager.savedFilePath = nil // Reset "File saved" text
                        
                        if newValue {
                            isRecordingInterval = false
                        }
                    }
                
                Toggle("Time-Interval", isOn: $isRecordingInterval)
                    .onChange(of: isRecordingInterval) { _, newValue in
                        isRecording = false
                        motionManager.stopMagnetometerDataCollection()
                        motionManager.savedFilePath = nil // Reset "File saved" text
                        
                        if newValue {
                            isRecordingRealTime = false
                        }
                    }
            }
            .padding()
            
            VStack {
                if isRecordingInterval && !isRecording {
                    DatePicker("Start Date and Time", selection: $startDate)
                        .datePickerStyle(CompactDatePickerStyle())
                    
                    DatePicker("End Date and Time", selection: $endDate)
                        .datePickerStyle(CompactDatePickerStyle())
                }
                HStack {
                    if isRecordingInterval {
                        Toggle(isOn: $isRecording) {
                            Text(isRecording ? "Data will be fetched according to set time interval" : "Start timed recording")
                                .padding()
                                .background(isRecording ? Color.mint : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                                .multilineTextAlignment(.center)
                        }
                        .onChange(of: isRecording) { _, newValue in
                            motionManager.savedFilePath = nil // Reset "File saved" text
                            if newValue {
                                motionManager.scheduleDataCollection(startDate: startDate, endDate: endDate) {
                                    DispatchQueue.main.async {
                                        isRecording = false
                                        motionManager.removeDataCollectionNotification() // Remove notification
                                    }
                                }
                                motionManager.showDataCollectionNotification() // Show notification on start
                            } else {
                                motionManager.stopMagnetometerDataCollection()
                                motionManager.removeDataCollectionNotification() // Remove notification on stop
                            }
                        }
                        
                        if motionManager.savedFilePath != nil {
                            Text("File saved")
                                .font(.footnote)
                                .foregroundStyle(Color(.blue))
                        }
                    }
                }
                
                HStack {
                    if isRecordingRealTime {
                        Button(action: {
                            motionManager.savedFilePath = nil // Reset "File saved" text when starting a new recording
                            
                            if isRecording {
                                motionManager.stopMagnetometerDataCollection()
                                motionManager.removeDataCollectionNotification() // Remove notification on stop
                            } else {
                                motionManager.startMagnetometerDataCollection(realTime: true)
                                motionManager.showDataCollectionNotification() // Show notification on start
                            }
                            isRecording.toggle()
                        }) {
                            Text(isRecording ? "Stop and Save" : "Start")
                                .padding()
                                .background(isRecording ? Color.gray : Color.mint)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }
                        
                        if motionManager.savedFilePath != nil {
                            Text("File saved")
                                .font(.footnote)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // Function to authenticate the user using Face ID/Touch ID or passcode
    func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Authenticate to enable sampling rate control."
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            }
        } else {
            completion(false)
        }
    }
}

struct MagnetometerGraphView: View {
    var dataPoints: [Double]
    var lineColor: Color

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard dataPoints.count > 1 else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let maxValue = dataPoints.max() ?? 1
                let minValue = dataPoints.min() ?? 0
                let scaleX = width / CGFloat(dataPoints.count - 1)
                let scaleY = height / CGFloat(maxValue - minValue)

                path.move(to: CGPoint(x: 0, y: height - CGFloat(dataPoints[0] - minValue) * scaleY))
                
                for index in 1..<dataPoints.count {
                    let x = CGFloat(index) * scaleX
                    let y = height - CGFloat(dataPoints[index] - minValue) * scaleY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(lineColor, lineWidth: 2)
        }
    }
}

#Preview {
    magnetometerDataView()
}
