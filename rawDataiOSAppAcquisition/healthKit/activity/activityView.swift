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
    
    @State private var savedFilePath: String? = nil
    
    @State private var showingInfo = false
    // New state to trigger the graph refresh
    @State private var refreshGraph = UUID() // Use UUID for forcing refresh
    
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
            ScrollView(.vertical) {
                VStack(spacing: 10) {
                    dataSection(title: "Step Count", dataAvailable: !healthKitManager.stepCountData.isEmpty, chartKey: "StepCount", data: healthKitManager.stepCountData, unit: HKUnit.count(), chartTitle: "Step Count")
                    dataSection(title: "Active Energy Burned", dataAvailable: !healthKitManager.activeEnergyBurnedData.isEmpty, chartKey: "ActiveEnergy", data: healthKitManager.activeEnergyBurnedData, unit: HKUnit.smallCalorie(), chartTitle: "Active Energy Burned in KiloCalorie")
                    dataSection(title: "Move Time", dataAvailable: !healthKitManager.appleMoveTimeData.isEmpty, chartKey: "MoveTime", data: healthKitManager.appleMoveTimeData, unit: HKUnit.minute(), chartTitle: "Move Time (min)")
                    dataSection(title: "Stand Time", dataAvailable: !healthKitManager.appleStandTimeData.isEmpty, chartKey: "StandTime", data: healthKitManager.appleStandTimeData, unit: HKUnit.minute(), chartTitle: "Stand Time (min)")
                    dataSection(title: "Distance Walking/Running", dataAvailable: !healthKitManager.distanceWalkingRunningData.isEmpty, chartKey: "DistanceWalkingRunning", data: healthKitManager.distanceWalkingRunningData, unit: HKUnit.meter(), chartTitle: "Distance Walking/Running (Km)")
                    dataSection(title: "Exercise Time", dataAvailable: !healthKitManager.appleExerciseTimeData.isEmpty, chartKey: "ExerciseTime", data: healthKitManager.appleExerciseTimeData, unit: HKUnit.minute(), chartTitle: "Exercise Time (min)")
                }
                .padding([.leading, .bottom, .trailing])
            }
            .onAppear {
                print("View appeared, forcing data fetch and refresh")
                // Re-fetch data and force refresh on view appear
                healthKitManager.fetchActivityData(startDate: startDate, endDate: endDate)
                refreshGraph = UUID() // Force refresh with UUID
                
            }
            .onChange(of: healthKitManager.stepCountData) { _, newData in
                print("Step count data changed, forcing graph refresh")
                refreshGraph = UUID() // Force refresh whenever stepCountData changes
            }
            
            Text("Set Start and End-Date to fetched available data:")
                .font(.subheadline)
            
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
                        // Define the server URL
                        let serverURL = ServerConfig.serverURL
                        print("serverURL is \(serverURL)")
                        
                        // Call saveDataAsCSV with the server URL
                        healthKitManager.saveDataAsCSV(serverURL: serverURL)
                    } else {
                        healthKitManager.fetchActivityData(startDate: startDate, endDate: endDate)
                        print("Data fetched, refreshing graph")
                    }
                    isRecording.toggle()
                }) {
                    Text(isRecording ? "Save and Upload Data" : "Fetch Data")
                        .padding()
                        .background(isRecording ? Color.secondary : Color.blue)
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
        .navigationTitle("Activity Health Data")
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
                        Text("Data Information")
                            .font(.largeTitle)
                        Text("Start and End date can only fetch the history or collected data from iOS Health App and not collecting future or unrecorded data.")
                            .font(.body)
                            .padding()
                            .padding()
                            .foregroundStyle(Color.primary)
                        Spacer()
                        // Adding a chevron as a swipe indicator
                        AnimatedSwipeDownCloseView()
                    }
                    .padding()
                }
            }
        }
    }
    
    // Modular function for creating data sections
    @ViewBuilder
    private func dataSection(title: String, dataAvailable: Bool, chartKey: String, data: [HKQuantitySample], unit: HKUnit, chartTitle: String) -> some View {
        Section(header: Text(title)
            .font(.title3)) {
            HStack {
                if !isRecording {
                    
                } else {
                    // Show data availability information after fetching data
                    if dataAvailable {
                        Button(action: {
                            showingChart[chartKey] = true
                        }) {
                            Text("\(title) Data is Available")
                                .font(.footnote)
                                .foregroundStyle(Color.blue)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        Text("\(title) Data is not Available")
                            .font(.footnote)
                            .foregroundStyle(Color.pink)
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
                            .id(refreshGraph) // Force refresh with UUID to ensure the view is recreated
                    }
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

    @State private var selectedTimeFrame: TimeFrame = .sixMonths
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
    
    @State private var refreshGraph = UUID()

    // Cache for precomputed data
    @State private var precomputedPageData: [TimeFrame: [Int: [ChartDataactivity]]] = [:]
    @State private var sum: Double = 0
    @State private var average: Double = 0

    var body: some View {
        VStack {
            HStack {
                Text(getInformationText())
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .padding(2)
                    .padding(.top, 5)
                
                Button(action: {
                    showInfoPopover.toggle()
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                        .padding(.bottom, 2)
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
            
            HStack {
                Text(getTitleForMetric(timeFrame: selectedTimeFrame))
                    .font(.footnote)
                    .foregroundColor(.primary)
                
                Button(action: {
                    showDatePicker = true
                }) {
                    Text(getTitleForCurrentPage(timeFrame: selectedTimeFrame, page: currentPageForTimeFrames[selectedTimeFrame] ?? 0, startDate: startDate, endDate: endDate))
                        .foregroundColor(.blue)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(.white)
                        .cornerRadius(25)
                        .overlay(  // Adding black outline
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.blue, lineWidth: 2)  // Outline color and width
                        )
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
                                    let timeZone = TimeZone.current
                                    
                                    // Log the selected date before any modification
                                    print("Newly selected date before any adjustments: \(newDate)")
                                    
                                    // Get the year and month of the selected date directly
                                    var components = calendar.dateComponents([.year, .month], from: newDate)
                                    
                                    if let selectedYear = components.year, let selectedMonth = components.month {
                                        
                                        // Log the components before setting the new date
                                        print("Selected Year: \(selectedYear), Selected Month: \(selectedMonth)")
                                        
                                        // Force the selected date to be the 1st of the month and set the time to midday (to avoid time zone issues)
                                        components.day = 1
                                        components.hour = 23
                                        components.minute = 0
                                        components.second = 0
                                        components.timeZone = timeZone
                                        
                                        if let adjustedDate = calendar.date(from: components) {
                                            selectedDate = adjustedDate
                                            jumpToPage(for: selectedDate)
                                        }
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
                            refreshGraph = UUID()
                        }
                        .foregroundStyle(Color.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                }
                
                Text(": ")
                    .foregroundColor(.primary)
                
                Text(getValueText(timeFrame: selectedTimeFrame, sum: sum, average: average))
                    .foregroundColor(.pink)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 5)
            
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
                            .tag(page) // Ensure each page has a unique tag of type Int
                            .id(refreshGraph) // Force refresh of the chart when graph data is updated
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
            // Ensure the data is updated and visible upon initial appearance
            DispatchQueue.main.async {
                updateFilteredData() // Precompute and update the data before displaying
                jumpToPage(for: endDate) // Jump to the appropriate page
                
                // Trigger a refresh manually after the data has been fetched and displayed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    refreshGraph = UUID() // Force a chart redraw on appear
                }
            }
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
                .foregroundStyle(Color.primary)
            Text(measuredUsing())
                .font(.body)
                .padding(.bottom, 3)
            Text(useCase())
                .font(.body)
                .padding(.bottom, 3)
            Text("For more information, go to:")
                .font(.title3)
                .padding(.bottom, 3)
                .foregroundStyle(Color.secondary)
            Text("https://dimesociety.org/library-of-digital-endpoints/")
                .font(.body)
                .padding(.bottom, 3)
        }
        .frame(width: 300, height: 400)
    }
    
    // Helper function to get the unit for the metric based on the title
    private func getUnitForMetric(title: String) -> String {
        switch title {
        case "Step Count":
            return "Steps"
        case "Active Energy Burned in KiloCalorie":
            return "KCal"
        case "Move Time (min)", "Stand Time (min)", "Exercise Time (min)":
            return "Minutes"
        case "Distance Walking/Running (Km)":
            return "Kilometers"
        default:
            return ""
        }
    }

    // Helper function to get the value text
    private func getValueText(timeFrame: TimeFrame, sum: Double, average: Double) -> String {
        let unit = getUnitForMetric(title: title) // Get the unit based on the title
        
        switch (title, timeFrame) {
        case ("Active Energy Burned in KiloCalorie", .daily):
            return sum == 0 ? "-- \(unit)" : "\(String(format: "%.1f", sum / 1000)) \(unit)"
            
        case ("Active Energy Burned in KiloCalorie", _):
            return average == 0 ? "-- \(unit)" : "\(String(format: "%.0f", average / 1000)) \(unit)"
            
        case ("Step Count", _):
            return average == 0 ? "-- \(unit)" : "\(String(format: "%.0f", average)) \(unit)"
            
        case ("Distance Walking/Running (Km)", .daily):
            return sum == 0 ? "-- \(unit)" : "\(String(format: "%.2f", sum / 1000)) \(unit)"
            
        case ("Distance Walking/Running (Km)", _):
            return average == 0 ? "-- \(unit)" : "\(String(format: "%.1f", average / 1000)) \(unit)"
            
        default:
            return average == 0 ? "-- \(unit)" : "\(String(format: "%.0f", average)) \(unit)"
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
                description = "Total in "
            case .weekly:
                description = "Average from "
            case .sixMonths:
                description = "Daily average from "
            case .yearly:
                description = "Daily average in "
            default:
                description = "Average in "
            }
            
        case "Active Energy Burned in KiloCalorie":
            switch timeFrame {
            case .daily:
                description = "Total in "
            case .weekly:
                description = "Average from "
            case .sixMonths:
                description = "Daily average from "
            case .yearly:
                description = "Daily average in "
            default:
                description = "Average in "
            }
            
        case "Move Time (min)":
            switch timeFrame {
            case .daily:
                description = "Total in "
            case .weekly:
                description = "Average from "
            case .sixMonths:
                description = "Daily average from "
            case .yearly:
                description = "Daily average in "
            default:
                description = "Average in "
            }
            
        case "Stand Time (min)":
            switch timeFrame {
            case .daily:
                description = "Total in "
            case .weekly:
                description = "Average from "
            case .sixMonths:
                description = "Daily average from "
            case .yearly:
                description = "Daily average in "
            default:
                description = "Average in "
            }
            
        case "Distance Walking/Running (Km)":
            switch timeFrame {
            case .daily:
                description = "Total in "
            case .weekly:
                description = "Average from "
            case .sixMonths:
                description = "Daily average from "
            case .yearly:
                description = "Daily average in "
            default:
                description = "Average in "
            }
            
        case "Exercise Time (min)":
            switch timeFrame {
            case .daily:
                description = "Total in "
            case .weekly:
                description = "Average from "
            case .sixMonths:
                description = "Daily average from "
            case .yearly:
                description = "Daily average in "
            default:
                description = "Average in "
            }
            
        default:
            switch timeFrame {
            case .daily:
                description = "Total in "
            case .weekly:
                description = "Average from "
            case .sixMonths:
                description = "Daily average from "
            case .yearly:
                description = "Daily average in "
            default:
                description = "Average in "
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
            return "Energy burned through physical activity, excluding Energy burned at Rest (basal metabolic rate)"
        case "Move Time (min)":
            return "Time spent performing activities that involve full-body movements"
        case "Stand Time (min)":
            return "Time has spent standing"
        case "Distance Walking/Running (Km)":
            return "Distance the user has moved by walking or running"
        case "Exercise Time (min)":
            return "Time that the user has spent exercising"
        default:
            return "Data not available."
        }
    }
    
    // Helper function for detailed popover information
    private func measuredUsing() -> String {
        switch title {
        case "Step Count":
            return "MEASURED USING: iPhone or Apple Watch"
        case "Active Energy Burned in KiloCalorie":
            return "MEASURED USING: Apple Watch"
        case "Move Time (min)":
            return "MEASURED USING: Apple Watch and/or iPhone"
        case "Stand Time (min)":
            return "MEASURED USING: Apple Watch"
        case "Distance Walking/Running (Km)":
            return "MEASURED USING: iPhone and Apple Watch"
        case "Exercise Time (min)":
            return "MEASURED USING: Apple Watch"
        default:
            return "More information about this section is not available."
        }
    }
    private func useCase() -> String {
        switch title {
        case "Step Count":
            return "USE CASE: Cardiovascular Diseases, Diabetes, Parkinson Diseases, Musculoskeletal Issues such as Arthritis"
        case "Active Energy Burned in KiloCalorie":
            return "USE CASE: Managing weight, Metabolic conditions, Diabetes and Cardiovascular disease"
        case "Move Time (min)":
            return "USE CASE: Cardiovascular disease, Obesity and Diabetes"
        case "Stand Time (min)":
            return "USE CASE: Prolonged sitting, Cardiovascular disease, Diabetes and obesity"
        case "Distance Walking/Running (Km)":
            return "USE CASE: Cardiovascular disease, Rehabilitation after surgery and Diabetes"
        case "Exercise Time (min)":
            return "USE CASE: Cardiovascular disease, Obesity, Diabetes and Mental health disorders"
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
    @State private var isLoading: Bool = true // Flag for loading state

    var body: some View {
        VStack(alignment: .center) {

            if isLoading {
                VStack {
                    ProgressView() // Display the progress spinner
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(2) // Optional: make the progress view bigger
                        .padding()
                    
                    Text("Fetching Data...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .onAppear {
                    // Simulate a loading delay or wait for actual data fetching logic
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isLoading = false // Set to false when loading is complete
                    }
                }
            } else if data.allSatisfy({ $0.value == 0 }) {
                Text("No Data")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                Chart {
                    ForEach(data) { item in
                        BarMark(
                            x: .value("Date", item.date),
                            y: .value("Value", (title == "Active Energy Burned in KiloCalorie" || title == "Distance Walking/Running (Km)") ? item.value / 1000 : item.value)
                        )
                        .offset(x: getOffsetForTimeFrame(timeFrame))
                    }
                }
                .id(UUID()) // Force re-render whenever data changes
                .foregroundStyle(Color.primary)
                .chartXScale(domain: getXScaleDomain())
                .chartXAxis {
                    switch timeFrame {
                    case .daily:
                        AxisMarks(values: .automatic(desiredCount: 4)) { value in
                            AxisValueLabel(format: .dateTime.hour())
                            AxisGridLine()
                        }

                    case .weekly:
                        AxisMarks(values: .automatic(desiredCount: 7)) { value in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                .offset(x: 5)
                            AxisGridLine()
                        }

                    case .monthly:
                        AxisMarks(values: .automatic) { value in
                            AxisValueLabel(format: .dateTime.day())
                                .offset(x: -(2))
                            AxisGridLine()
                        }

                    case .sixMonths:
                        AxisMarks(values: .stride(by: .month)) { value in
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                                .offset(x: 8)
                            AxisGridLine()
                        }

                    case .yearly:
                        AxisMarks(values: .automatic(desiredCount: 12)) { value in
                            AxisValueLabel(format:
                                .dateTime.month(.narrow))
                            .offset(x: 5)
                            AxisGridLine()
                        }
                    }
                }

                ScrollView {
                    ForEach(timeFrame == .weekly ? Array(data.prefix(7)) : data) { item in
                        HStack {
                            Text(formatDateForTimeFrame(item.date)) // Display date formatted based on time frame
                            Spacer()
                            
                            if title == "Active Energy Burned in KiloCalorie" {
                                VStack {
                                    // Check the time frame and display either "Daily average" or "Total"
                                    if timeFrame == .yearly || timeFrame == .sixMonths {
                                        Text("Daily average")
                                            .font(.caption2)
                                    } else if timeFrame == .monthly || timeFrame == .weekly || timeFrame == .daily {
                                        Text("Total")
                                            .font(.caption2)
                                    }

                                    // Display the value and the unit (kcal)
                                    HStack {
                                        Text(item.value == 0 ? "--" : "\(String(format: "%.0f", item.value / 1000))")
                                        Text("kcal")
                                    }
                                }
                            }
                            
                            if title == "Step Count" {
                                VStack {
                                    // Check the time frame and display either "Daily average" or "Total"
                                    if timeFrame == .yearly || timeFrame == .sixMonths {
                                        Text("Daily average")
                                            .font(.caption2)
                                    } else if timeFrame == .monthly || timeFrame == .weekly || timeFrame == .daily {
                                        Text("Total")
                                            .font(.caption2)
                                    }

                                    // Display the value and the unit (Steps)
                                    HStack {
                                        Text(item.value == 0 ? "--" : "\(String(format: "%.0f", item.value))")
                                        Text("Steps")
                                    }
                                }
                            }
                            
                            if title == "Move Time (min)" {
                                VStack {
                                    if timeFrame == .yearly || timeFrame == .sixMonths {
                                        Text("Daily average")
                                            .font(.caption2)
                                    } else {
                                        Text("Total")
                                            .font(.caption2)
                                    }

                                    // Display the value and the unit (Minutes)
                                    HStack {
                                        Text(item.value == 0 ? "--" : "\(String(format: "%.0f", item.value))")
                                        Text("Minutes")
                                    }
                                }
                            }
                            
                            if title == "Stand Time (min)" {
                                VStack {
                                    if timeFrame == .yearly || timeFrame == .sixMonths {
                                        Text("Daily average")
                                            .font(.caption2)
                                    } else {
                                        Text("Total")
                                            .font(.caption2)
                                    }

                                    // Display the value and the unit (Minutes)
                                    HStack {
                                        Text(item.value == 0 ? "--" : "\(String(format: "%.0f", item.value))")
                                        Text("Minutes")
                                    }
                                }
                            }
                            
                            if title == "Distance Walking/Running (Km)" {
                                VStack {
                                    if timeFrame == .yearly || timeFrame == .sixMonths {
                                        Text("Daily average")
                                            .font(.caption2)
                                    } else {
                                        Text("Total")
                                            .font(.caption2)
                                    }

                                    // Display the value and the unit (Kilometers)
                                    HStack {
                                        Text(item.value == 0 ? "--" : "\(String(format: "%.2f", item.value / 1000))")
                                        Text("Kilometers")
                                    }
                                }
                            }
                            
                            if title == "Exercise Time (min)" {
                                VStack {
                                    if timeFrame == .yearly || timeFrame == .sixMonths {
                                        Text("Daily average")
                                            .font(.caption2)
                                    } else {
                                        Text("Total")
                                            .font(.caption2)
                                    }

                                    // Display the value and the unit (Minutes)
                                    HStack {
                                        Text(item.value == 0 ? "--" : "\(String(format: "%.0f", item.value))")
                                        Text("Minutes")
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .foregroundStyle(Color.primary)
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(25)
        .onAppear {
            print("BoxChartViewActivity appeared with new data") // Debugging log
        }
    }
    
    // Helper function to get the dynamic title based on data type and time frame
//        private func getDynamicTitle() -> String {
//            switch title {
//            case "Step Count":
//                switch timeFrame {
//                case .sixMonths:
//                    return "Daily average step counts (weekly)"
//                case .yearly:
//                    return "Daily average step counts (monthly)"
//                default:
//                    return "Total Step Counts"
//                }
//                
//            case "Active Energy Burned in KiloCalorie":
//                switch timeFrame {
//                case .sixMonths:
//                    return "Daily average Active energy burned (weekly)"
//                case .yearly:
//                    return "Daily average Active energy burned (monthly)"
//                default:
//                    return "Active Energy Burned in KCal"
//                }
//                
//            case "Move Time (min)":
//                switch timeFrame {
//                case .sixMonths:
//                    return "Daily average Move time (weekly)"
//                case .yearly:
//                    return "Daily average Move time (monthly)"
//                default:
//                    return "Move Time in seconds"
//                }
//                
//            case "Stand Time (min)":
//                switch timeFrame {
//                case .sixMonths:
//                    return "Daily average Stand time (weekly)"
//                case .yearly:
//                    return "Daily average Stand time (monthly)"
//                default:
//                    return "Stand Time in seconds"
//                }
//                
//            case "Distance Walking/Running (Km)":
//                switch timeFrame {
//                case .sixMonths:
//                    return "Daily average Distance Walking/Running (weekly)"
//                case .yearly:
//                    return "Daily average Distance Walking/Running (monthly)"
//                default:
//                    return "Distance Walking/Running in meters"
//                }
//                
//            case "Exercise Time (min)":
//                switch timeFrame {
//                case .sixMonths:
//                    return "Daily average Exercise time (weekly)"
//                case .yearly:
//                    return "Daily average Exercise time (monthly)"
//                default:
//                    return "Exercise Time in seconds"
//                }
//                
//            default:
//                switch timeFrame {
//                case .sixMonths:
//                    return "6-Month Data Overview"
//                case .yearly:
//                    return "Yearly Data Overview"
//                default:
//                    return "Data"
//                }
//            }
//        }
    
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
            return "\(startHour) - \(endHour)"
        
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
