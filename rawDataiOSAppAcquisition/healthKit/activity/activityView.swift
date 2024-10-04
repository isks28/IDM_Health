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
    @ObservedObject private var healthKitManager: ActivityManager
    @State private var isRecording = false
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    // State variables to control sheet presentation
    @State private var showingChart: [String: Bool] = [
        "StepCount": false,
        "ActiveEnergy": false,
        "MoveTime": false,
        "StandTime": false,
        "DistanceWalkingRunning": false,
        "ExerciseTime": false
    ]
    
    init() {
        _healthKitManager = ObservedObject(wrappedValue: ActivityManager(startDate: Date(), endDate: Date()))
        _startDate = State(initialValue: Date())
        _endDate = State(initialValue: Date())
    }
    
    var body: some View {
        VStack {
            Text("Activity Health Data")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                
            Text("To be fetched Data:")
                .font(.headline)
                .padding(.top)
            
            ScrollView(.vertical) {
                VStack(spacing: 15) {
                    dataSection(title: "Step Count", dataAvailable: !healthKitManager.stepCountData.isEmpty, chartKey: "StepCount", data: healthKitManager.stepCountData, unit: HKUnit.count(), chartTitle: "Step Count")
                    dataSection(title: "Active Energy Burned", dataAvailable: !healthKitManager.activeEnergyBurnedData.isEmpty, chartKey: "ActiveEnergy", data: healthKitManager.activeEnergyBurnedData, unit: HKUnit.smallCalorie(), chartTitle: "Active Energy Burned in KiloCalorie")
                    dataSection(title: "Move Time", dataAvailable: !healthKitManager.appleMoveTimeData.isEmpty, chartKey: "MoveTime", data: healthKitManager.appleMoveTimeData, unit: HKUnit.second(), chartTitle: "Move Time (s)")
                    dataSection(title: "Stand Time", dataAvailable: !healthKitManager.appleStandTimeData.isEmpty, chartKey: "StandTime", data: healthKitManager.appleStandTimeData, unit: HKUnit.second(), chartTitle: "Stand Time (s)")
                    dataSection(title: "Distance Walking/Running", dataAvailable: !healthKitManager.distanceWalkingRunningData.isEmpty, chartKey: "DistanceWalkingRunning", data: healthKitManager.distanceWalkingRunningData, unit: HKUnit.meter(), chartTitle: "Distance Walking/Running (m)")
                    dataSection(title: "Exercise Time", dataAvailable: !healthKitManager.appleExerciseTimeData.isEmpty, chartKey: "ExerciseTime", data: healthKitManager.appleExerciseTimeData, unit: HKUnit.second(), chartTitle: "Exercise Time (s)")
                }
                .padding(.horizontal)
            }
            
            Text("Set Start and End-Date of Data to be fetched:")
                .font(.headline)
                .foregroundStyle(Color.pink)
            
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                .onChange(of: startDate) {
                    healthKitManager.startDate = startDate
                }
            
            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                .onChange(of: endDate) {
                    healthKitManager.endDate = endDate
                }

            Spacer()

            HStack {
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
                }
                .padding()
                
                if healthKitManager.savedFilePath != nil {
                    Text("File saved")
                        .font(.footnote)
                }
            }
        }
        .padding()
    }
    
    // Modular function for creating data sections
    @ViewBuilder
    private func dataSection(title: String, dataAvailable: Bool, chartKey: String, data: [HKQuantitySample], unit: HKUnit, chartTitle: String) -> some View {
        Section(header: Text(title)) {
            HStack {
                if dataAvailable {
                    Text("\(title) Data is Available")
                        .foregroundStyle(Color.mint)
                        .multilineTextAlignment(.center)
                }
                Button(action: {
                    showingChart[chartKey] = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color.blue)
                }
                .sheet(isPresented: Binding(
                    get: { showingChart[chartKey] ?? false },
                    set: { showingChart[chartKey] = $0 }
                )) {
                    ChartWithTimeFramePicker(title: chartTitle, data: data.map {
                        ChartDataactivity(date: $0.startDate, value: $0.quantity.doubleValue(for: unit))
                    }, startDate: healthKitManager.startDate, endDate: healthKitManager.endDate)
                }
            }
        }
    }
}

struct ChartWithTimeFramePicker: View {
    var title: String
    var data: [ChartDataactivity]
    var startDate: Date
    var endDate: Date

