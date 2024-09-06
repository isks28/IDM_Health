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
    
    // Dictionary to track the current page for each time frame independently
    @State private var currentPageForTimeFrames: [TimeFrame: Int] = [
        .daily: 0,
        .weekly: 0,
        .monthly: 0,
        .sixMonths: 0,
        .yearly: 0
    ]
    
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
            Text(getTitleForCurrentPage(timeFrame: selectedTimeFrame, page: currentPageForTimeFrames[selectedTimeFrame] ?? 0))
                .font(.title2)
                .padding(.bottom)
            
            // Display the chart with horizontal paging
            TabView(selection: Binding(
                get: { currentPageForTimeFrames[selectedTimeFrame] ?? 0 },
                set: { newValue in
                    currentPageForTimeFrames[selectedTimeFrame] = newValue
                }
            )) {
                if !data.isEmpty {
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
            .padding(.bottom)
            
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
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: calendar.date(byAdding: .weekOfYear, value: -page, to: now)!)
            let mondayOfWeek = calendar.date(from: components) ?? now
            
            let dailyData = (0..<8).map { offset -> ChartDataactivity in
                let date = calendar.date(byAdding: .day, value: offset, to: mondayOfWeek)!
                return aggregateDataByDay(for: date, data: data)
            }
            filteredData = dailyData
            
        case .monthly:
            let pageDate = calendar.date(byAdding: .month, value: -page, to: now) ?? now
            let dailyData = (0..<30).map { offset -> ChartDataactivity in
                let date = calendar.date(byAdding: .day, value: offset, to: pageDate)!
                return aggregateDataByDay(for: date, data: data)
            }
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
    
    // Same helper functions as before for aggregating data
    // ...
}

    // Aggregate data by hour for the daily time frame
