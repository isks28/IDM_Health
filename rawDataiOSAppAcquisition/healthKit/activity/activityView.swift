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
    @State private var showingDistanceWalkingRunningChart = false
    @State private var showingExerciseTimeChart = false
    
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
                                ChartWithTimeFramePicker(title: "Active Energy Burned in KiloCalorie", data: healthKitManager.activeEnergyBurnedData.map { ChartDataactivity(date: $0.startDate, value: $0.quantity.doubleValue(for: HKUnit.smallCalorie())) })
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
                    // Distance Walking Running Section with info button
                    Section(header: Text("Distance Walking/Running")) {
                        HStack {
                            if !healthKitManager.activeEnergyBurnedData.isEmpty{
                                Text("Distance Walking/Running Data is Available")
                                    .foregroundStyle(Color.mint)
                                    .multilineTextAlignment(.center)
                            }
                            Button(action: {
                                showingDistanceWalkingRunningChart = true
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(Color.pink)
                            }
                            .sheet(isPresented: $showingDistanceWalkingRunningChart) {
                                ChartWithTimeFramePicker(title: "Distance Walking/Running (m)", data: healthKitManager.distanceWalkingRunningData.map { ChartDataactivity(date: $0.startDate, value: $0.quantity.doubleValue(for: HKUnit.meter())) })
                            }
                        }
                        .padding(.bottom, 10)
                    }
                    // Exercise Time Section with info button
                    Section(header: Text("Exercise Time")) {
                        HStack {
                            if !healthKitManager.activeEnergyBurnedData.isEmpty{
                                Text("Exercise Time Data is Available")
                                    .foregroundStyle(Color.mint)
                                    .multilineTextAlignment(.center)
                            }
                            Button(action: {
                                showingExerciseTimeChart = true
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(Color.pink)
                            }
                            .sheet(isPresented: $showingExerciseTimeChart) {
                                ChartWithTimeFramePicker(title: "Exercise Time (s)", data: healthKitManager.appleExerciseTimeData.map { ChartDataactivity(date: $0.startDate, value: $0.quantity.doubleValue(for: HKUnit.second())) })
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
    
    // State for showing the popover
    @State private var showInfoPopover: Bool = false
    
    var body: some View {
        VStack {
            
            // Display additional information based on the selected section (Step Count, Active Energy, etc.)
            HStack {
                Text(getInformationText())
                    .font(.subheadline)
                    .padding(.top)
                    .multilineTextAlignment(.center)
                
                // Information button with popover
                Button(action: {
                    showInfoPopover.toggle()
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.pink)
                        .padding(.top)
                }
                .popover(isPresented: $showInfoPopover) {
                    // Popover content
                    VStack(alignment: .leading) {
                        Text("Additional Information")
                            .font(.title)
                            .padding(.bottom, 7)
                            .foregroundStyle(Color.pink)
                        Text(measuredUsing())
                            .font(.body)
                            .padding(.bottom, 3)
                        Text(useCase())
                            .font(.body)
                            .padding(.bottom, 3)
                    }
                    .frame(width: 300, height: 400) // Customize popover size
                }
            }
            .padding(.horizontal)
            
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
                .padding(.bottom, 8)
            
            // Filter the data for the current page and time frame
            let filteredData = filterAndAggregateDataForPage(data, timeFrame: selectedTimeFrame, page: currentPageForTimeFrames[selectedTimeFrame] ?? 0)

            
            // Calculate sum and average
            let (sum, average) = calculateSumAndAverage(for: selectedTimeFrame, data: filteredData)

            // Display correct title for total or average
            Text(getTitleForMetric())
                .font(.headline)

            // Conditional display: show total for daily view, average for others
            if title != "Active Energy Burned in KiloCalorie" && selectedTimeFrame == .daily {
                Text(sum == 0 ? "--" : "\(String(format: "%.0f", sum))")
                    .font(.headline)
                    .foregroundStyle(Color.mint)
            } 
            if title == "Active Energy Burned in KiloCalorie" && selectedTimeFrame == .daily {
                Text(sum == 0 ? "--" : "\(String(format: "%.2f", sum/1000))")
                    .font(.headline)
                    .foregroundStyle(Color.mint)
            } 
            if title == "Active Energy Burned in KiloCalorie" && selectedTimeFrame != .daily {
                Text(sum == 0 ? "--" : "\(String(format: "%.2f", average/1000))")
                    .font(.headline)
                    .foregroundStyle(Color.mint)
            }
            if title != "Active Energy Burned in KiloCalorie" && selectedTimeFrame != .daily {
                Text(average == 0 ? "--" : "\(String(format: "%.0f", average))")
                    .font(.headline)
                    .foregroundStyle(Color.mint)
            }
            
            // Display the chart with horizontal paging
            TabView(selection: Binding(
                get: { currentPageForTimeFrames[selectedTimeFrame] ?? 0 },
                set: { newValue in
                    currentPageForTimeFrames[selectedTimeFrame] = newValue
                }
            )) {
                if !data.isEmpty {
                    ForEach((0..<getPageCount(for: selectedTimeFrame)).reversed(), id: \.self) { page in
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
    
    private func calculateSumAndAverage(for timeFrame: TimeFrame, data: [ChartDataactivity]) -> (sum: Double, average: Double) {
        let totalSum = data.map { $0.value }.reduce(0, +)
        
        // Count only the data points that have a value greater than 0
        let nonZeroDataCount = data.filter { $0.value > 0 }.count
        
        let count: Int
        
        switch timeFrame {
        case .daily:
            // If it's a daily view, the count is either 1 or 0, depending on whether data exists
            count = nonZeroDataCount > 0 ? 1 : 0
            
        case .weekly, .monthly, .sixMonths, .yearly:
            // For all other views, use the count of non-zero data points
            count = nonZeroDataCount > 0 ? nonZeroDataCount : 1  // Avoid division by zero
        
        }
        
        // Calculate the average only if we have valid data points
        let average = count > 0 ? totalSum / Double(count) : 0.0
        return (sum: totalSum, average: average)
    }
    
    private func getTitleForMetric() -> String {
        let description: String
        let dataType: String
        
        // Determine the data type based on the title of the chart
        switch title {
        case "Step Count":
            dataType = "Step Counts"
        case "Active Energy Burned in KiloCalorie":
            dataType = "Active Energy Burned in KCal"
        case "Move Time (s)":
            dataType = "Move Time in seconds"
        case "Stand Time (s)":
            dataType = "Stand Time in seconds"
        case "Distance Walking/Running (m)":
            dataType = "Distance Walking/Running in meters"
        case "Exercise Time (s)":
            dataType = "Exercise Time in seconds"
        default:
            dataType = "Data"
        }
        
        // Determine the description based on the selected timeframe
        switch selectedTimeFrame {
        case .daily:
            description = "Total \(dataType) in this Day"
        case .weekly:
            description = "Daily Average \(dataType) in this Week"
        case .monthly:
            description = "Daily Average \(dataType) in this Month"
        case .sixMonths:
            description = "Weekly Average \(dataType) in this 6 Months Span"
        case .yearly:
            description = "Monthly Average \(dataType) in this Year"
        }
        
        return description
    }
    
    // Helper function to display different text based on the selected data section
    private func getInformationText() -> String {
        switch title {
        case "Step Count":
            return "Number of Steps taken"
        case "Active Energy Burned in KiloCalorie":
            return "Amount of Energy burned (Calories) through physical activity, excluding Energy burned at Rest (basal metabolic rate)"
        case "Move Time (s)":
            return "Amount of time spent performing activities that involve full-body movements during the specified day."
        case "Stand Time (s)":
            return "Amount of time has spent standing"
        case "Distance Walking/Running (m)":
            return "Distance Walking/Running in meters"
        case "Exercise Time (s)":
            return "Exercise Time in seconds"
        default:
            return "Data not available."
        }
    }
    
    // Helper function for detailed popover information
    private func measuredUsing() -> String {
        switch title {
        case "Step Count":
            return "MEASURED USING: Accelerometer and Gyroscope"
        case "Active Energy Burned in KiloCalorie":
            return "Measured using: Accelerometer, Gyroscope and GPS. Use Case: Managing weight, metabolic conditions, diabetes, cardiovascular diseases"
        case "Move Time (s)":
            return "Move time represents the time during which physical activity was recorded. It's measured in seconds."
        case "Stand Time (s)":
            return "Stand time is the total duration in which the user stood up and moved around during the day, measured in seconds."
        case "Distance Walking/Running (m)":
            return "Distance Walking/Running in meters"
        case "Exercise Time (s)":
            return "Exercise Time in seconds"
        default:
            return "More information about this section is not available."
        }
    }
    private func useCase() -> String {
        switch title {
        case "Step Count":
            return "USE CASE: Cardiovascular Diseases, Diabetes, Parkinson Diseases, Musculoskeletal Issues such as Arthritis"
        case "Active Energy Burned in KiloCalorie":
            return "Measured using: Accelerometer, Gyroscope and GPS. Use Case: Managing weight, metabolic conditions, diabetes, cardiovascular diseases"
        case "Move Time (s)":
            return "Move time represents the time during which physical activity was recorded. It's measured in seconds."
        case "Stand Time (s)":
            return "Stand time is the total duration in which the user stood up and moved around during the day, measured in seconds."
        case "Distance Walking/Running (m)":
            return "Distance Walking/Running in meters"
        case "Exercise Time (s)":
            return "Exercise Time in seconds"
        default:
            return "More information about this section is not available."
        }
    }
    private func normalRange() -> String {
        switch title {
        case "Step Count":
            return "NORMAL RANGE: 10.000 per Day"
        case "Active Energy Burned in KiloCalorie":
            return "Measured using: Accelerometer, Gyroscope and GPS. Use Case: Managing weight, metabolic conditions, diabetes, cardiovascular diseases"
        case "Move Time (s)":
            return "Move time represents the time during which physical activity was recorded. It's measured in seconds."
        case "Stand Time (s)":
            return "Stand time is the total duration in which the user stood up and moved around during the day, measured in seconds."
        case "Distance Walking/Running (m)":
            return "Distance Walking/Running in meters"
        case "Exercise Time (s)":
            return "Exercise Time in seconds"
        default:
            return "More information about this section is not available."
        }
    }
}
    
    // Function to dynamically adjust the number of pages based on time frame
        private func getPageCount(for timeFrame: TimeFrame) -> Int {
            switch timeFrame {
            case .daily:
                return 21  // 21 pages for daily (three week)
            case .weekly:
                return 16  // 16 pages for weekly (four month)
            case .monthly:
                return 12 // 12 pages for monthly (one year)
            case .sixMonths:
                return 6  // 6 pages for six months
            case .yearly:
                return 1  // 1 years
            }
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
                if offset == 7 {
                return ChartDataactivity(date: date, value: 0)
                            }
                return aggregateDataByDay(for: date, data: data)
            }
            filteredData = dailyData
            
        case .monthly:
            let pageDate = calendar.date(byAdding: .month, value: -page, to: now) ?? now
            
            // Get the first day of the month
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: pageDate))!
            
            // Calculate the number of days in the month
            let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
            let numberOfDaysInMonth = range.count
            
            // Aggregate data for each day of the month
            let dailyData = (0..<numberOfDaysInMonth).map { offset -> ChartDataactivity in
                let date = calendar.date(byAdding: .day, value: offset, to: startOfMonth)!
                return aggregateDataByDay(for: date, data: data)
            }
            filteredData = dailyData
            
        case .sixMonths:
            // Subtract the page number to get a 6-month period starting point
            let startOfSixMonths = calendar.date(byAdding: .month, value: -(page * 6), to: now) ?? now
            
            // Aggregate data by day and sum it by week for the 6-month view
            let sixMonthsData = aggregateDataByWeek(for: startOfSixMonths, data: data, weeks: 26)
            filteredData = sixMonthsData

        case .yearly:
            // Subtract the page number to get a 1-year period starting point
            let selectedYear = calendar.component(.year, from: now) - page
            let startOfYear = calendar.date(from: DateComponents(year: selectedYear, month: 1))!
            
            // Aggregate data by day and sum it by month for the yearly view
            let yearlyData = aggregateDataByMonth(for: startOfYear, data: data, months: 12)
            filteredData = yearlyData

        }
            
        return filteredData
    }
    
    // Same helper functions as before for aggregating data
    // ...

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
            hourlyData.append(ChartDataactivity(date: startOfHour, value: hourlyValue))
        }

        return hourlyData
    }

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

                // Proportionally distribute the data based on the overlap
                let proportion = overlapDuration / totalDuration
                dailyValue += item.value * proportion
            }
        }

        // Return the aggregated data for the entire day, even if there's no data (returning 0 in that case)
        return ChartDataactivity(date: startOfDay, value: dailyValue)
    }

    private func aggregateDataByWeek(for startDate: Date, data: [ChartDataactivity], weeks: Int) -> [ChartDataactivity] {
        let calendar = Calendar.current
        var weeklyData: [ChartDataactivity] = []

        for weekOffset in 0..<weeks {
            // Get the start and end of each week
            let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startDate)!)?.start ?? startDate
            let currentWeekEnd = calendar.date(byAdding: .day, value: 6, to: currentWeekStart)!
            
            var weeklyValue = 0.0

            // Loop through all the data to sum the values for the week
            for item in data {
                let sampleStart = item.date
                let sampleEnd = calendar.date(byAdding: .second, value: Int(item.value), to: sampleStart) ?? sampleStart

                // Check if the sample overlaps with the current week
                if sampleStart <= currentWeekEnd && sampleEnd >= currentWeekStart {
                    // Calculate the overlap between this week and the sample period
                    let overlapStart = max(sampleStart, currentWeekStart)
                    let overlapEnd = min(sampleEnd, currentWeekEnd)

                    let overlapDuration = overlapEnd.timeIntervalSince(overlapStart)
                    let totalDuration = sampleEnd.timeIntervalSince(sampleStart)

                    // Proportionally distribute the data based on the overlap
                    let proportion = overlapDuration / totalDuration
                    weeklyValue += item.value * proportion
                }
            }

            // Append the aggregated data for the current week
            weeklyData.append(ChartDataactivity(date: currentWeekStart, value: weeklyValue))
        }
        
        return weeklyData
    }

    // Aggregate data by month for 6-month and yearly time frames
    private func aggregateDataByMonth(for startDate: Date, data: [ChartDataactivity], months: Int) -> [ChartDataactivity] {
        let calendar = Calendar.current
        var monthlyData: [ChartDataactivity] = []
        
        for monthOffset in 0..<months {
            // Get the start and end of each month
            let currentMonthStart = calendar.date(byAdding: .month, value: monthOffset, to: startDate)!
            let currentMonthEnd = calendar.date(byAdding: .month, value: 1, to: currentMonthStart)!.addingTimeInterval(-1)
            
            var monthlyValue = 0.0

            // Loop through all the data to sum the values for the month
            for item in data {
                let sampleStart = item.date
                let sampleEnd = calendar.date(byAdding: .second, value: Int(item.value), to: sampleStart) ?? sampleStart

                // Check if the sample overlaps with the current month
                if sampleStart <= currentMonthEnd && sampleEnd >= currentMonthStart {
                    // Calculate the overlap between this month and the sample period
                    let overlapStart = max(sampleStart, currentMonthStart)
                    let overlapEnd = min(sampleEnd, currentMonthEnd)

                    let overlapDuration = overlapEnd.timeIntervalSince(overlapStart)
                    let totalDuration = sampleEnd.timeIntervalSince(sampleStart)

                    // Proportionally distribute the data based on the overlap
                    let proportion = overlapDuration / totalDuration
                    monthlyValue += item.value * proportion
                }
            }
            
            // Append the aggregated data for the current month
            monthlyData.append(ChartDataactivity(date: currentMonthStart, value: monthlyValue))
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
                            y: .value("Value", title == "Active Energy Burned in KiloCalorie" ? item.value / 1000 : item.value)
                        )
                        .offset(x: getOffsetForTimeFrame(timeFrame))
                    }
                }
                .chartXScale(domain: getXScaleDomain())
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
                                .offset(x: 5)
                            AxisGridLine()
                        }

                    case .monthly:
                        // Date marks for monthly view (from the 1st to the end of the month)
                        AxisMarks(values: .automatic) { value in
                            AxisValueLabel(format: .dateTime.day())
                                .offset(x: -(2))
                            AxisGridLine()
                        }

                    case .sixMonths:
                        // Month marks for six months view
                        AxisMarks(values: .stride(by: .month)) { value in
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                                .offset(x: 8)
                            AxisGridLine()
                        }

                    case .yearly:
                        // Narrow month marks (first letter) for yearly view
                        AxisMarks(values: .automatic(desiredCount: 12)) { value in
                            AxisValueLabel(format: 
                                .dateTime.month(.narrow))
                            .offset(x: 2.5)
                            AxisGridLine()
                        }
                    }
                }

                // Scrollable List of Data below the chart
                ScrollView {
                    ForEach(timeFrame == .weekly ? Array(data.prefix(7)) : data) { item in
                        HStack {
                            Text(formatDateForTimeFrame(item.date)) // Display date formatted based on time frame
                            Spacer()
                            
                            // Apply division by 1000 if the title indicates it's the Active Energy Burned section
                            if title == "Active Energy Burned in KiloCalorie" {
                                Text("\(String(format: "%.0f", item.value / 1000)) kcal") // Convert to kiloCalories
                            } else {
                                Text("\(String(format: "%.0f", item.value))") // Display value without conversion
                            }
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
    
    // Function to get the offset based on the time frame. Offset to set the position of the X-Axis Label
        private func getOffsetForTimeFrame(_ timeFrame: TimeFrame) -> CGFloat {
            switch timeFrame {
            case .daily:
                return 6 // Offset for daily view
            case .weekly:
                return 20 // Offset for weekly view
            case .monthly:
                return 5 // Offset for monthly view
            case .sixMonths:
                return 0 // Offset for 6 months view
            case .yearly:
                return 10 // No offset for yearly view
            }
        }

    // Helper function to format the date based on the selected time frame
    private func formatDateForTimeFrame(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        switch timeFrame {
        case .daily:
            // Format as "HH-HH Hours" for daily view
            formatter.dateFormat = "HH"
            let startHour = formatter.string(from: date)
            let endHour = formatter.string(from: calendar.date(byAdding: .hour, value: 1, to: date) ?? date)
            return "\(startHour)-\(endHour)"
        
        case .weekly:
            // Format as day of the week (e.g., Monday, Tuesday)
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        
        case .monthly:
            // Format as day of the month (e.g., 1st, 2nd, etc.)
            formatter.dateFormat = "d"
            let day = formatter.string(from: date)
            return day + ordinalSuffix(for: day)
        
        case .sixMonths:
            // Display the week span (start and end dates of the week)
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? date  // Change 13 to 6
            formatter.dateFormat = "MMM dd"

            // Format start and end dates correctly
            let startDate = formatter.string(from: startOfWeek)
            let endDate = formatter.string(from: endOfWeek)

            // Return the correct week span
            return "\(startDate) - \(endDate)"
        
        case .yearly:
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
    // Function to extend the X-axis range based on the data for monthly time frame
        private func getXScaleDomain() -> ClosedRange<Date> {
            let calendar = Calendar.current
            guard let firstDate = data.first?.date, let lastDate = data.last?.date else {
                return Date()...Date() // Fallback to current date
            }
            
            // Only extend the last date if the timeFrame is .monthly
            if timeFrame == .monthly {
                let adjustedLastDate = calendar.date(byAdding: .day, value: 1, to: lastDate) ?? lastDate
                return firstDate...adjustedLastDate
            }
            if timeFrame == .sixMonths {
                let adjustedLastDate = calendar.date(byAdding: .day, value: 15, to: lastDate) ?? lastDate
                return firstDate...adjustedLastDate
            }
            if timeFrame == .yearly {
                let adjustedLastDate = calendar.date(byAdding: .month, value: 1, to: lastDate) ?? lastDate
                return firstDate...adjustedLastDate
            }
            else {
                // For other time frames, use the default range from first to last date
                return firstDate...lastDate
            }
        }
    }

#Preview {
    activityView()
}
