//
//  StepCountView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 11.10.24.
//

import SwiftUI
import LocalAuthentication
import CoreMotion
import UserNotifications

struct StepCountView: View {
    @StateObject private var stepManager = StepCountManager()
    @State private var isRecording = false
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var isRecordingRealTime = false
    @State private var isRecordingInterval = false
    @State private var showingAuthenticationError = false
    @State private var canControlStepLength = false
    @State private var timer: Timer?
    
    @State private var showingInfo = false
    @State private var refreshGraph = UUID()
    
    var body: some View {
        VStack {
            
            if stepManager.stepCount == 0 {
                Text("Place the phone in the pocket after clicking start")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.secondary)
                    .padding(.top, 5)
                    .padding(.horizontal)
            }
            Spacer()
            
            VStack {
                Spacer()
                if !isRecording && stepManager.stepCount == 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $canControlStepLength) {
                            VStack(alignment: .leading, spacing: 4) {
                                if !canControlStepLength {
                                    Text("Enable Step Length Control")
                                }
                                
                                HStack {
                                    if canControlStepLength {
                                        Text("Enter new step length:")
                                            .font(.callout)
                                        TextField("0", value: Binding(
                                            get: { stepManager.stepLengthInMeters * 100 },
                                            set: { newValue in
                                                stepManager.stepLengthInMeters = newValue / 100
                                            }
                                        ), formatter: NumberFormatter())
                                            .font(.callout)
                                            .foregroundStyle(Color.blue)
                                            .keyboardType(.decimalPad)
                                            .frame(width: 80)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .multilineTextAlignment(.center)
                                            .toolbar {
                                                ToolbarItem(placement: .keyboard) {
                                                    HStack {
                                                        Spacer()
                                                        Button("Done") {
                                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                                        }
                                                    }
                                                }
                                            }
                                        Text("cm")
                                    } else {
                                        if stepManager.stepLengthInMeters == 0.7 {
                                            Text("Default: 70 cm")
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        } else {
                                            Text(String(format: "Changed: %.2f meters (%.0f cm)", stepManager.stepLengthInMeters, stepManager.stepLengthInMeters * 100))
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                        }
                        .onChange(of: canControlStepLength) { _, newValue in
                            if newValue {
                                authenticateUser { success in
                                    if !success {
                                        canControlStepLength = false
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
                
                if stepManager.stepCount > 0 {
                    Grid {
                        VStack {
                            Text("Number of Steps:")
                                .font(.largeTitle)
                                .foregroundStyle(Color.primary)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 15)
                                .gridCellAnchor(.leading)
                            Text("\(stepManager.stepCount)")
                                .font(.largeTitle)
                                .foregroundColor(.primary)
                                .gridCellAnchor(.trailing)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(25)

                        Spacer()
                        
                        GridRow {
                            Text("Distance GPS:")
                                .font(.title3)
                                .gridCellAnchor(.leading)
                            Text(String(format: "%.2f meters", stepManager.distanceGPS))
                                .font(.title3)
                                .foregroundColor(.blue)
                                .gridCellAnchor(.trailing)
                        }
                        .padding(.vertical, 1.5)
                        
                        GridRow {
                            Text("Distance Pedometer:")
                                .font(.title3)
                                .gridCellAnchor(.leading)
                            Text(String(format: "%.2f meters", stepManager.distancePedometer))
                                .font(.title3)
                                .foregroundColor(.blue)
                                .gridCellAnchor(.trailing)
                        }
                        .padding(.vertical, 1.5)

                        GridRow {
                            Text("Average Active Pace:")
                                .font(.title3)
                                .gridCellAnchor(.leading)
                            if let averageActivePace = stepManager.averageActivePace {
                                Text(String(format: "%.2f meters/second", averageActivePace))
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .gridCellAnchor(.trailing)
                            } else {
                                Text("Not available")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                    .gridCellAnchor(.trailing)
                            }
                        }
                        .padding(.vertical, 1.5)

                        GridRow {
                            Text("Current Pace:")
                                .font(.title3)
                                .gridCellAnchor(.leading)
                            if let currentPace = stepManager.currentPace {
                                Text(String(format: "%.2f meters/second", currentPace))
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .gridCellAnchor(.trailing)
                            } else {
                                Text("Not available")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                    .gridCellAnchor(.trailing)
                            }
                        }
                        .padding(.vertical, 1.5)

                        GridRow {
                            Text("Current Cadence:")
                                .font(.title3)
                                .gridCellAnchor(.leading)
                            if let currentCadence = stepManager.currentCadence {
                                Text(String(format: "%.2f steps/minute", currentCadence))
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .gridCellAnchor(.trailing)
                            } else {
                                Text("Not available")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                    .gridCellAnchor(.trailing)
                            }
                        }
                        .padding(.vertical, 1.5)
                        Spacer()
                    }
                } else {
                    Text("Select the Time-Method:")
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                        .multilineTextAlignment(.center)
                }
            }
            Spacer()
            
            HStack {
                Toggle("Real-Time", isOn: $isRecordingRealTime)
                    .onChange(of: isRecordingRealTime) { _, newValue in
                        isRecording = false
                        stepManager.stopStepCountCollection()
                        stopTimer()
                        stepManager.savedFilePath = nil
                        
                        if newValue {
                            isRecordingInterval = false
                        }
                    }
                
                Toggle("Time-Interval", isOn: $isRecordingInterval)
                    .onChange(of: isRecordingInterval) { _, newValue in
                        isRecording = false
                        stepManager.stopStepCountCollection()
                        stopTimer()
                        stepManager.savedFilePath = nil
                        
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
                            stepManager.savedFilePath = nil
                            if newValue {
                                
                                let serverURL = ServerConfig.serverURL
                                
                                stepManager.scheduleStepCountCollection(startDate: startDate, endDate: endDate, serverURL: serverURL, baseFolder: "ProcessedStepCountsData") {
                                    DispatchQueue.main.async {
                                        isRecording = false
                                        stopTimer()
                                        stepManager.removeDataCollectionNotification()
                                    }
                                }
                                stepManager.showDataCollectionNotification(startTime: startDate, endTime: endDate)
                            } else {
                                stepManager.stopStepCountCollection()
                                stopTimer()
                                stepManager.removeDataCollectionNotification()
                            }
                        }
                        
                        if stepManager.savedFilePath != nil {
                            Text("File saved")
                                .font(.footnote)
                                .foregroundStyle(Color(.blue))
                        }
                    }
                }
                
                HStack {
                    if isRecordingRealTime {
                        Button(action: {
                            stepManager.savedFilePath = nil
                            
                            if isRecording {
                                stepManager.stopStepCountCollection()
                                stopTimer()
                                stepManager.removeDataCollectionNotification()
                                let serverURL = ServerConfig.serverURL
                                stepManager.saveDataToCSV(serverURL: serverURL, baseFolder: "ProcessedStepCountsData", recordingMode: "RealTime")
                            } else {
                                let serverURL = ServerConfig.serverURL
                                
                                stepManager.startStepCountCollection(realTime: true, serverURL: serverURL)
                                startTimer()
                                stepManager.showDataCollectionNotification()
                            }
                            isRecording.toggle()
                        }) {
                            Text(isRecording ? "Stop and Save" : "Start")
                                .padding()
                                .background(isRecording ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }
                        
                        if stepManager.savedFilePath != nil {
                            Text("File saved")
                                .font(.footnote)
                                .foregroundStyle(Color.primary)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Step Counts")
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
                        Text("Step Counts Information")
                            .font(.title)
                            .multilineTextAlignment(.leading)
                            .padding(.top)
                        ScrollView {
                        Text("Step count measured from the device's accelerometer and represents the number of steps walked in a given bout of time. Repetitive motion patterns typical of walking or running are detected and calculates the total step count accordingly. ")
                            .font(.callout)
                            .multilineTextAlignment(.leading)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 5)
                            .foregroundStyle(Color.primary)
                        Text("Distance GPS is the measured distance collected through Apple's Core Location using real-time GPS data.")
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
                        Link("Apple developer documentation, core motion pedometer", destination: URL(string: "https://developer.apple.com/documentation/coremotion/cmpedometer")!)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 5)
                            .foregroundStyle(Color.blue)
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
                            .font(.callout)
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
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            stepManager.updateCurrentPaceAndCadence()
        }
    }
    
    // Stop the timer
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Authenticate to enable step length control."
            
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

#Preview {
    StepCountView()
}
