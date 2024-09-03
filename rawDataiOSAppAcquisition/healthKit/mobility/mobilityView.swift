//
//  mobilityView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI
import HealthKit
import Charts
import Foundation

struct mobilityView: View {
    @StateObject private var healthKitManager: HealthKitMobilityManager
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

        
        _healthKitManager = StateObject(wrappedValue: HealthKitMobilityManager(startDate: Date(), endDate: Date()))
        _startDate = State(initialValue: customStartDate)
        _endDate = State(initialValue: Date())
    }
    
    var body: some View {
        VStack {
            Text("Mobility Health Data")
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
                    Section(header: Text("Walking Double Support")) {
                        if !healthKitManager.walkingDoubleSupportData.isEmpty {
                            LineChartView(data: healthKitManager.walkingDoubleSupportData.map { ChartData(date: $0.startDate, value: $0.quantity.doubleValue(for: HKUnit.percent()) * 100) }, title: "Walking Double Support")
                                .frame(height: 200)
                        }
                    }
                    
                    Section(header: Text("Walking Asymmetry")) {
                        if !healthKitManager.walkingAsymmetryData.isEmpty {
                            LineChartView(data: healthKitManager.walkingAsymmetryData.map { ChartData(date: $0.startDate, value: $0.quantity.doubleValue(for: HKUnit.percent()) * 100) }, title: "Walking Asymmetry")
                                .frame(height: 200)
                        }
                    }
                    
                    Section(header: Text("Walking Speed")) {
                        if !healthKitManager.walkingSpeedData.isEmpty {
                            LineChartView(data: healthKitManager.walkingSpeedData.map { ChartData(date: $0.startDate, value: $0.quantity.doubleValue(for: HKUnit.meter().unitDivided(by: HKUnit.second())) * 3.6) }, title: "Walking Speed (km/h)")
                                .frame(height: 200)
                        }
                    }
                    
                    Section(header: Text("Walking Step Length")) {
                        if !healthKitManager.walkingStepLengthData.isEmpty {
                            LineChartView(data: healthKitManager.walkingStepLengthData.map { ChartData(date: $0.startDate, value: $0.quantity.doubleValue(for: HKUnit.meter())) }, title: "Walking Step Length (m)")
                                .frame(height: 200)
                        }
                    }
                    
                    Section(header: Text("Walking Steadiness")) {
                        if !healthKitManager.walkingSteadinessData.isEmpty {
                            LineChartView(data: healthKitManager.walkingSteadinessData.map { ChartData(date: $0.startDate, value: $0.quantity.doubleValue(for: HKUnit.percent()) * 100) }, title: "Walking Steadiness")
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
                        healthKitManager.fetchMobilityData()
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

struct ChartData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct LineChartView: View {
    var data: [ChartData]
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
    mobilityView()
}