    @State private var selectedTimeFrame: TimeFrame = .daily
    @State private var currentPageForTimeFrames: [TimeFrame: Int] = [
        .daily: 0,
        .weekly: 0,
        .monthly: 0,
        .sixMonths: 0,
        .yearly: 0
    ]

    @State private var showInfoPopover: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var selectedDate: Date = Date()

    // Cache for precomputed data
    @State private var precomputedPageData: [TimeFrame: [Int: [ChartDataactivity]]] = [:]
    @State private var sum: Double = 0
    @State private var average: Double = 0

    var body: some View {
        VStack {
            HStack {
                Text(getInformationText())
                    .font(.subheadline)
                    .padding(.top)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    showInfoPopover.toggle()
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.pink)
                        .padding(.top)
                }
                .popover(isPresented: $showInfoPopover) {
                    popoverContent()
                }
            }
            .padding(.horizontal)
            
            Picker("Time Frame", selection: $selectedTimeFrame) {
                ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                    Text(timeFrame.rawValue).tag(timeFrame)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedTimeFrame) { _, _ in
                updateFilteredData()
            }
            
            Button(action: {
                showDatePicker = true
            }) {
                Text(getTitleForCurrentPage(timeFrame: selectedTimeFrame, page: currentPageForTimeFrames[selectedTimeFrame] ?? 0, startDate: startDate, endDate: endDate))
                    .font(.title2)
            }
            .sheet(isPresented: $showDatePicker) {
                VStack {
                    if selectedTimeFrame == .yearly {
                        // Yearly: Restrict to year-only
                        DatePicker("Select Year", selection: $selectedDate, in: startDate...endDate, displayedComponents: .date)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .onChange(of: selectedDate) { _, newDate in
                                let calendar = Calendar.current
                                if let selectedYear = calendar.dateComponents([.year], from: newDate).year {
                                    // Set the date to January 1st of the selected year
                                    selectedDate = calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1)) ?? newDate
                                    jumpToPage(for: selectedDate)
                                }
                            }
                    } else if selectedTimeFrame == .monthly || selectedTimeFrame == .sixMonths {
                        // Monthly and SixMonths: Restrict to month and year
                        DatePicker("Select Month and Year", selection: $selectedDate, in: startDate...endDate, displayedComponents: [.date])
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .onChange(of: selectedDate) { _, newDate in
                                let calendar = Calendar.current
                                let components = calendar.dateComponents([.year, .month], from: newDate)
                                if let selectedYear = components.year, let selectedMonth = components.month {
                                    // Set the date to the first of the selected month and year
                                    selectedDate = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1)) ?? newDate
                                    jumpToPage(for: selectedDate)
                                }
                            }
                    } else {
                        // Daily and Weekly: Regular Date Picker
                        DatePicker("Select Date", selection: $selectedDate, in: startDate...endDate, displayedComponents: [.date])
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .onChange(of: selectedDate) { _, _ in
                                jumpToPage(for: selectedDate)
                            }
                    }

                    Button("Done") {
                        showDatePicker = false
                    }
                    .foregroundStyle(Color.pink)
                    .padding()
                }
            }

            // Display the metric sum and average
            HStack {
                Text(getTitleForMetric(timeFrame: selectedTimeFrame))
                    .foregroundColor(.primary)
                + Text(": ")
                    .foregroundColor(.primary)
                + Text(getValueText(timeFrame: selectedTimeFrame, sum: sum, average: average))
                    .foregroundColor(.mint)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 25)

            // Use precomputed data for TabView
            TabView(selection: Binding(
                get: { currentPageForTimeFrames[selectedTimeFrame] ?? 0 },
                set: { newValue in
                    currentPageForTimeFrames[selectedTimeFrame] = newValue
                    updateDisplayedData()
                }
            )) {
                if let pageData = precomputedPageData[selectedTimeFrame] {
                    ForEach(0..<getPageCount(for: selectedTimeFrame, startDate: startDate, endDate: endDate), id: \.self) { page in
                        BoxChartViewActivity(data: pageData[page] ?? [], timeFrame: selectedTimeFrame, title: title)
                            .tag(page)
                    }
                } else {
                    Text("No Data")
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .padding(.horizontal)

            Spacer()
        }
        .onAppear {
            updateFilteredData()
        }
    }

    // Precompute data for all pages
    private func updateFilteredData() {
        DispatchQueue.global(qos: .userInitiated).async {
            var newPrecomputedData: [Int: [ChartDataactivity]] = [:]
            let pageCount = getPageCount(for: selectedTimeFrame, startDate: startDate, endDate: endDate)

            for page in 0..<pageCount {
                let filtered = filterAndAggregateDataForPage(data, timeFrame: selectedTimeFrame, page: page, startDate: startDate, endDate: endDate)
                newPrecomputedData[page] = filtered
            }

            let (computedSum, computedAverage) = calculateSumAndAverage(for: selectedTimeFrame, data: newPrecomputedData[currentPageForTimeFrames[selectedTimeFrame] ?? 0] ?? [], startDate: startDate, endDate: endDate, currentPage: currentPageForTimeFrames[selectedTimeFrame] ?? 0)

            DispatchQueue.main.async {
                precomputedPageData[selectedTimeFrame] = newPrecomputedData
                sum = computedSum
                average = computedAverage
            }
        }
    }

    // Update displayed data based on the current page
    private func updateDisplayedData() {
        if let pageData = precomputedPageData[selectedTimeFrame]?[currentPageForTimeFrames[selectedTimeFrame] ?? 0] {
            let (computedSum, computedAverage) = calculateSumAndAverage(for: selectedTimeFrame, data: pageData, startDate: startDate, endDate: endDate, currentPage: currentPageForTimeFrames[selectedTimeFrame] ?? 0)
            sum = computedSum
            average = computedAverage
        }
    }

    private func popoverContent() -> some View {
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
        .frame(width: 300, height: 400)
    }
    
    // Helper function to get the value text
    private func getValueText(timeFrame: TimeFrame, sum: Double, average: Double) -> String {
        if title != "Active Energy Burned in KiloCalorie" && timeFrame == .daily {
            return sum == 0 ? "--" : "\(String(format: "%.0f", sum))"
        } else if title == "Active Energy Burned in KiloCalorie" && timeFrame == .daily {
            return sum == 0 ? "--" : "\(String(format: "%.2f", sum / 1000)) kcal"
        } else if title == "Active Energy Burned in KiloCalorie" && timeFrame != .daily {
            return average == 0 ? "--" : "\(String(format: "%.2f", average / 1000)) kcal"
        } else if title == "Step Count"{
            return average == 0 ? "--" : "\(String(format: "%.0f", average))"
        } else {
            return average == 0 ? "--" : "\(String(format: "%.0f", average))"
        }
    }
    
    private func jumpToPage(for date: Date) {
        let calendar = Calendar.current
        switch selectedTimeFrame {
        case .daily:
            let daysDifference = calendar.dateComponents([.day], from: startDate, to: date).day ?? 0
            currentPageForTimeFrames[selectedTimeFrame] = max(daysDifference, 0)
        case .weekly:
            let weeksDifference = calendar.dateComponents([.weekOfYear], from: startDate, to: date).weekOfYear ?? 0
            currentPageForTimeFrames[selectedTimeFrame] = max(weeksDifference, 0)
        case .monthly:
            let monthsDifference = calendar.dateComponents([.month], from: startDate, to: date).month ?? 0
            currentPageForTimeFrames[selectedTimeFrame] = max(monthsDifference, 0)
        case .sixMonths:
            let monthsDifference = calendar.dateComponents([.month], from: startDate, to: date).month ?? 0
            currentPageForTimeFrames[selectedTimeFrame] = max(monthsDifference / 6, 0)
        case .yearly:
            let yearsDifference = calendar.dateComponents([.year], from: startDate, to: date).year ?? 0
            currentPageForTimeFrames[selectedTimeFrame] = max(yearsDifference, 0)
        }
    }
    
    private func calculateSumAndAverage(for timeFrame: TimeFrame, data: [ChartDataactivity], startDate: Date, endDate: Date, currentPage: Int) -> (sum: Double, average: Double) {
        
        let intervalStartDate: Date = startDate
        let intervalEndDate: Date = endDate

        var totalSum: Double = 0
        var dataPointsCount: Int = 0

        // Filter data within the selected interval and where the value is greater than zero
        let filteredData = data.filter { $0.date >= intervalStartDate && $0.date <= intervalEndDate && $0.value > 0 }

        // Loop through the filtered data to sum values and count data points
        for entry in filteredData {
            // Add the day's value to the total sum
            totalSum += entry.value
            
            // Count this data point
            dataPointsCount += 1
        }

        // Calculate the average based on the number of data points with values
        let average = dataPointsCount > 0 ? totalSum / Double(dataPointsCount) : 0

        print("Data points count: \(dataPointsCount)")
        print("Total Sum: \(totalSum)")

        return (sum: totalSum, average: average)
    }

    private func getTitleForMetric(timeFrame: TimeFrame) -> String {
        let description: String
        
        // Determine the data type and set the title based on the timeframe
        switch title {
        case "Step Count":
            switch timeFrame {
            case .daily:
                description = "Total in this day"
            case .sixMonths:
                description = "Daily average in this six months span"
            case .yearly:
                description = "Daily average in this one year span"
            default:
                description = "Daily average in this time span"
            }
            
        case "Active Energy Burned in KiloCalorie":
            switch timeFrame {
            case .daily:
                description = "Total in this day"
            case .sixMonths:
                description = "Daily average in these six months span"
            case .yearly:
                description = "Daily average in one year span"
            default:
                description = "Daily average in this time span"
            }
            
        case "Move Time (s)":
            switch timeFrame {
            case .daily:
                description = "Total in this day"
            case .sixMonths:
                description = "Daily average in these six months span"
            case .yearly:
                description = "Daily average in one year span"
            default:
                description = "Daily average in this time span"
            }
            
        case "Stand Time (s)":
            switch timeFrame {
            case .daily:
                description = "Total in this day"
            case .sixMonths:
                description = "Daily average in these six months span"
            case .yearly:
                description = "Daily average in one year span"
            default:
                description = "Daily average in this time span"
            }
            
        case "Distance Walking/Running (m)":
            switch timeFrame {
            case .daily:
                description = "Total in this day"
            case .sixMonths:
                description = "Daily average in these six months span"
            case .yearly:
                description = "Daily average in one year span"
            default:
                description = "Daily average in this time span"
            }
            
        case "Exercise Time (s)":
            switch timeFrame {
            case .daily:
                description = "Total in this day"
            case .sixMonths:
                description = "Daily average in these six months span"
            case .yearly:
                description = "Daily average in one year span"
            default:
                description = "Daily average in this time span"
            }
            
        default:
            switch timeFrame {
            case .daily:
                description = "Total in this day"
            case .sixMonths:
                description = "Daily average in these six months span"
            case .yearly:
                description = "Daily average in one year span"
            default:
                description = "Daily average in this time span"
            }
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
            return "RECORDED FROM: iPhone and Apple Watch"
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
    
    private func getPageCount(for timeFrame: TimeFrame, startDate: Date, endDate: Date) -> Int {
        let calendar = Calendar.current
        switch timeFrame {
        case .daily:
            // Calculate days between start and end dates
            let dayDifference = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
            return max(dayDifference + 1, 1) // Ensure at least 1 page
        case .weekly:
            // Calculate weeks between start and end dates
            let weekDifference = calendar.dateComponents([.weekOfYear], from: startDate, to: endDate).weekOfYear ?? 0
            return max(weekDifference + 1, 1) // Ensure at least 1 page
        case .monthly:
            // Calculate months between start and end dates
            let monthDifference = calendar.dateComponents([.month], from: startDate, to: endDate).month ?? 0
            return max(monthDifference + 1, 1) // Ensure at least 1 page
        case .sixMonths:
            // Calculate 6-month intervals between start and end dates
            let monthDifference = calendar.dateComponents([.month], from: startDate, to: endDate).month ?? 0
            return max((monthDifference / 6) + 1, 1) // Ensure at least 1 page
        case .yearly:
            // Calculate years between start and end dates
            let yearDifference = calendar.dateComponents([.year], from: startDate, to: endDate).year ?? 0
            return max(yearDifference, 1) // Ensure at least 1 page
        }
    }
    
    // Function to filter and aggregate data based on the current page and time frame
private func filterAndAggregateDataForPage(_ data: [ChartDataactivity], timeFrame: TimeFrame, page: Int, startDate: Date, endDate: Date) -> [ChartDataactivity] {
        let calendar = Calendar.current
        var filteredData: [ChartDataactivity] = []
        
        switch timeFrame {
        case .daily:
            let pageDate = calendar.date(byAdding: .day, value: page, to: startDate) ?? startDate
            if pageDate <= endDate {
                let hourlyData = aggregateDataByHour(for: pageDate, data: data, endDate: endDate)
                filteredData = hourlyData
            }
            
        case .weekly:
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: calendar.date(byAdding: .weekOfYear, value: page, to: startDate)!)
            let mondayOfWeek = calendar.date(from: components) ?? startDate
            
            let dailyData = (0..<8).map { offset -> ChartDataactivity in
                let date = calendar.date(byAdding: .day, value: offset, to: mondayOfWeek)!
                if offset == 7 {
                return ChartDataactivity(date: date, value: 0)
                            }
                return aggregateDataByDay(for: date, data: data)
            }
            filteredData = dailyData
            
        case .monthly:
            let pageDate = calendar.date(byAdding: .month, value: page, to: startDate) ?? startDate
            
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
            let startOfSixMonths = calendar.date(byAdding: .month, value: (page * 6), to: startDate) ?? startDate
            
            // Aggregate data by day and sum it by week for the 6-month view
            let sixMonthsData = aggregateDataByWeek(for: startOfSixMonths, data: data, weeks: 26)
            filteredData = sixMonthsData

        case .yearly:
            // Subtract the page number to get a 1-year period starting point
            let selectedYear = calendar.component(.year, from: startDate) - page
            let startOfYear = calendar.date(from: DateComponents(year: selectedYear, month: 1))!
            
            // Aggregate data by day and sum it by month for the yearly view
            let yearlyData = aggregateDataByMonth(for: startOfYear, data: data, months: 12)
            filteredData = yearlyData

        }
            
        return filteredData
    }
    
    // Same helper functions as before for aggregating data
    // ...

    private func aggregateDataByHour(for date: Date, data: [ChartDataactivity], endDate: Date) -> [ChartDataactivity] {
        let calendar = Calendar.current
        var hourlyData: [ChartDataactivity] = []

        for hour in 0..<24 {
            let startOfHour = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
            let endOfHour = calendar.date(bySettingHour: hour, minute: 59, second: 59, of: date)!

            // Stop if the hour goes beyond the endDate
            if startOfHour > endDate {
                break
            }

            // Filter data for the current hour
            let filteredData = data.filter { $0.date >= startOfHour && $0.date <= endOfHour }

            // Sum up the values for this hour
            let hourlySum = filteredData.map { $0.value }.reduce(0, +)

            // Append the hourly aggregated data
            hourlyData.append(ChartDataactivity(date: startOfHour, value: hourlySum))
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
            var daysWithData = Set<Date>() // Track unique days with data

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

                    // Add each day in the overlap to the set of days with data
                    var overlapDate = calendar.startOfDay(for: overlapStart)
                    while overlapDate <= overlapEnd {
                        daysWithData.insert(overlapDate)
                        overlapDate = calendar.date(byAdding: .day, value: 1, to: overlapDate)!
                    }
                }
            }

            // Calculate daily average for the week (avoid division by zero)
            let dailyAverage = daysWithData.count > 0 ? weeklyValue / Double(daysWithData.count) : 0.0

            // Append the aggregated data for the current week with the daily average
            weeklyData.append(ChartDataactivity(date: currentWeekStart, value: dailyAverage))
        }

        return weeklyData
    }

    private func aggregateDataByMonth(for startDate: Date, data: [ChartDataactivity], months: Int) -> [ChartDataactivity] {
        let calendar = Calendar.current
        var monthlyData: [ChartDataactivity] = []
        
        for monthOffset in 0..<months {
            // Get the start and end of each month
            let currentMonthStart = calendar.date(byAdding: .month, value: monthOffset, to: startDate)!
            let currentMonthEnd = calendar.date(byAdding: .month, value: 1, to: currentMonthStart)!.addingTimeInterval(-1)
            
            var monthlyValue = 0.0
            var daysWithData = Set<Date>() // Track unique days with data

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

                    // Add each day in the overlap to the set of days with data
                    var overlapDate = calendar.startOfDay(for: overlapStart)
                    while overlapDate <= overlapEnd {
                        daysWithData.insert(overlapDate)
                        overlapDate = calendar.date(byAdding: .day, value: 1, to: overlapDate)!
                    }
                }
            }
            
            // Calculate daily average for the month (avoid division by zero)
            let dailyAverage = daysWithData.count > 0 ? monthlyValue / Double(daysWithData.count) : 0.0

            // Append the aggregated data for the current month with the daily average
            monthlyData.append(ChartDataactivity(date: currentMonthStart, value: dailyAverage))
        }
        
        return monthlyData
    }

    // Function to get the title for the current page based on the time frame
    private func getTitleForCurrentPage(timeFrame: TimeFrame, page: Int, startDate: Date, endDate: Date) -> String {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        var title: String = ""
        
        switch timeFrame {
        case .daily:
            let pageDate = calendar.date(byAdding: .day, value: page, to: startDate) ?? startDate
            dateFormatter.dateStyle = .full
            title = dateFormatter.string(from: pageDate)
            
        case .weekly:
            let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: calendar.date(byAdding: .weekOfYear, value: page, to: startDate)!)?.start ?? startDate
            let currentWeekEnd = calendar.date(byAdding: .day, value: 6, to: currentWeekStart)!
            dateFormatter.dateFormat = "MMM dd"
            title = "\(dateFormatter.string(from: currentWeekStart)) - \(dateFormatter.string(from: currentWeekEnd))"
                
        case .monthly:
            let pageDate = calendar.date(byAdding: .month, value: page, to: startDate) ?? startDate
            dateFormatter.dateFormat = "MMMM yyyy"
            title = dateFormatter.string(from: pageDate)
            
        case .sixMonths:
            let startOfSixMonths = calendar.date(byAdding: .month, value: page * 6, to: startDate) ?? startDate
            let endOfSixMonths = calendar.date(byAdding: .month, value: 5, to: startOfSixMonths) ?? startOfSixMonths
            dateFormatter.dateFormat = "MMM yyyy"
            title = "\(dateFormatter.string(from: startOfSixMonths)) - \(dateFormatter.string(from: endOfSixMonths))"
            
        case .yearly:
            let pageDate = calendar.date(byAdding: .year, value: page, to: startDate) ?? startDate
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
        VStack(alignment: .center) {

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
                .foregroundStyle(Color.pink)
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
                            .offset(x: 5)
                            AxisGridLine()
                        }
                    }
                }
                
                Text(getDynamicTitle())
                    .font(.callout)

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
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .foregroundStyle(Color.primary)
                    }
                }
                .frame(maxHeight: 200) // Restrict the height of the scrollable list
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(25)
    }
    
    // Helper function to get the dynamic title based on data type and time frame
        private func getDynamicTitle() -> String {
            switch title {
            case "Step Count":
                switch timeFrame {
                case .sixMonths:
                    return "Daily average step counts (weekly)"
                case .yearly:
                    return "Daily average step counts (monthly)"
                default:
                    return "Step Counts"
                }
                
            case "Active Energy Burned in KiloCalorie":
                switch timeFrame {
                case .sixMonths:
                    return "6-Month Active Energy Burned in KCal Overview"
                case .yearly:
                    return "Yearly Active Energy Burned in KCal Overview"
                default:
                    return "Active Energy Burned in KCal"
                }
                
            case "Move Time (s)":
                switch timeFrame {
                case .sixMonths:
                    return "6-Month Move Time Overview (seconds)"
                case .yearly:
                    return "Yearly Move Time Overview (seconds)"
                default:
                    return "Move Time in seconds"
                }
                
            case "Stand Time (s)":
                switch timeFrame {
                case .sixMonths:
                    return "6-Month Stand Time Overview (seconds)"
                case .yearly:
                    return "Yearly Stand Time Overview (seconds)"
                default:
                    return "Stand Time in seconds"
                }
                
            case "Distance Walking/Running (m)":
                switch timeFrame {
                case .sixMonths:
                    return "6-Month Distance Walking/Running Overview (meters)"
                case .yearly:
                    return "Yearly Distance Walking/Running Overview (meters)"
                default:
                    return "Distance Walking/Running in meters"
                }
                
            case "Exercise Time (s)":
                switch timeFrame {
                case .sixMonths:
                    return "6-Month Exercise Time Overview (seconds)"
                case .yearly:
                    return "Yearly Exercise Time Overview (seconds)"
                default:
                    return "Exercise Time in seconds"
                }
                
            default:
                switch timeFrame {
                case .sixMonths:
                    return "6-Month Data Overview"
                case .yearly:
                    return "Yearly Data Overview"
                default:
                    return "Data"
                }
            }
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
                return 12.5 // No offset for yearly view
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
