//
//  gyroscopeDataView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI
import LocalAuthentication
import UserNotifications

struct gyroscopeDataView: View {
    @StateObject private var motionManager = GyroscopeManager()
    @State private var isRecording = false
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var isRecordingRealTime = false
    @State private var isRecordingInterval = false
    @State private var samplingRate: Double = 60.0
    
    @State private var canControlSamplingRate = false
    @State private var showingAuthenticationError = false
    
    @State private var showingInfo = false
    @State private var refreshGraph = UUID()
    
    var body: some View {
        VStack {
            Spacer()
            
            if motionManager.gyroscopeData.last != nil {
                
            } else {
                Text("No data")
                    .padding()
                    .font(.title3)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack {
                if motionManager.gyroscopeData.last != nil {
                    Text("X-Axis")
                        .font(.title3)
                        .foregroundStyle(Color.gray)
                }
                GyroscopeGraphView(dataPoints: motionManager.gyroscopeDataPointsX, lineColor: .red.opacity(0.5))
                    .frame(height: 100)
                
                if motionManager.gyroscopeData.last != nil {
                    Text("Y-Axis")
                        .font(.title3)
                        .foregroundStyle(Color.gray)
                }
                GyroscopeGraphView(dataPoints: motionManager.gyroscopeDataPointsY, lineColor: .green.opacity(0.5))
                    .frame(height: 100)
                
                if motionManager.gyroscopeData.last != nil {
                    Text("Z-Axis")
                        .font(.title3)
                        .foregroundStyle(Color.gray)
                }
                GyroscopeGraphView(dataPoints: motionManager.gyroscopeDataPointsZ, lineColor: .blue.opacity(0.5))
                    .frame(height: 100)
            }
            
            Spacer()
            Spacer()
            
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
            
            HStack(alignment: .bottom) {
                Toggle("Real-Time", isOn: $isRecordingRealTime)
                    .onChange(of: isRecordingRealTime) { _, newValue in
                        isRecording = false
                        motionManager.stopGyroscopeDataCollection()
                        motionManager.savedFilePath = nil
                        motionManager.gyroscopeData = []
                        motionManager.gyroscopeDataPointsX = []
                        motionManager.gyroscopeDataPointsY = []
                        motionManager.gyroscopeDataPointsZ = []
                        
                        if newValue {
                            isRecordingInterval = false
                        }
                    }
                
                Toggle("Time-Interval", isOn: $isRecordingInterval)
                    .onChange(of: isRecordingInterval) { _, newValue in
                        isRecording = false
                        motionManager.stopGyroscopeDataCollection()
                        motionManager.savedFilePath = nil
                        motionManager.gyroscopeData = []
                        motionManager.gyroscopeDataPointsX = []
                        motionManager.gyroscopeDataPointsY = []
                        motionManager.gyroscopeDataPointsZ = []
                        
                        if newValue {
                            isRecordingRealTime = false
                        }
                    }
            }
            .padding(.horizontal)
            
            VStack {
                if isRecordingInterval && !isRecording {
                    DatePicker("Start Date and Time", selection: $startDate)
                        .datePickerStyle(CompactDatePickerStyle())
                    
                    DatePicker("End Date and Time", selection: $endDate)
                        .datePickerStyle(CompactDatePickerStyle())
                }
                HStack(alignment: .bottom) {
                    if isRecordingInterval {
                        Toggle(isOn: $isRecording) {
                            Text(isRecording ? "Data will be fetched according to set time interval" : "Start timed recording")
                                .padding()
                                .background(isRecording ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                                .multilineTextAlignment(.center)
                        }
                        .onChange(of: isRecording) { _, newValue in
                            motionManager.savedFilePath = nil

                            if newValue {
                                let serverURL = ServerConfig.serverURL

                                motionManager.scheduleDataCollection(startDate: startDate, endDate: endDate, serverURL: serverURL, baseFolder: "GyroscopeData") {
                                    DispatchQueue.main.async {
                                        isRecording = false
                                        motionManager.removeDataCollectionNotification()
                                    }
                                }
                                motionManager.showDataCollectionNotification()
                            } else {
                                motionManager.stopGyroscopeDataCollection()
                                motionManager.removeDataCollectionNotification()
                            }
                        }

                        if motionManager.savedFilePath != nil {
                            Text("File saved")
                                .font(.footnote)
                                .foregroundStyle(Color.primary)
                        }
                    }
                }
                
                HStack(alignment: .bottom) {
                    if isRecordingRealTime {
                        Button(action: {
                            motionManager.savedFilePath = nil

                            if isRecording {
                                motionManager.stopGyroscopeDataCollection()
                                motionManager.removeDataCollectionNotification()
                                let serverURL = ServerConfig.serverURL
                                motionManager.saveDataToCSV(serverURL: serverURL, baseFolder: "GyroscopeData", recordingMode: "RealTime")
                            } else {
                                let serverURL = ServerConfig.serverURL
                                
                                motionManager.startGyroscopeDataCollection(realTime: true, serverURL: serverURL)
                                motionManager.showDataCollectionNotification()
                            }
                            isRecording.toggle()
                        }) {
                            Text(isRecording ? "Stop and Save" : "Start")
                                .padding()
                                .background(isRecording ? Color.secondary : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }
                        
                        if motionManager.savedFilePath != nil {
                            Text("File saved")
                                .font(.footnote)
                                .foregroundStyle(Color.primary)
                                .padding()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Gyroscope")
        .onDisappear {
                    if isRecording || isRecordingRealTime || isRecordingInterval {
                        motionManager.stopGyroscopeDataCollection()
                        isRecording = false
                        isRecordingRealTime = false
                        isRecordingInterval = false
                        motionManager.resetData()
                    }
                }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingInfo.toggle()
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
                .sheet(isPresented: $showingInfo) {
                    VStack {
                        Text("Gyroscope Information")
                            .font(.title)
                            .multilineTextAlignment(.leading)
                            .padding(.top)
                        ScrollView {
                            Text("GYROSCOPE measures the UNFILTERED rate of rotation around the device's three axes (x, y, z). It tracks angular velocity, helping detect rotational movements")
                                .font(.callout)
                                .multilineTextAlignment(.leading)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 5)
                                .foregroundStyle(Color.primary)
                            Text("For more information go to: https://developer.apple.com/documentation/coremotion/getting_raw_gyroscope_events")
                                .font(.callout)
                                .multilineTextAlignment(.leading)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 5)
                                .foregroundStyle(Color.primary)
                            Text("SAMPLING RATE CONTROL can only be accessed by authorized personal")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 5)
                                .foregroundStyle(Color.primary)
                            Text("REAL-TIME record the data immediately and stop on-demand")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 5)
                                .foregroundStyle(Color.primary)
                            Text("TIME-INTERVAL record the data automatically. Set the start and end date, turn on the Start timed recording, and the recording will stop automatically after the end time is up")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 5)
                                .foregroundStyle(Color.primary)
                            Text("Data collection will stop if the gyroscope view is closed, but it will continue running even if the phone is locked or other apps are in use.")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 5)
                                .foregroundStyle(Color.pink)
                                .background(Color.white)
                                .cornerRadius(25)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.pink, lineWidth: 2)
                                )
                        }
                        .scrollIndicators(.hidden)
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                        AnimatedSwipeDownCloseView()
                    }
                    .padding()
                }
            }
        }
    }
    
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

struct GyroscopeGraphView: View {
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
    gyroscopeDataView()
}