private func aggregateDataByHour(for date: Date, data: [ChartDataactivity]) -> [ChartDataactivity] {
    let calendar = Calendar.current
    var hourlyData: [ChartDataactivity] = []

    for hour in 0..<24 {
        let startOfHour = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
        let endOfHour = calendar.date(bySettingHour: hour, minute: 59, second: 59, of: date)!

        var hourlyValue = 0.0

        // Loop through all the data and aggregate it for the current hour range
        for item in data {
            let sampleStart = item.date
            let sampleEnd = calendar.date(byAdding: .second, value: Int(item.value), to: sampleStart) ?? sampleStart

            // Check if the sample overlaps with the current hour
            if sampleStart <= endOfHour && sampleEnd >= startOfHour {
                // Calculate the overlap between this hour and the sample period
                let overlapStart = max(sampleStart, startOfHour)
                let overlapEnd = min(sampleEnd, endOfHour)

                let overlapDuration = overlapEnd.timeIntervalSince(overlapStart)
                let totalDuration = sampleEnd.timeIntervalSince(sampleStart)

                // Proportionally distribute the data based on the overlap
                let proportion = overlapDuration / totalDuration
                hourlyValue += item.value * proportion
            }
        }

        // Append the data for this hour, showing the start and end of the hour
        if hourlyValue > 0 {
            hourlyData.append(ChartDataactivity(date: startOfHour, value: hourlyValue))
        } else {
            // Append even if there's no data for consistent display in the list and chart
            hourlyData.append(ChartDataactivity(date: startOfHour, value: 0))
        }
    }

    return hourlyData
}


    // Aggregate data by day for weekly and monthly time frames
    private func aggregateDataByDay(for date: Date, data: [ChartDataactivity]) -> ChartDataactivity {
        let calendar = Calendar.current
        
        // Define the start and end of the day
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)!
        
        var dailyValue = 0.0
        
        // Loop through all the data to sum the values for the day
        for item in data {
            let sampleStart = item.date
            let sampleEnd = calendar.date(byAdding: .second, value: Int(item.value), to: sampleStart) ?? sampleStart
            
            // Check if the sample overlaps with the current day
            if sampleStart <= endOfDay && sampleEnd >= startOfDay {
                // Calculate the overlap between this day and the sample period
                let overlapStart = max(sampleStart, startOfDay)
                let overlapEnd = min(sampleEnd, endOfDay)
                
                let overlapDuration = overlapEnd.timeIntervalSince(overlapStart)
                let totalDuration = sampleEnd.timeIntervalSince(sampleStart)
                
                // Proportionally distribute the step count based on the overlap
                let proportion = overlapDuration / totalDuration
                dailyValue += item.value * proportion
            }
        }
        
        // Return the aggregated data for the entire day
        return ChartDataactivity(date: startOfDay, value: dailyValue)
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
                // Find the Monday of the current week
                var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: calendar.date(byAdding: .weekOfYear, value: -page, to: now)!)
                components.weekday = 2 // Monday is the 2nd day of the week
                
                let mondayOfWeek = calendar.date(from: components) ?? now
                let sundayOfWeek = calendar.date(byAdding: .day, value: 6, to: mondayOfWeek) ?? now
                
                dateFormatter.dateFormat = "MMM dd"
                let mondayString = dateFormatter.string(from: mondayOfWeek)
                let sundayString = dateFormatter.string(from: sundayOfWeek)
                
                title = "\(mondayString) - \(sundayString)" // Show Monday to Sunday
                
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
            Text(title)
                .font(.headline)

            if data.allSatisfy({ $0.value == 0 }) {
                Text("No Data")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                Chart {
                    ForEach(data) { item in
                        BarMark(
                            x: .value("Date", item.date),
                            y: .value("Value", item.value)
                        )
                        .offset(x: 6)
                    }
                }
                .chartXAxis {
                    switch timeFrame {
                    case .daily:
                        // Hourly marks for daily view
                        AxisMarks(values: .automatic(desiredCount: 4)) { value in
                            AxisValueLabel(format: .dateTime.hour())
                            AxisGridLine()
                        }

                    case .weekly:
                        // Day marks for weekly view
                        AxisMarks(values: .automatic(desiredCount: 7)) { value in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            AxisGridLine()
                        }

                    case .monthly:
                        // Date marks for monthly view (from the 1st to the end of the month)
                        AxisMarks(values: .automatic(desiredCount: 7)) { value in
                            AxisValueLabel(format: .dateTime.day())
                        }

                    case .sixMonths:
                        // Month marks for six months view
                        AxisMarks(values: stride(from: 1, through: 6, by: 1).map { $0 }) { value in
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                        }

                    case .yearly:
                        // Narrow month marks (first letter) for yearly view
                        AxisMarks(values: stride(from: 1, through: 12, by: 1).map { $0 }) { value in
                            AxisValueLabel(format: .dateTime.month(.narrow))
                        }
                    }
                }

                // Scrollable List of Data below the chart
                ScrollView {
                    ForEach(data) { item in
                        HStack {
                            Text(formatDateForTimeFrame(item.date)) // Display date formatted based on time frame
                            Spacer()
                            Text("\(Int(item.value))") // Display value with 2 decimal places
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 3)
                        .padding(.horizontal)
                    }
                }
                .frame(maxHeight: 200) // Restrict the height of the scrollable list
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .shadow(radius: 5)
    }

    // Helper function to format the date based on the selected time frame
    private func formatDateForTimeFrame(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        switch timeFrame {
        case .daily:
            // Format as hour (24 Hours)
            formatter.dateFormat = "HH"
            return "\(formatter.string(from: date)) Hours"

        case .weekly:
            // Format as day of the week (e.g., Monday, Tuesday)
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)

        case .monthly:
            // Format as day of the month (e.g., 1st, 2nd, etc.)
            formatter.dateFormat = "d"
            let day = formatter.string(from: date)
            return day + ordinalSuffix(for: day)

        case .sixMonths, .yearly:
            // Format as month (e.g., Jan, Feb)
            formatter.dateFormat = "MMM"
            return formatter.string(from: date)
        }
    }

    // Helper function to provide the ordinal suffix for day (1st, 2nd, 3rd, etc.)
    private func ordinalSuffix(for day: String) -> String {
        guard let dayInt = Int(day) else { return "" }
        switch dayInt {
        case 11...13:
            return "th"
        case _ where dayInt % 10 == 1:
            return "st"
        case _ where dayInt % 10 == 2:
            return "nd"
        case _ where dayInt % 10 == 3:
            return "rd"
        default:
            return "th"
        }
    }
}

#Preview {
    activityView()
}
