//
//  rawDataAllView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI
import CoreMotion

struct rawDataAllView: View {
    @StateObject private var motionManager = RawDataAllManager()
    @State private var isRecording = false
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var isRecordingRealTime = false
    @State private var isRecordingInterval = false
    
    var body: some View {
        VStack {
            Text("Raw Data All Acquisition")
                .font(.title)
                .foregroundStyle(Color.mint)
            
            TabView {
                List(motionManager.userAccelerometerData, id: \.self) { data in
                    Text(data)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            if let latestData = motionManager.userAccelerometerData.last {
                Text(latestData)
                    .padding()
            } else {
                Text("No Data")
                    .padding()
            }
            
            HStack {
                Toggle("Real-Time", isOn: $isRecordingRealTime)
                    .onChange(of: isRecordingRealTime) { oldValue, newValue in
                        isRecording = false
                        motionManager.stopRawDataAllCollection()
                        motionManager.savedFilePath = nil // Reset "File saved" text
                        
                        if newValue {
                            isRecordingInterval = false
                        }
                    }
                
                Toggle("Time-Interval", isOn: $isRecordingInterval)
                    .onChange(of: isRecordingInterval) { oldValue, newValue in
                        isRecording = false
                        motionManager.stopRawDataAllCollection()
                        motionManager.savedFilePath = nil // Reset "File saved" text
                        
                        if newValue {
                            isRecordingRealTime = false
                        }
                    }
            }
            .padding()
            
            VStack {
                if isRecordingInterval {
                    DatePicker("Start Date and Time", selection: $startDate)
                        .datePickerStyle(CompactDatePickerStyle())
                    
                    DatePicker("End Date and Time", selection: $endDate)
                        .datePickerStyle(CompactDatePickerStyle())
                    
                    Toggle(isOn: $isRecording) {
                        Text("Turn the toggle on to start automatic Raw Data All retrieval")
                            .padding()
                            .background(isRecording ? Color.mint : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .padding()
                    .onChange(of: isRecording, initial: false) { oldValue, newValue in
                        motionManager.savedFilePath = nil // Reset "File saved" text when starting a new recording
                        
                        if newValue {
                            motionManager.scheduleDataCollection(startDate: startDate, endDate: endDate) {
                                DispatchQueue.main.async {
                                    isRecording = false
                                }
                            }
                        } else {
                            motionManager.stopRawDataAllCollection()
                        }
                    }
                }
                
                if isRecordingRealTime {
                    Button(action: {
                        motionManager.savedFilePath = nil // Reset "File saved" text when starting a new recording
                        
                        if isRecording {
                            motionManager.stopRawDataAllCollection()
                        } else {
                            motionManager.startRawDataAllCollection(realTime: true)
                        }
                        isRecording.toggle()
                    }) {
                        Text(isRecording ? "Stop and Save" : "Start")
                            .padding()
                            .background(isRecording ? Color.gray : Color.mint)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .padding()
                }
                
                if motionManager.savedFilePath != nil {
                    Text("File saved")
                        .font(.footnote)
                        .padding()
                }
            }
            .padding()
        }
    }
}

#Preview {
    rawDataAllView()
}
