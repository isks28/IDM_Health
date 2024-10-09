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

enum TimeFrameMobility: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case sixMonths = "6 Months"
    case yearly = "Yearly"
}

struct mobilityView: View {
    @StateObject private var healthKitManager = HealthKitMobilityManager(startDate: Date(), endDate: Date())
    @State private var isRecording = false
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    // State variables to control sheet presentation
    @State private var showingChart: [String: Bool] = [
        "WalkingDoubleSupport": false,
        "WalkingAsymmetry": false,
        "WalkingSpeed": false,
        "WalkingStepLength": false,
        "WalkingSteadiness": false
    ]
    
    init() {
        _healthKitManager = StateObject(wrappedValue: HealthKitMobilityManager(startDate: Date(), endDate: Date()))
        _startDate = State(initialValue: Date())
        _endDate = State(initialValue: Date())
    }
    
    var body: some View {
        VStack {
            Text("Mobility Health Data")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            ScrollView(.vertical) {
                VStack(spacing: 10) {
                    dataSection(title: "Walking Double Support", dataAvailable: !healthKitManager.walkingDoubleSupportData.isEmpty, chartKey: "WalkingDoubleSupport", data: healthKitManager.walkingDoubleSupportData, unit: HKUnit.percent(), chartTitle: "Walking Double Support")
                    
                    dataSection(title: "Walking Asymmetry", dataAvailable: !healthKitManager.walkingAsymmetryData.isEmpty, chartKey: "WalkingAsymmetry", data: healthKitManager.walkingAsymmetryData, unit: HKUnit.percent(), chartTitle: "Walking Asymmetry")
                    
                    dataSection(title: "Walking Speed", dataAvailable: !healthKitManager.walkingSpeedData.isEmpty, chartKey: "WalkingSpeed", data: healthKitManager.walkingSpeedData, unit: HKUnit.meter().unitDivided(by: HKUnit.second()), chartTitle: "Walking Speed")
                    
                    dataSection(title: "Walking Step Length", dataAvailable: !healthKitManager.walkingStepLengthData.isEmpty, chartKey: "WalkingStepLength", data: healthKitManager.walkingStepLengthData, unit: HKUnit.meter(), chartTitle: "Walking Step Length")
                    
                    dataSection(title: "Walking Steadiness", dataAvailable: !healthKitManager.walkingSteadinessData.isEmpty, chartKey: "WalkingSteadiness", data: healthKitManager.walkingSteadinessData, unit: HKUnit.percent(), chartTitle: "Walking Steadiness")
                }
                .padding()
            }
            
            Text("Set Start and End-Date of Data to be fetched:")
                .font(.headline)
            
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
                        healthKitManager.fetchMobilityData(startDate: startDate, endDate: endDate)
                    }
                    isRecording.toggle()
                }) {
                    Text(isRecording ? "Save Data" : "Fetch Data")
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
    }
    
    // Modular function for creating data sections
    @ViewBuilder
    private func dataSection(title: String, dataAvailable: Bool, chartKey: String, data: [MobilityStatistics], unit: HKUnit, chartTitle: String) -> some View {
        Section(header: Text(title)
            .font(.title3)) {
            HStack {
                if !isRecording {
                    // Show this message if the "Fetch Data" button hasn't been clicked
                    Text("Set the date to fetch data")
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
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
                        ChartWithTimeFrameMobilityPicker(title: chartTitle, data: data.map {
                            ChartDataMobility(date: $0.endDate, minValue: $0.minValue, maxValue: $0.maxValue, value: $0.averageValue)
                        },
                        startDate: healthKitManager.startDate,
                        endDate: healthKitManager.endDate)
                    }
                }
            }
        }
    }
}

struct ChartWithTimeFrameMobilityPicker: View {
    var title: String
    var data: [ChartDataMobility]
    var startDate: Date
    var endDate: Date

