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

enum TimeFrame: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case sixMonths = "6 Months"
    case yearly = "Yearly"
}

struct activityView: View {
    @StateObject private var healthKitManager: ActivityManager
    @State private var isRecording = false
    
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    // State variables to control sheet presentation
    @State private var showingStepCountChart = false
    @State private var showingActiveEnergyChart = false
    @State private var showingMoveTimeChart = false
    @State private var showingStandTimeChart = false
    
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
                    // Step Count Section with info button
                    Section(header: Text("Step Count")) {
                        HStack {
                            if !healthKitManager.stepCountData.isEmpty{
                                Text("Step Count Data is Available")
                                    .foregroundStyle(Color.mint)
                                    .multilineTextAlignment(.center)
                            }
                            Button(action: {
                                showingStepCountChart = true
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(Color.pink)
                            }
                            .sheet(isPresented: $showingStepCountChart) {
                                ChartWithTimeFramePicker(title: "Step Count", data: healthKitManager.stepCountData.map { ChartDataactivity(date: $0.startDate, value: $0.quantity.doubleValue(for: HKUnit.count())) })
                            }
                        }
                        .padding(.bottom, 10)
                    }
                    
                    // Active Energy Burned Section with info button
                    Section(header: Text("Active Energy Burned")) {
                        HStack {
                            if !healthKitManager.activeEnergyBurnedData.isEmpty{
                                Text("Active Energy Burned Data is Available")
                                    .foregroundStyle(Color.mint)
                                    .multilineTextAlignment(.center)
                            }
                            Button(action: {
                                showingActiveEnergyChart = true
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(Color.pink)
                            }
                            .sheet(isPresented: $showingActiveEnergyChart) {
                                ChartWithTimeFramePicker(title: "Active Energy Burned in KiloCalorie", data: healthKitManager.activeEnergyBurnedData.map { ChartDataactivity(date: $0.startDate, value: $0.quantity.doubleValue(for: HKUnit.largeCalorie())) })
                            }
                        }
                        .padding(.bottom, 10)
                    }
                    
                    // Move Time Section with info button
                    Section(header: Text("Move Time")) {
                        HStack {
                            if !healthKitManager.appleMoveTimeData.isEmpty{
                                Text("Move Time Data is Available")
                                    .foregroundStyle(Color.mint)
                                    .multilineTextAlignment(.center)
                            }
                            Button(action: {
                                showingMoveTimeChart = true
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(Color.pink)
                            }
                            .sheet(isPresented: $showingMoveTimeChart) {
                                ChartWithTimeFramePicker(title: "Move Time (s)", data: healthKitManager.appleMoveTimeData.map { ChartDataactivity(date: $0.startDate, value: $0.quantity.doubleValue(for: HKUnit.second())) })
                            }
                        }
                        .padding(.bottom, 10)
                    }
                    
                    // Stand Time Section with info button
                    Section(header: Text("Stand Time")) {
                        HStack {
                            if !healthKitManager.appleStandTimeData.isEmpty{
                                Text("Stand Time Data is Available")
                                    .foregroundStyle(Color.mint)
                                    .multilineTextAlignment(.center)
                            }
                            Button(action: {
                                showingStandTimeChart = true
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(Color.pink)
                            }
                            .sheet(isPresented: $showingStandTimeChart) {
                                ChartWithTimeFramePicker(title: "Stand Time (s)", data: healthKitManager.appleStandTimeData.map { ChartDataactivity(date: $0.startDate, value: $0.quantity.doubleValue(for: HKUnit.second())) })
                            }
                        }
                        .padding(.bottom, 10)
                    }
                }
                .padding(.horizontal)
            }

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
                    Text(isRecording ? "Save Data" : "Fetch Data")
                        .padding()
                        .background(isRecording ? Color.gray : Color.mint)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    if healthKitManager.savedFilePath != nil {
                        Text("File saved")
                            .font(.footnote)
                    }
                }
                .padding() // Ensure button is visible
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

struct ChartWithTimeFramePicker: View {
    var title: String
    var data: [ChartDataactivity]
    
    // State to control the selected time frame
    @State private var selectedTimeFrame: TimeFrame = .daily
    @State private var currentPage: Int = 0 // Track the current page for paging behavior
    
    var body: some View {
        VStack {
            // Picker for selecting the time frame
            Picker("Time Frame", selection: $selectedTimeFrame) {
                ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                    Text(timeFrame.rawValue).tag(timeFrame)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Display date title for each time frame and page
            Text(getTitleForCurrentPage(timeFrame: selectedTimeFrame, page: currentPage))
                .font(.title2)
                .padding(.bottom)
            
            // Display the chart with horizontal paging
            TabView(selection: $currentPage) {
                if !data.isEmpty{
                    ForEach((0..<10).reversed(), id: \.self) { page in
                        BoxChartViewActivity(data: filterAndAggregateDataForPage(data, timeFrame: selectedTimeFrame, page: page), timeFrame: selectedTimeFrame, title: title)
                            .tag(page)
                            .padding(.horizontal)
                    }
                } else {
                    Text("No Data")
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Remove default page indicator for a smooth effect
            .frame(height: 300)
            
            Spacer()
        }
        .padding()
    }
    
    // Function to filter and aggregate data based on the current page and time frame
    private func filterAndAggregateDataForPage(_ data: [ChartDataactivity], timeFrame: TimeFrame, page: Int) -> [ChartDataactivity] {
        let calendar = Calendar.current
        let now = Date()
        var filteredData: [ChartDataactivity] = []
        
        switch timeFrame {
        case .daily:
            let pageDate = calendar.date(byAdding: .day, value: -page, to: now) ?? now
            let hourlyData = aggregateDataByHour(for: pageDate, data: data)
            filteredData = hourlyData
            
        case .weekly:
            let pageDate = calendar.date(byAdding: .weekOfYear, value: -page, to: now) ?? now
            let dailyData = aggregateDataByDay(for: pageDate, data: data, days: 7)
            filteredData = dailyData
            
        case .monthly:
            let pageDate = calendar.date(byAdding: .month, value: -page, to: now) ?? now
            let dailyData = aggregateDataByDay(for: pageDate, data: data, days: 30)
            filteredData = dailyData
            
        case .sixMonths:
            let pageDate = calendar.date(byAdding: .month, value: -(page * 6), to: now) ?? now
            let monthlyData = aggregateDataByMonth(for: pageDate, data: data, months: 6)
            filteredData = monthlyData
            
        case .yearly:
            let pageDate = calendar.date(byAdding: .year, value: -page, to: now) ?? now
            let monthlyData = aggregateDataByMonth(for: pageDate, data: data, months: 12)
            filteredData = monthlyData
        }
        
        return filteredData
    }
    
    // Aggregate data by hour for the daily time frame
    private func aggregateDataByHour(for date: Date, data: [ChartDataactivity]) -> [ChartDataactivity] {
        let calendar = Calendar.current
        var hourlyData: [ChartDataactivity] = []
        
        for hour in 0..<24 {
            let startOfHour = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
            let endOfHour = calendar.date(bySettingHour: hour, minute: 59, second: 59, of: date)!
            let hourlyValue = data
                .filter { $0.date >= startOfHour && $0.date <= endOfHour }
                .map { $0.value }
                .reduce(0, +)
            
            hourlyData.append(ChartDataactivity(date: startOfHour, value: hourlyValue))
        }
        
        return hourlyData
    }

    // Aggregate data by day for weekly and monthly time frames
    private func aggregateDataByDay(for date: Date, data: [ChartDataactivity], days: Int) -> [ChartDataactivity] {
        let calendar = Calendar.current
        var dailyData: [ChartDataactivity] = []
        
        for dayOffset in 0..<days {
            let startOfDay = calendar.date(byAdding: .day, value: dayOffset, to: date)!
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)!
            let dailyValue = data
                .filter { $0.date >= startOfDay && $0.date <= endOfDay }
                .map { $0.value }
                .reduce(0, +)
            
            dailyData.append(ChartDataactivity(date: startOfDay, value: dailyValue))
        }
        
        return dailyData
    }

    // Aggregate data by month for 6-month and yearly time frames
    private func aggregateDataByMonth(for date: Date, data: [ChartDataactivity], months: Int) -> [ChartDataactivity] {
        let calendar = Calendar.current
        var monthlyData: [ChartDataactivity] = []
        
        for monthOffset in 0..<months {
            let startOfMonth = calendar.date(byAdding: .month, value: monthOffset, to: date)!
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!.addingTimeInterval(-1)
            let monthlyValue = data
                .filter { $0.date >= startOfMonth && $0.date <= endOfMonth }
                .map { $0.value }
                .reduce(0, +)
            
            monthlyData.append(ChartDataactivity(date: startOfMonth, value: monthlyValue))
        }
        
        return monthlyData
    }
    
    // Function to get the title for the current page based on the time frame
    private func getTitleForCurrentPage(timeFrame: TimeFrame, page: Int) -> String {
        let calendar = Calendar.current
        let now = Date()
        let dateFormatter = DateFormatter()
        var title: String = ""
        
        switch timeFrame {
        case .daily:
            let pageDate = calendar.date(byAdding: .day, value: -page, to: now) ?? now
            dateFormatter.dateStyle = .full
            title = dateFormatter.string(from: pageDate)
            
        case .weekly:
            let startOfWeek = calendar.date(byAdding: .weekOfYear, value: -page, to: now) ?? now
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? now
            dateFormatter.dateFormat = "MMM dd"
            title = "\(dateFormatter.string(from: startOfWeek)) - \(dateFormatter.string(from: endOfWeek))"
            
        case .monthly:
            let pageDate = calendar.date(byAdding: .month, value: -page, to: now) ?? now
            dateFormatter.dateFormat = "MMMM yyyy"
            title = dateFormatter.string(from: pageDate)
            
        case .sixMonths:
            let startDate = calendar.date(byAdding: .month, value: -(page * 6), to: now) ?? now
            let endDate = calendar.date(byAdding: .month, value: 5, to: startDate) ?? now
            dateFormatter.dateFormat = "MMM yyyy"
            title = "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
            
        case .yearly:
            let pageDate = calendar.date(byAdding: .year, value: -page, to: now) ?? now
            dateFormatter.dateFormat = "yyyy"
            title = dateFormatter.string(from: pageDate)
        }
        
        return title
    }
}

struct ChartDataactivity: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct BoxChartViewActivity: View {
    var data: [ChartDataactivity]
    var timeFrame: TimeFrame
    var title: String
    
    var body: some View {
        VStack(alignment: .leading) {
            // Check if all values in the data are 0 or if there's no data at all
            if data.allSatisfy({ $0.value == 0 }) {
                // Display "No Data" in the center of the chart area
                Text("No Data")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                Text(title)
                    .font(.headline)
                
                // Show the chart when there is valid data
                Chart {
                    ForEach(data) { item in
                        BarMark(
                            x: .value("Date", item.date),
                            y: .value("Value", item.value)
                        )
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        switch timeFrame {
                        case .daily:
                            AxisValueLabel(format: .dateTime.hour())
                        case .weekly:
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        case .monthly:
                            AxisValueLabel(format: .dateTime.day())
                        case .sixMonths, .yearly:
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                        }
                    }
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
