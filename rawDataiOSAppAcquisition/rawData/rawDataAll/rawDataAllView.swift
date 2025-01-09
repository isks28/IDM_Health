//
//  RawDataView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 29.10.24.
//

import SwiftUI
import LocalAuthentication
import CoreMotion
import UserNotifications

enum DataTypeRawAll: String, CaseIterable {
case accelerometer = "Accel."
case gyroscope = "Gyro."
case magnetometer = "Magneto."
}

struct rawDataAccGyroMagView: View {
@StateObject private var motionManager = RawDataManager()
@State private var isRecording = false
@State private var startDate = Date()
@State private var endDate = Date().addingTimeInterval(3600)
@State private var isRecordingRealTime = false
@State private var isRecordingInterval = false
@State private var samplingRate: Double = 60.0
@State private var canControlSamplingRate = false
@State private var showingAuthenticationError = false
    @State private var selectedDataType: DataTypeRawAll = .accelerometer

@State private var showingInfo = false
@State private var refreshGraph = UUID()

var body: some View {
    VStack {
        Picker("Select Data", selection: $selectedDataType) {
            ForEach(DataTypeRawAll.allCases, id: \.self) { dataType in
                Text(dataType.rawValue)
                    .tag(dataType)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()

        Spacer()

        switch selectedDataType {
        case .accelerometer:
            if motionManager.AccelerometerData.last != nil {
                VStack {
                    RawDataGraphView(dataPoints: motionManager.accelerometerDataPointsX, lineColor: .red.opacity(0.5), graphTitle: "Acceleration X-Axis")
                        .frame(height: 100)
                    RawDataGraphView(dataPoints: motionManager.accelerometerDataPointsY, lineColor: .green.opacity(0.5), graphTitle: "Acceleration Y-Axis")
                        .frame(height: 100)
                    RawDataGraphView(dataPoints: motionManager.accelerometerDataPointsZ, lineColor: .blue.opacity(0.5), graphTitle: "Acceleration Z-Axis")
                        .frame(height: 100)
                }
            } else {
                showNoDataMessage()
            }

        case .gyroscope:
            if motionManager.gyroscopeData.last != nil {
                VStack {
                    RawDataGraphView(dataPoints: motionManager.gyroscopeDataPointsX, lineColor: .red.opacity(0.5), graphTitle: "Gyroscope X-Axis")
                        .frame(height: 100)
                    RawDataGraphView(dataPoints: motionManager.gyroscopeDataPointsY, lineColor: .green.opacity(0.5), graphTitle: "Gyroscope Y-Axis")
                        .frame(height: 100)
                    RawDataGraphView(dataPoints: motionManager.gyroscopeDataPointsZ, lineColor: .blue.opacity(0.5), graphTitle: "Gyroscope Z-Axis")
                        .frame(height: 100)
                }
            } else {
                showNoDataMessage()
            }
            
        case .magnetometer:
            if motionManager.magnetometerData.last != nil {
                VStack {
                    RawDataGraphView(dataPoints: motionManager.magnetometerDataPointsX, lineColor: .red.opacity(0.5), graphTitle: "Magnetometer X-Axis")
                        .frame(height: 100)
                    RawDataGraphView(dataPoints: motionManager.magnetometerDataPointsY, lineColor: .green.opacity(0.5), graphTitle: "Magnetometer Y-Axis")
                        .frame(height: 100)
                    RawDataGraphView(dataPoints: motionManager.magnetometerDataPointsZ, lineColor: .blue.opacity(0.5), graphTitle: "Magnetometer Z-Axis")
                        .frame(height: 100)
                }
            } else {
                showNoDataMessage()
            }
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
            
            HStack(alignment: .bottom) {
                Toggle("Real-Time", isOn: $isRecordingRealTime)
                    .onChange(of: isRecordingRealTime) { _, newValue in
                        isRecording = false
                        motionManager.stoprawDataCollection()
                        motionManager.savedFilePath = nil // Reset "File saved" text
                        
                        // Reset accelerometer data
                        motionManager.AccelerometerData = []
                        motionManager.gyroscopeData = []
                        motionManager.magnetometerData = []
                        motionManager.accelerometerDataPointsX = []
                        motionManager.accelerometerDataPointsY = []
                        motionManager.accelerometerDataPointsZ = []
                        motionManager.gyroscopeDataPointsX = []
                        motionManager.gyroscopeDataPointsY = []
                        motionManager.gyroscopeDataPointsZ = []
                        motionManager.magnetometerDataPointsX = []
                        motionManager.magnetometerDataPointsY = []
                        motionManager.magnetometerDataPointsZ = []
                        
                        if newValue {
                            isRecordingInterval = false
                        }
                    }
                
                Toggle("Time-Interval", isOn: $isRecordingInterval)
                    .onChange(of: isRecordingInterval) { _, newValue in
                        isRecording = false
                        motionManager.stoprawDataCollection()
                        motionManager.savedFilePath = nil
                        
                        motionManager.AccelerometerData = []
                        motionManager.gyroscopeData = []
                        motionManager.magnetometerData = []
                        motionManager.accelerometerDataPointsX = []
                        motionManager.accelerometerDataPointsY = []
                        motionManager.accelerometerDataPointsZ = []
                        motionManager.gyroscopeDataPointsX = []
                        motionManager.gyroscopeDataPointsY = []
                        motionManager.gyroscopeDataPointsZ = []
                        motionManager.magnetometerDataPointsX = []
                        motionManager.magnetometerDataPointsY = []
                        motionManager.magnetometerDataPointsZ = []
                        
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
                HStack {
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

                                motionManager.scheduleDataCollection(startDate: startDate, endDate: endDate, serverURL: serverURL, baseFolder: "RawData") {
                                    DispatchQueue.main.async {
                                        isRecording = false
                                        motionManager.removeDataCollectionNotification()
                                    }
                                }
                                motionManager.showDataCollectionNotification(startTime: startDate, endTime: endDate)
                            } else {
                                motionManager.stoprawDataCollection()
                                motionManager.removeDataCollectionNotification()
                            }
                        }
                        
                        if motionManager.savedFilePath != nil {
                            Text("File saved")
                                .font(.footnote)
                                .foregroundStyle(Color(.blue))
                                .padding()
                        }
                    }
                }
                
                HStack(alignment: .bottom) {
                    if isRecordingRealTime {
                        Button(action: {
                            motionManager.savedFilePath = nil
                            
                            if isRecording {
                                motionManager.stoprawDataCollection()
                                motionManager.removeDataCollectionNotification()
                                let serverURL = ServerConfig.serverURL
                                motionManager.saveDataToCSV(serverURL: serverURL, baseFolder: "RawData", recordingMode: "RealTime")
                            } else {
                                let serverURL = ServerConfig.serverURL
                                
                                motionManager.startrawDataCollection(realTime: true, serverURL: serverURL)
                                motionManager.showDataCollectionNotification()
                            }
                            isRecording.toggle()
                        }) {
                            Text(isRecording ? "Stop and Save" : "Start")
                                .padding()
                                .background(isRecording ? Color.gray : Color.blue)
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
        .navigationTitle("IMU Data")
        .onDisappear {
                    if isRecording || isRecordingRealTime || isRecordingInterval {
                        motionManager.stoprawDataCollection()
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
                        Text("IMU data Information")
                            .font(.title)
                            .multilineTextAlignment(.leading)
                            .padding(.top)
                        ScrollView {
                        Text("IMU data measures the unfiltered, raw data of accelerometer, gyroscope and magnetometer simultaneously.")
                            .font(.callout)
                            .multilineTextAlignment(.leading)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 5)
                            .foregroundStyle(Color.primary)
                        Text("For more information go to:")
                            .font(.callout)
                            .multilineTextAlignment(.leading)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 5)
                            .foregroundStyle(Color.primary)
                        Link("Apple developer documentation, getting raw accelerometer events", destination: URL(string: "https://developer.apple.com/documentation/coremotion/getting_raw_accelerometer_events")!)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 5)
                            .foregroundStyle(Color.blue)
                        Text("Sampling rate control allows the user to change the sampling frequency.")
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 5)
                            .foregroundStyle(Color.primary)
                        Text("The Real-Time function records the data as soon as it is activated and continues to record until the user manually stops the recording.")
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 5)
                            .foregroundStyle(Color.primary)
                        Text("Time-Interval allows the user to programme a date and time for the start and end of the recording. Set the start and end date, turn on Start timed recording, and the recording will stop automatically after the end time is up.")
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 5)
                            .foregroundStyle(Color.primary)
                        Text("Data collection will stop if the app is closed, but it will continue running even if the phone is locked or other apps are in use.")
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
    
    func showNoDataMessage() -> some View {
            Text("No data")
                .padding(.bottom, 300)
                .font(.title3)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
        }
}

struct RawDataAllGraphView: View {
    var dataPoints: [Double]
    var lineColor: Color
    var graphTitle: String
    
    var body: some View {
        VStack {
            Text(graphTitle)
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .padding(.bottom, 5)
            
            GeometryReader { geometry in
                Path { path in
                    let displayedData = dataPoints.suffix(1000)
                    guard displayedData.count > 1 else { return }
                    
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    let maxValue = displayedData.max() ?? 0
                    let minValue = displayedData.min() ?? 0
                    
                    let adjustedMax = max(maxValue, 0.1)
                    let scaleX = width / CGFloat(displayedData.count - 1)
                    let scaleY = height / CGFloat(adjustedMax - minValue)
                    
                    path.move(to: CGPoint(x: 0, y: height - CGFloat(displayedData.first! - minValue) * scaleY))
                    
                    for (index, dataPoint) in displayedData.enumerated() {
                        let x = CGFloat(index) * scaleX
                        let y = height - CGFloat(dataPoint - minValue) * scaleY
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(lineColor, lineWidth: 2)
            }
        }
    }
}

#Preview {
    rawDataAccGyroMagView()
}