    @State private var selectedTimeFrameMobility: TimeFrameMobility = .daily
    @State private var currentPageForTimeFrameMobilitys: [TimeFrameMobility: Int] = [
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
    @State private var precomputedPageData: [TimeFrameMobility: [Int: [ChartDataMobility]]] = [:]
    @State private var minValue: Double = 0
    @State private var maxValue: Double = 0

    var body: some View {
        VStack {
            HStack {
                Text(getInformationText())
                    .font(.headline)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .padding(2)
                    .padding(.top, 5)
                
                Button(action: {
                    showInfoPopover.toggle()
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .padding(.vertical)
                }
                .popover(isPresented: $showInfoPopover) {
                    popoverContent()
                }
            }
            .padding(.horizontal)
            
            Picker("Time Frame", selection: $selectedTimeFrameMobility) {
                ForEach(getAvailableTimeFrames(for: title), id: \.self) { timeFrame in
                    Text(timeFrame.rawValue).tag(timeFrame)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedTimeFrameMobility) { _, _ in
                updateFilteredData()
            }
            
            Button(action: {
                showDatePicker = true
            }) {
                Text(getTitleForCurrentPage(TimeFrameMobility: selectedTimeFrameMobility, page: currentPageForTimeFrameMobilitys[selectedTimeFrameMobility] ?? 0, startDate: startDate, endDate: endDate))
                    .font(.title2)
            }
            .sheet(isPresented: $showDatePicker) {
                VStack {
                    if selectedTimeFrameMobility == .yearly {
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
                    } else if selectedTimeFrameMobility == .monthly || selectedTimeFrameMobility == .sixMonths {
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
                                        
                                        // Log the newly adjusted date
                                        print("Adjusted Date to first of the month: \(adjustedDate)")
                                        
                                        // Update the selected date and jump to the corresponding page
                                        selectedDate = adjustedDate
                                        jumpToPage(for: selectedDate)
                                    } else {
                                        print("Failed to adjust the date correctly.")
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
                    }
                    .foregroundStyle(Color.white)
                    .padding() // Add padding inside the button to make the text area larger
                    .background(Color.blue) // Set background color
                    .cornerRadius(8) // Round the corners
                    .padding(.horizontal, 20) // Add horizontal padding to make the button wider
                    .padding(.vertical, 10) // Add vertical padding to make the button taller
                }
            }

            // Display the metric sum and average
            HStack {
                Text(getTitleForMetric(TimeFrameMobility: selectedTimeFrameMobility, minValue: minValue, maxValue: maxValue))
                    .foregroundColor(.primary)
                + Text(": ")
                    .foregroundColor(.primary)
                + Text(getValueText(timeFrame: selectedTimeFrameMobility, minValue: minValue, maxValue: maxValue))
                    .foregroundColor(.pink)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 25)

            // Use precomputed data for TabView
            TabView(selection: Binding(
                get: { currentPageForTimeFrameMobilitys[selectedTimeFrameMobility] ?? 0 },
                set: { newValue in
                    currentPageForTimeFrameMobilitys[selectedTimeFrameMobility] = newValue
                    updateDisplayedData()
                }
            )) {
                if let pageData = precomputedPageData[selectedTimeFrameMobility] {
                    ForEach(0..<getPageCount(for: selectedTimeFrameMobility, startDate: startDate, endDate: endDate), id: \.self) { page in
                        BoxChartViewMobility(data: pageData[page] ?? [], timeFrame: selectedTimeFrameMobility, title: title)
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
            selectedDate = endDate
            jumpToPage(for: endDate)
        }
    }
    
    private func getAvailableTimeFrames(for title: String) -> [TimeFrameMobility] {
        if title == "Walking Steadiness" {
            // Exclude .daily and .weekly for "Walking Steadiness"
            return TimeFrameMobility.allCases.filter { $0 != .daily && $0 != .weekly }
        } else {
            // Return all time frames for other titles
            return TimeFrameMobility.allCases
        }
    }

    // Precompute data for all pages
    private func updateFilteredData() {
        DispatchQueue.global(qos: .userInitiated).async {
            var newPrecomputedData: [Int: [ChartDataMobility]] = [:]
            let pageCount = getPageCount(for: selectedTimeFrameMobility, startDate: startDate, endDate: endDate)

            // Loop over each page and compute the data for it
            for page in 0..<pageCount {
                let filtered = filterAndAggregateDataForPage(data, timeFrame: selectedTimeFrameMobility, page: page, startDate: startDate, endDate: endDate)
                newPrecomputedData[page] = filtered
            }

            // Compute min and max for the current page
            let (computedMinValue, computedMaxValue) = calculateMinMax(
                for: selectedTimeFrameMobility,
                data: newPrecomputedData[currentPageForTimeFrameMobilitys[selectedTimeFrameMobility] ?? 0] ?? [],
                startDate: startDate,
                endDate: endDate,
                currentPage: currentPageForTimeFrameMobilitys[selectedTimeFrameMobility] ?? 0
            )

            // Update state on the main thread
            DispatchQueue.main.async {
                precomputedPageData[selectedTimeFrameMobility] = newPrecomputedData
                minValue = computedMinValue
                maxValue = computedMaxValue
            }
        }
    }

    // Update displayed data based on the current page
    private func updateDisplayedData() {
        if let pageData = precomputedPageData[selectedTimeFrameMobility]?[currentPageForTimeFrameMobilitys[selectedTimeFrameMobility] ?? 0] {
            let (computedMinValue, computedMaxValue) = calculateMinMax(for: selectedTimeFrameMobility, data: pageData, startDate: startDate, endDate: endDate, currentPage: currentPageForTimeFrameMobilitys[selectedTimeFrameMobility] ?? 0)
            minValue = computedMinValue
            maxValue = computedMaxValue
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
            Text("For more information, go to:")
                .font(.title3)
                .padding(.bottom, 3)
                .foregroundStyle(Color.mint)
            Text("https://dimesociety.org/library-of-digital-endpoints/")
                .font(.body)
                .padding(.bottom, 3)
        }
        .frame(width: 300, height: 400)
    }
    
    private func getUnitForMetric(title: String) -> String {
        switch title {
        case "Walking Double Support", "Walking Asymmetry", "Walking Steadiness":
            return "%"
        case "Walking Speed":
            return "km/h"
        case "Walking Step Length":
            return "cm"
        default:
            return ""
        }
    }

    private func getValueText(timeFrame: TimeFrameMobility, minValue: Double, maxValue: Double) -> String {
        let unit = getUnitForMetric(title: title) // Get the unit based on the title

        // Check if both minValue and maxValue are 0, return "--" if true
        guard minValue != 0 || maxValue != 0 else {
            return "-- \(unit)"
        }
        
        // If minValue equals maxValue, return only minValue
        if minValue == maxValue {
            return "\(String(format: "%.1f", minValue)) \(unit)"
        }

        // Return formatted string showing the range between minValue and maxValue
        return "\(String(format: "%.1f", minValue))-\(String(format: "%.1f", maxValue)) \(unit)"
    }
    
    private func jumpToPage(for date: Date) {
        let calendar = Calendar.current
        switch selectedTimeFrameMobility {
        case .daily:
            let daysDifference = calendar.dateComponents([.day], from: startDate, to: date).day ?? 0
            currentPageForTimeFrameMobilitys[selectedTimeFrameMobility] = max(daysDifference, 0)
        case .weekly:
            let weeksDifference = calendar.dateComponents([.weekOfYear], from: startDate, to: date).weekOfYear ?? 0
            currentPageForTimeFrameMobilitys[selectedTimeFrameMobility] = max(weeksDifference, 0)
        case .monthly:
            let monthsDifference = calendar.dateComponents([.month], from: startDate, to: date).month ?? 0
            currentPageForTimeFrameMobilitys[selectedTimeFrameMobility] = max(monthsDifference, 0)
        case .sixMonths:
            let monthsDifference = calendar.dateComponents([.month], from: startDate, to: date).month ?? 0
            currentPageForTimeFrameMobilitys[selectedTimeFrameMobility] = max(monthsDifference / 6, 0)
        case .yearly:
            let yearsDifference = calendar.dateComponents([.year], from: startDate, to: date).year ?? 0
            currentPageForTimeFrameMobilitys[selectedTimeFrameMobility] = max(yearsDifference, 0)
        }
    }
        
    private func calculateMinMax(for timeFrame: TimeFrameMobility, data: [ChartDataMobility], startDate: Date, endDate: Date, currentPage: Int) -> (minValue: Double, maxValue: Double) {
        // Filter out zero values when computing the minimum
        let nonZeroData = data.filter { $0.minValue > 0 }

        // Calculate min and max from non-zero values
        let minValue = nonZeroData.map { $0.minValue }.min() ?? 0.0
        let maxValue = data.map { $0.maxValue }.max() ?? 0.0

        return (minValue, maxValue)
    }

    private func getTitleForMetric(TimeFrameMobility: TimeFrameMobility, minValue: Double, maxValue: Double) -> String {
        let description: String
        let rangeOrValue = (minValue == maxValue) ? "Value" : "Range"  // Switch between "Range" and "Value"
        
        // Determine the data type and set the title based on the TimeFrameMobility and the min/max values
        switch title {
        case "Walking Double Support":
            switch TimeFrameMobility {
            case .daily:
                description = "\(rangeOrValue) in this day"
            case .weekly:
                description = "\(rangeOrValue) in this week"
            case .monthly:
                description = "\(rangeOrValue) in this month"
            case .sixMonths:
                description = "\(rangeOrValue) in these 6 months span"
            case .yearly:
                description = "\(rangeOrValue) in this year"
            }
            
        case "Walking Asymmetry":
            switch TimeFrameMobility {
            case .daily:
                description = "\(rangeOrValue) in this day"
            case .weekly:
                description = "\(rangeOrValue) in this week"
            case .monthly:
                description = "\(rangeOrValue) in this month"
            case .sixMonths:
                description = "\(rangeOrValue) in these 6 months span"
            case .yearly:
                description = "\(rangeOrValue) in this year"
            }
            
        case "Walking Step Length":
            switch TimeFrameMobility {
            case .daily:
                description = "\(rangeOrValue) in this day"
            case .weekly:
                description = "\(rangeOrValue) in this week"
            case .monthly:
                description = "\(rangeOrValue) in this month"
            case .sixMonths:
                description = "\(rangeOrValue) in these 6 months span"
            case .yearly:
                description = "\(rangeOrValue) in this year"
            }
            
        case "Walking Steadiness":
            switch TimeFrameMobility {
            case .daily:
                description = "\(rangeOrValue) in this day"
            case .weekly:
                description = "\(rangeOrValue) in this week"
            case .monthly:
                description = "\(rangeOrValue) in this month"
            case .sixMonths:
                description = "\(rangeOrValue) in these 6 months span"
            case .yearly:
                description = "\(rangeOrValue) in this year"
            }
            
        default:
            switch TimeFrameMobility {
            case .daily:
                description = "\(rangeOrValue) in this day"
            case .weekly:
                description = "\(rangeOrValue) in this week"
            case .monthly:
                description = "\(rangeOrValue) in this month"
            case .sixMonths:
                description = "\(rangeOrValue) in these 6 months span"
            case .yearly:
                description = "\(rangeOrValue) in this year"
            }
        }
        
        return description
    }
    
    // Helper function to display different text based on the selected data section
    private func getInformationText() -> String {
        switch title {
        case "Walking Double Support":
            return "Percentage of time when both of the user's feet touch the ground while walking steadily over flat ground"
        case "Walking Asymmetry":
            return "Percentage of steps in which one foot moves at a different speed than the other when walking on flat ground"
        case "Walking Speed":
            return "Speed when walking steadily over flat ground"
        case "Walking Step Length":
            return "Distance between your front foot and back foot when you're walking"
        case "Walking Steadiness":
            return "Steadiness of the gait calculated using walking speed, step length, double support time and wlaking asymmetry data"
        default:
            return "Data not available."
        }
    }
    
    // Helper function for detailed popover information
    private func measuredUsing() -> String {
        switch title {
        case "Walking Double Support":
            return "MEASURED USING: iPhone"
        case "Walking Asymmetry":
            return "MEASURED USING: iPhone and Apple Watch"
        case "Walking Speed":
            return "MEASURED USING: iPhone and Apple Watch"
        case "Walking Step Length":
            return "MEASURED USING: iPhone and Apple Watch"
        case "Walking Steadiness":
            return "MEASURED USING: iPhone and Apple Watch"
        default:
            return "Data not available."
        }
    }
    
    private func useCase() -> String {
        switch title {
        case "Walking Double Support":
            return "USE CASE: Parkinson, Stroke recovery and Musculoskeletal diseases"
        case "Walking Asymmetry":
            return "USE CASE: Neurological conditions, Stroke recovery, Sklerosis and Knee injuries"
        case "Walking Speed":
            return "USE CASE: Fraility, Parkinson, Sklerosis, Post surgical recovery and 6 minute walk test"
        case "Walking Step Length":
            return "USE CASE: Parkinson, Stroke recovery, Musculoskeletal issues and Age-related mobility decline"
        case "Walking Steadiness":
            return "USE CASE: Balance disorders, Parkinson, Sklerosis and Stroke recovery"
        default:
            return "Data not available."
        }
    }
}
    
    private func getPageCount(for TimeFrameMobility: TimeFrameMobility, startDate: Date, endDate: Date) -> Int {
        let calendar = Calendar.current
        switch TimeFrameMobility {
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
    private func filterAndAggregateDataForPage(_ data: [ChartDataMobility], timeFrame: TimeFrameMobility, page: Int, startDate: Date, endDate: Date) -> [ChartDataMobility] {
        let calendar = Calendar.current
        var filteredData: [ChartDataMobility] = []

        switch timeFrame {
        case .daily:
            let pageDate = calendar.date(byAdding: .day, value: page, to: startDate) ?? startDate
            if pageDate <= endDate {
                let hourlyData = aggregateDataByHour(for: pageDate, data: data, endDate: endDate)
                filteredData = hourlyData
            }
            
        case .weekly:
            let startOfWeek = calendar.date(byAdding: .weekOfYear, value: page, to: startDate) ?? startDate
            if startOfWeek <= endDate {
                let dailyData = (0..<7).compactMap { offset -> ChartDataMobility? in
                    let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek)!
                    return aggregateDataByDay(for: date, data: data, endDate: endDate)
                }
                filteredData = dailyData
            }
            
        case .monthly:
            let startOfMonth = calendar.date(byAdding: .month, value: page, to: startDate) ?? startDate
            if startOfMonth <= endDate {
                let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
                let numberOfDaysInMonth = range.count
                let dailyData = (0..<numberOfDaysInMonth).compactMap { offset -> ChartDataMobility? in
                    let date = calendar.date(byAdding: .day, value: offset, to: startOfMonth)!
                    if date <= endDate { // Ensure the date is within the end date
                        return aggregateDataByDay(for: date, data: data, endDate: endDate)
                    }
                    return nil
                }
                filteredData = dailyData
            }
            
        case .sixMonths:
            let startOfSixMonths = calendar.date(byAdding: .month, value: page * 6, to: startDate) ?? startDate
            if startOfSixMonths <= endDate {
                let sixMonthsData = aggregateDataByWeek(for: startOfSixMonths, data: data, weeks: 26)
                filteredData = sixMonthsData.filter { $0.date <= endDate } // Ensure data is within the end date
            }
            
        case .yearly:
            let startOfYear = calendar.date(byAdding: .year, value: page, to: startDate) ?? startDate
            if startOfYear <= endDate {
                let yearlyData = aggregateDataByMonth(for: startOfYear, data: data, months: 12)
                filteredData = yearlyData
            }
        }

        return filteredData
    }

    // Aggregate data by minute
    private func aggregateDataByMinute(for date: Date, data: [ChartDataMobility], endDate: Date) -> [ChartDataMobility] {
        let calendar = Calendar.current
        var minuteData: [ChartDataMobility] = []

        for minute in 0..<60 {
            let startOfMinute = calendar.date(bySettingHour: calendar.component(.hour, from: date), minute: minute, second: 0, of: date)!
            let endOfMinute = calendar.date(bySettingHour: calendar.component(.hour, from: date), minute: minute, second: 59, of: date)!

            if startOfMinute > endDate {
                break
            }

            let filteredData = data.filter { $0.date >= startOfMinute && $0.date <= endOfMinute }

            let minValue = filteredData.map { $0.minValue }.min() ?? 0.0
            let maxValue = filteredData.map { $0.maxValue }.max() ?? 0.0
            let averageValue = (minValue + maxValue) / 2

            minuteData.append(ChartDataMobility(date: startOfMinute, minValue: minValue, maxValue: maxValue, value: averageValue))
        }

        return minuteData
    }

    // Aggregate data by hour with min, max, and average values
    private func aggregateDataByHour(for date: Date, data: [ChartDataMobility], endDate: Date) -> [ChartDataMobility] {
        let calendar = Calendar.current
        var hourlyData: [ChartDataMobility] = []

        for hour in 0..<24 {
            let startOfHour = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
            let endOfHour = calendar.date(bySettingHour: hour, minute: 59, second: 59, of: date)!

            if startOfHour > endDate {
                break
            }

            let filteredData = data.filter { $0.date >= startOfHour && $0.date <= endOfHour }

            let minValue = filteredData.map { $0.minValue }.min() ?? 0.0
            let maxValue = filteredData.map { $0.maxValue }.max() ?? 0.0
            let averageValue = (minValue + maxValue) / 2

            hourlyData.append(ChartDataMobility(date: startOfHour, minValue: minValue, maxValue: maxValue, value: averageValue))
        }

        return hourlyData
    }

    // Aggregate data by day with min, max, and average values
    private func aggregateDataByDay(for date: Date, data: [ChartDataMobility], endDate: Date) -> ChartDataMobility {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? endDate

        let filteredData = data.filter { $0.date >= startOfDay && $0.date <= endOfDay }

        let minValue = filteredData.map { $0.minValue }.min() ?? 0.0
        let maxValue = filteredData.map { $0.maxValue }.max() ?? 0.0
        let averageValue = (minValue + maxValue) / 2

        return ChartDataMobility(date: startOfDay, minValue: minValue, maxValue: maxValue, value: averageValue)
    }

    // Aggregate data by week with min, max, and average values
    private func aggregateDataByWeek(for startDate: Date, data: [ChartDataMobility], weeks: Int) -> [ChartDataMobility] {
        let calendar = Calendar.current
        var weeklyData: [ChartDataMobility] = []

        for weekOffset in 0..<weeks {
            let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startDate)!)?.start ?? startDate
            let currentWeekEnd = calendar.date(byAdding: .day, value: 6, to: currentWeekStart)!

            let filteredData = data.filter { $0.date >= currentWeekStart && $0.date <= currentWeekEnd }

            let minValue = filteredData.map { $0.minValue }.min() ?? 0.0
            let maxValue = filteredData.map { $0.maxValue }.max() ?? 0.0
            let averageValue = (minValue + maxValue) / 2

            weeklyData.append(ChartDataMobility(date: currentWeekStart, minValue: minValue, maxValue: maxValue, value: averageValue))
        }

        return weeklyData
    }

    // Aggregate data by month with min, max, and average values
    private func aggregateDataByMonth(for startDate: Date, data: [ChartDataMobility], months: Int) -> [ChartDataMobility] {
        let calendar = Calendar.current
        var monthlyData: [ChartDataMobility] = []

        for monthOffset in 0..<months {
            let currentMonthStart = calendar.date(byAdding: .month, value: monthOffset, to: startDate)!
            let currentMonthEnd = calendar.date(byAdding: .month, value: 1, to: currentMonthStart)!.addingTimeInterval(-1)

            let filteredData = data.filter { $0.date >= currentMonthStart && $0.date <= currentMonthEnd }

            let minValue = filteredData.map { $0.minValue }.min() ?? 0.0
            let maxValue = filteredData.map { $0.maxValue }.max() ?? 0.0
            let averageValue = (minValue + maxValue) / 2

            monthlyData.append(ChartDataMobility(date: currentMonthStart, minValue: minValue, maxValue: maxValue, value: averageValue))
        }

        return monthlyData
    }

    // Function to get the title for the current page based on the time frame
    private func getTitleForCurrentPage(TimeFrameMobility: TimeFrameMobility, page: Int, startDate: Date, endDate: Date) -> String {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        var title: String = ""
        
        switch TimeFrameMobility {
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


struct ChartDataMobility: Identifiable {
    let id = UUID()
    let date: Date
    let minValue: Double
    let maxValue: Double
    let value: Double
}

struct BoxChartViewMobility: View {
    var data: [ChartDataMobility]
    var timeFrame: TimeFrameMobility
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
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
                        if title == "Walking Steadiness" && (timeFrame == .monthly || timeFrame == .sixMonths) {
                            // Use PointMark for Walking Steadiness in .monthly and .sixMonths
                            if item.value != 0 {
                                PointMark(
                                    x: .value("Date", item.date),
                                    y: .value("Value", item.value)
                                )
                                .symbolSize(25)
                            }
                        } else if title == "Walking Steadiness" && timeFrame == .yearly {
                            // Adjust minValue for Walking Steadiness in .yearly, but skip if minValue is 0
                            let adjustedMinValue = item.minValue != 0 ? item.minValue - 1 : item.minValue
                            
                            BarMark(
                                x: .value("Date", item.date),
                                yStart: .value("Min", adjustedMinValue), // Use the adjusted minValue
                                yEnd: .value("Max", item.maxValue)
                            )
                            .offset(x: getOffsetForTimeFrame(timeFrame))
                        } else if item.minValue == item.maxValue {
                            let adjustedMinValue = item.minValue != 0 ? item.minValue - 1 : item.minValue
                            
                            BarMark(
                                x: .value("Date", item.date),
                                yStart: .value("Min", adjustedMinValue), // Use the adjusted minValue
                                yEnd: .value("Max", item.maxValue)
                            )
                        } else {
                            // Use BarMark for other cases
                            BarMark(
                                x: .value("Date", item.date),
                                yStart: .value("Min", item.minValue),
                                yEnd: .value("Max", item.maxValue)
                            )
                            .offset(x: getOffsetForTimeFrame(timeFrame))
                        }
                    }
                }
                .id(UUID())
                .foregroundStyle(Color.primary)
                .chartYAxis {
                    switch title {
                    case "Walking Double Support", "Walking Asymmetry":
                        AxisMarks(values: [0, 50, 100]) { value in
                            AxisValueLabel(format: Decimal.FormatStyle.Percent.percent.scale(1))
                            AxisGridLine()
                        }
                    case "Walking Steadiness":
                        // Add grid lines at 0, 20, 40, and 100
                        AxisMarks(values: [0, 20, 40, 100]) {
                            AxisGridLine()
                        }

                        // Add custom labels at midpoints (10, 30, 70)
                        AxisMarks(values: [10, 30, 70]) { value in
                            AxisValueLabel {
                                let steadinessValue = value.as(Double.self) ?? 0
                                if steadinessValue == 10 {
                                    Text("Very Low")
                                } else if steadinessValue == 30 {
                                    Text("Low")
                                } else if steadinessValue == 70 {
                                    Text("OK")
                                }
                            }
                        }
                    default:
                        AxisMarks(values: .automatic(desiredCount: 3))
                    }
                }
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
                            AxisValueLabel(format: .dateTime.month(.narrow))
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
                                           Text(getFormattedText(minValue: item.minValue, maxValue: item.maxValue))
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

        // Helper function to format the text based on the title
        private func getFormattedText(minValue: Double, maxValue: Double) -> String {
            guard minValue != 0 || maxValue != 0 else {
                return "--"
            }

            let unit: String
            switch title {
            case "Walking Speed":
                unit = "m/s"
            case "Walking Step Length":
                unit = "meters"
            case "Walking Double Support", "Walking Asymmetry", "Walking Steadiness":
                unit = "%"
            default:
                unit = ""
            }

            // Check if minValue is equal to maxValue
            if minValue == maxValue {
                return "\(String(format: "%.1f", maxValue)) \(unit)"
            } else {
                return "\(String(format: "%.1f", minValue))-\(String(format: "%.1f", maxValue)) \(unit)"
            }
        }
    
    // Helper function to get the dynamic title based on data type and time frame
        private func getDynamicTitle() -> String {
            switch title {
            case "Walking Double Support":
                switch timeFrame {
                case .sixMonths:
                    return "Daily average step counts (weekly)"
                case .yearly:
                    return "Daily average step counts (monthly)"
                default:
                    return "Step Counts"
                }
                
            case "Walking Asymmetry":
                switch timeFrame {
                case .sixMonths:
                    return "Daily average Active energy burned (weekly)"
                case .yearly:
                    return "Daily average Active energy burned (monthly)"
                default:
                    return "Active Energy Burned in KCal"
                }
                
            case "Walking Speed":
                switch timeFrame {
                case .sixMonths:
                    return "Daily average Move time (weekly)"
                case .yearly:
                    return "Daily average Move time (monthly)"
                default:
                    return "Move Time in seconds"
                }
                
            case "Walking Step length":
                switch timeFrame {
                case .sixMonths:
                    return "Daily average Stand time (weekly)"
                case .yearly:
                    return "Daily average Stand time (monthly)"
                default:
                    return "Stand Time in seconds"
                }
                
            case "Walking Steadiness":
                switch timeFrame {
                case .sixMonths:
                    return "Daily average Distance Walking/Running (weekly)"
                case .yearly:
                    return "Daily average Distance Walking/Running (monthly)"
                default:
                    return "Distance Walking/Running in meters"
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
    private func getOffsetForTimeFrame(_ timeFrame: TimeFrameMobility) -> CGFloat {
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
                return 11.5 // No offset for yearly view
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
        
        switch timeFrame {
        case .monthly:
            let adjustedLastDate = calendar.date(byAdding: .day, value: 1, to: lastDate) ?? lastDate
            return firstDate...adjustedLastDate
        case .sixMonths:
            let adjustedLastDate = calendar.date(byAdding: .day, value: 15, to: lastDate) ?? lastDate
            return firstDate...adjustedLastDate
        case .yearly:
            let adjustedLastDate = calendar.date(byAdding: .month, value: 1, to: lastDate) ?? lastDate
            return firstDate...adjustedLastDate
        default:
            return firstDate...lastDate
        }
    }
}


#Preview {
    mobilityView()
}
