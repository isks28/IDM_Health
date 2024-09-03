//
//  activityView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI
import HealthKit
import Charts
import Foundation

struct activityView: View {
    @StateObject private var healthKitManager: ActivityManager
    @State private var isRecording = false
    
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    init() {
        let calendar = Calendar.current
            var components = DateComponents()
            components.year = 2024
            components.month = 1
            components.day = 1
            let customStartDate = calendar.date(from: components) ?? Date()

        
        _healthKitManager = StateObject(wrappedValue: ActivityManager(startDate: Date(), endDate: Date()))
        _startDate = State(initialValue: customStartDate)
        _endDate = State(initialValue: Date())
    }
    
    var body: some View {
        VStack {
            Text("Activity Health Data")
                .font(.largeTitle)
            Text("Set Start and End-Date of Data to be fetched:")
                .font(.headline)
                .padding(.top, 50)
            
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                .onChange(of: startDate) {
                        healthKitManager.startDate = startDate
                    }
            
            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                .onChange(of: endDate) {
                        healthKitManager.endDate = endDate
                    }
                
            Text("To be fetched Data:")
                .font(.headline)
                .padding(.top)
            ScrollView {
                VStack {
                    Section(header: Text("Step Count")) {
                        if !healthKitManager.stepCountData.isEmpty {
                            LineChartViewActivity(data: healthKitManager.stepCountData.map { ChartDataactivity(date: $0.startDate, value: $0.quantity.doubleValue(for: HKUnit.count())) }, title: "Step Count")
                                .frame(height: 200)
                        }
                    }
                    
                    Section(header: Text("Active Energy Burned")) {
                        if !healthKitManager.activeEnergyBurnedData.isEmpty {
                            LineChartViewActivity(data: healthKitManager.activeEnergyBurnedData.map { ChartDataactivity(date: $0.startDate, value: $0.quantity.doubleValue(for: HKUnit.largeCalorie())) }, title: "Active Energy Burned in KiloCalorie")
                                .frame(height: 200)
                        }
                    }
                    
                    Section(header: Text("Move Time")) {
                        if !healthKitManager.appleMoveTimeData.isEmpty {
                            LineChartViewActivity(data: healthKitManager.appleMoveTimeData.map { ChartDataactivity(date: $0.startDate, value: $0.quantity.doubleValue(for: HKUnit.second())) }, title: "Move Time (s)")
                                .frame(height: 200)
                        }
                    }
                    
                    Section(header: Text("Stand Time")) {
                        if !healthKitManager.appleStandTimeData.isEmpty {
                            LineChartViewActivity(data: healthKitManager.appleStandTimeData.map { ChartDataactivity(date: $0.startDate, value: $0.quantity.doubleValue(for: HKUnit.second())) }, title: "Stand Time (s)")
                                .frame(height: 200)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 80) // Add padding to avoid overlapping with buttons

            Spacer()

            HStack{
                Button(action: {
                    if isRecording {
                        healthKitManager.saveDataAsCSV()
                    } else {
                        healthKitManager.fetchActivityData(startDate: startDate, endDate: endDate)
                    }
                    isRecording.toggle()
                }) {
                    Text(isRecording ? "Stop and Save" : "Start")
                        .padding()
                        .background(isRecording ? Color.gray : Color.mint)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding() // Ensure button is visible

                if healthKitManager.savedFilePath != nil {
                    Text("File saved")
                        .font(.footnote)
                        .padding()
                }
            }
            
        }
        .padding()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ChartDataactivity: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct LineChartViewActivity: View {
    var data: [ChartDataactivity]
    var title: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            Chart {
                ForEach(data) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Value", item.value)
                    )
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel(format: .dateTime.year().month().day())
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .shadow(radius: 5)
    }
}

#Preview {
    activityView()
}
