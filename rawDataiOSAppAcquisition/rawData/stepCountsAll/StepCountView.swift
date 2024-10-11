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
    
    var body: some View {
        VStack {
            Text("Step Count Data Acquisition")
                .font(.title)
                .foregroundStyle(Color.mint)
                .padding(.top, 5)
            Spacer()
            
            // Step Count Display
            VStack {
                if stepManager.stepCount > 0 {
                    Text("Step Count")
                        .font(.title2)
                        .foregroundStyle(Color.pink)
                        .padding()
                    
                    Text("Steps: \(stepManager.stepCount)")
                        .font(.title)
                        .padding()
                    
                    if let distance = stepManager.distance {
                        Text(String(format: "Distance: %.2f meters", distance))
                            .font(.title3)
                            .padding()
                    } else {
                        Text("Distance: Not available")
                            .font(.title3)
                            .padding()
                    }
                } else {
                    Text("No Data")
                        .padding()
                }
            }
            
            // Toggle controls for real-time and interval-based recording
            HStack {
                Toggle("Real-Time", isOn: $isRecordingRealTime)
                    .onChange(of: isRecordingRealTime) { _, newValue in
                        isRecording = false
                        stepManager.stopStepCountCollection()
                        stepManager.savedFilePath = nil // Reset "File saved" text
                        
                        if newValue {
                            isRecordingInterval = false
                        }
                    }
                
                Toggle("Time-Interval", isOn: $isRecordingInterval)
                    .onChange(of: isRecordingInterval) { _, newValue in
                        isRecording = false
                        stepManager.stopStepCountCollection()
                        stepManager.savedFilePath = nil // Reset "File saved" text
                        
                        if newValue {
                            isRecordingRealTime = false
                        }
                    }
            }
            .padding()
            
            // Start/Stop buttons for recording
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
                            stepManager.savedFilePath = nil // Reset "File saved" text
                            if newValue {
                                stepManager.scheduleStepCountCollection(startDate: startDate, endDate: endDate) {
                                    DispatchQueue.main.async {
                                        isRecording = false
                                        stepManager.removeDataCollectionNotification() // Remove notification
                                    }
                                }
                                stepManager.showDataCollectionNotification() // Show notification on start
                            } else {
                                stepManager.stopStepCountCollection()
                                stepManager.removeDataCollectionNotification() // Remove notification on stop
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
                            stepManager.savedFilePath = nil // Reset "File saved" text when starting a new recording
                            
                            if isRecording {
                                stepManager.stopStepCountCollection()
                                stepManager.removeDataCollectionNotification() // Remove notification on stop
                            } else {
                                stepManager.startStepCountCollection()
                                stepManager.showDataCollectionNotification() // Show notification on start
                            }
                            isRecording.toggle()
                        }) {
                            Text(isRecording ? "Stop and Save" : "Start")
                                .padding()
                                .background(isRecording ? Color.gray : Color.mint)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }
                        
                        if stepManager.savedFilePath != nil {
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
            let reason = "Authenticate to start step count recording."
            
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
