//
//  vitalView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 19.09.24.
//

import SwiftUI
import HealthKit
import Charts
import Foundation

enum TimeFrameVital: String, CaseIterable {
    case hourly = "Hourly"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case sixMonths = "6 Months"
    case yearly = "Yearly"
}

struct vitalView: View {
    @StateObject private var vitalManager: VitalManager
    @State private var isRecording = false
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    @State private var savedFilePath: String? = nil
    
    @State private var showingInfo = false
    // New state to trigger the graph refresh
    @State private var refreshGraph = UUID()
    
    // State variable to control sheet presentation
    @State private var showingHeartRateChart = false
    
    init() {
        _vitalManager = StateObject(wrappedValue: VitalManager(startDate: Date(), endDate: Date()))
    }
    
    var body: some View {
        VStack {
            
            ScrollView(.vertical) {
                VStack(spacing: 10) {
                    dataSection(title: "Heart Rate", dataAvailable: !vitalManager.heartRateData.isEmpty, chartKey: "HeartRate", data: vitalManager.heartRateData, unit: HKUnit.init(from: "count/min"), chartTitle: "Heart Rate")
                }
                .padding()
            }
            Text("Set Start and End-Date to fetched available data:")
                .font(.subheadline)
            
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                .onChange(of: startDate) { _, newDate in
                    vitalManager.startDate = newDate
                }
            
            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                .onChange(of: endDate) { _, newDate in
                    vitalManager.endDate = newDate
                }

            Spacer()

            HStack {
                Button(action: {
                    if isRecording {
                        // Define the server URL
                        let serverURL = ServerConfig.serverURL

                        // Call saveDataAsCSV with the server URL
                        vitalManager.saveDataAsCSV(serverURL: serverURL)
                    } else {
                        vitalManager.fetchVitalData(startDate: startDate, endDate: endDate)
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
                
                if vitalManager.savedFilePath != nil {
                    Text("File saved")
                        .font(.footnote)
                }
            }
        }
        .padding()
        .navigationTitle("Vital Health Data")
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
    
    @ViewBuilder
    private func dataSection(title: String, dataAvailable: Bool, chartKey: String, data: [VitalStatistics], unit: HKUnit, chartTitle: String) -> some View {
        Section(header: Text(title).font(.title3)) {
            HStack {
                if !isRecording {
                    
                } else {
                    if dataAvailable {
                        Button(action: {
                            showingHeartRateChart = true
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
                        showingHeartRateChart = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Color.blue)
                    }
                    .sheet(isPresented: $showingHeartRateChart) {
                        VitalChartWithTimeFramePicker(title: chartTitle, data: data.map {
                            ChartDataVital(date: $0.endDate, minValue: $0.minValue, maxValue: $0.maxValue, averageValue: $0.averageValue)
                        },
                              startDate: vitalManager.startDate,
                              endDate: vitalManager.endDate)
                    }
                }
            }
        }
    }
}

struct VitalChartWithTimeFramePicker: View {
    var title: String
    var data: [ChartDataVital]
    var startDate: Date
    var endDate: Date
    
    @State private var selectedTimeFrameVital: TimeFrameVital = .sixMonths
    @State private var currentPageForTimeFramesVital: [TimeFrameVital: Int] = [
        .hourly: 0,
        .daily: 0,
        .weekly: 0,
        .monthly: 0,
        .sixMonths: 0,
        .yearly: 0
    ]
    @State private var showInfoPopover: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var selectedDate: Date = Date()
    @State private var selectedHour: Int = Calendar.current.component(.hour, from: Date())
    
    @State private var refreshGraph = UUID()
    
    // Cache for precomputed data
    @State private var precomputedPageData: [TimeFrameVital: [Int: [ChartDataVital]]] = [:]
    @State private var minValue: Double = 0
    @State private var maxValue: Double = 0
    @State private var averageValue: Double = 0

    var body: some View {
        VStack {
            HStack {
                Text(getInformationText())
                    .font(.body)
                    .foregroundStyle(Color.primary)
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
            
            Picker("Time Frame", selection: $selectedTimeFrameVital) {
                ForEach(getAvailableTimeFrames(for: title), id: \.self) { timeFrame in
                    Text(timeFrame.rawValue).tag(timeFrame)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedTimeFrameVital) { _, _ in
                updateFilteredData()
            }
            
            HStack {
                Text(getTitleForMetric(TimeFrameVital: selectedTimeFrameVital, minValue: minValue, maxValue: maxValue, averageValue: averageValue))
                    .font(.footnote)
                    .foregroundColor(.primary)
                
                Button(action: {
                    showDatePicker = true
                }) {
                    Text(getTitleForCurrentPage(TimeFrameVital: selectedTimeFrameVital, page: currentPageForTimeFramesVital[selectedTimeFrameVital] ?? 0, startDate: startDate, endDate: endDate))
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
                        if selectedTimeFrameVital == .hourly {
                            // Hourly: Allow selection of both date and hour
                            DatePicker("Select Date and Hour", selection: $selectedDate, in: startDate...endDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .labelsHidden()
                                .onChange(of: selectedDate) { _, newDate in
                                    let calendar = Calendar.current
                                    selectedHour = calendar.component(.hour, from: newDate)
                                    // Ensure the selectedDate is set with the updated hour, minute, and second
                                    selectedDate = calendar.date(bySettingHour: selectedHour, minute: 0, second: 0, of: newDate) ?? newDate
                                    jumpToPage(for: selectedDate)
                                }
                        } else if selectedTimeFrameVital == .yearly {
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
                        } else if selectedTimeFrameVital == .monthly || selectedTimeFrameVital == .sixMonths {
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
                
                Text(getValueText(timeFrame: selectedTimeFrameVital, minValue: minValue, maxValue: maxValue, averageValue: averageValue))
                    .foregroundColor(.primary)
                
                Text(getUnitForMetric(title: title))
                    .foregroundColor(.primary)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 5)
            
            // Use precomputed data for TabView
            TabView(selection: Binding(
                get: { currentPageForTimeFramesVital[selectedTimeFrameVital] ?? 0 },
                set: { newValue in
                    currentPageForTimeFramesVital[selectedTimeFrameVital] = newValue
                    updateDisplayedData()
                }
            )) {
                if let pageData = precomputedPageData[selectedTimeFrameVital] {
                    ForEach(0..<getPageCount(for: selectedTimeFrameVital, startDate: startDate, endDate: endDate), id: \.self) { page in
                        BoxChartViewVital(data: pageData[page] ?? [], timeFrame: selectedTimeFrameVital, title: title)
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
            updateFilteredData()  // Precompute data before the view appears
            jumpToPage(for: endDate)  // Immediately jump to the correct page
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                refreshGraph = UUID()
            }
        }
    }

    private func getAvailableTimeFrames(for title: String) -> [TimeFrameVital] {
        if title == "Walking Steadiness" {
            // Exclude .daily and .weekly for "Walking Steadiness"
            return TimeFrameVital.allCases.filter { $0 != .daily && $0 != .weekly }
        } else {
            // Return all time frames for other titles
            return TimeFrameVital.allCases
        }
    }

    // Precompute data for all pages
    private func updateFilteredData() {
        DispatchQueue.global(qos: .userInitiated).async {
            var newPrecomputedData: [Int: [ChartDataVital]] = [:]
            let pageCount = getPageCount(for: selectedTimeFrameVital, startDate: startDate, endDate: endDate)

            // Loop over each page and compute the data for it
            for page in 0..<pageCount {
                let filtered = filterAndAggregateDataForPage(data, timeFrame: selectedTimeFrameVital, page: page, startDate: startDate, endDate: endDate, title: title)
                newPrecomputedData[page] = filtered
            }

            // Compute min, max, and average for the current page
            let (computedMinValue, computedMaxValue, computedAverageValue) = calculateMinMaxAndAverage(
                for: selectedTimeFrameVital,
                data: newPrecomputedData[currentPageForTimeFramesVital[selectedTimeFrameVital] ?? 0] ?? [],
                startDate: startDate,
                endDate: endDate,
                currentPage: currentPageForTimeFramesVital[selectedTimeFrameVital] ?? 0
            )

            // Update state on the main thread
            DispatchQueue.main.async {
                precomputedPageData[selectedTimeFrameVital] = newPrecomputedData
                minValue = computedMinValue
                maxValue = computedMaxValue
                averageValue = computedAverageValue // Update average value
            }
        }
    }

    // Update displayed data based on the current page
    private func updateDisplayedData() {
        if let pageData = precomputedPageData[selectedTimeFrameVital]?[currentPageForTimeFramesVital[selectedTimeFrameVital] ?? 0] {
            let (computedMinValue, computedMaxValue, computedAverageValue) = calculateMinMaxAndAverage(
                for: selectedTimeFrameVital,
                data: pageData,
                startDate: startDate,
                endDate: endDate,
                currentPage: currentPageForTimeFramesVital[selectedTimeFrameVital] ?? 0
            )
            minValue = computedMinValue
            maxValue = computedMaxValue
            averageValue = computedAverageValue // Update average value
        }
    }

    private func popoverContent() -> some View {
        VStack(alignment: .leading) {
            Text("Additional Information")
                .font(.title)
                .padding(.bottom, 7)
                .foregroundStyle(Color.primary)
            Text(dataInformation())
                .font(.body)
                .padding(.bottom, 3)
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
    
    private func getUnitForMetric(title: String) -> String {
        switch title {
        case "Heart Rate":
            return "BPM"
        default:
            return ""
        }
    }

    private func getValueText(timeFrame: TimeFrameVital, minValue: Double, maxValue: Double, averageValue: Double) -> String {
        // Check if any of the values are 0, and return "--" if they are
        if minValue == 0 && maxValue == 0 && averageValue == 0 {
            return "--"
        }
        
        if minValue == maxValue {
            // If minValue equals maxValue, show only the average
            return "\(String(format: "%.1f", averageValue))"
        } else {
            // Otherwise, show the range and average
            let rangeText = "(\(String(format: "%.1f", minValue))-\(String(format: "%.1f", maxValue)))"
            return "\(rangeText) \(String(format: "%.1f", averageValue))"
        }
    }
    
    private func jumpToPage(for date: Date) {
        let calendar = Calendar.current
        switch selectedTimeFrameVital {
        case .hourly:
            let hoursDifference = calendar.dateComponents([.hour], from: startDate, to: date).hour ?? 0
            currentPageForTimeFramesVital[selectedTimeFrameVital] = max(hoursDifference, 0)
        case .daily:
            let daysDifference = calendar.dateComponents([.day], from: startDate, to: date).day ?? 0
            currentPageForTimeFramesVital[selectedTimeFrameVital] = max(daysDifference, 0)
        case .weekly:
            let weeksDifference = calendar.dateComponents([.weekOfYear], from: startDate, to: date).weekOfYear ?? 0
            currentPageForTimeFramesVital[selectedTimeFrameVital] = max(weeksDifference, 0)
        case .monthly:
            let monthsDifference = calendar.dateComponents([.month], from: startDate, to: date).month ?? 0
            currentPageForTimeFramesVital[selectedTimeFrameVital] = max(monthsDifference, 0)
        case .sixMonths:
            let monthsDifference = calendar.dateComponents([.month], from: startDate, to: date).month ?? 0
            currentPageForTimeFramesVital[selectedTimeFrameVital] = max(monthsDifference / 6, 0)
        case .yearly:
            let yearsDifference = calendar.dateComponents([.year], from: startDate, to: date).year ?? 0
            currentPageForTimeFramesVital[selectedTimeFrameVital] = max(yearsDifference, 0)
        }
    }
        
    private func calculateMinMaxAndAverage(for timeFrame: TimeFrameVital, data: [ChartDataVital], startDate: Date, endDate: Date, currentPage: Int) -> (minValue: Double, maxValue: Double, averageValue: Double) {
        // Filter out zero values when computing the minimum
        let nonZeroData = data.filter { $0.minValue > 0 }
        
        // Calculate min and max from non-zero values
        let minValue = nonZeroData.map { $0.minValue }.min() ?? 0.0
        let maxValue = data.map { $0.maxValue }.max() ?? 0.0

        // Filter data with valid non-zero values
        let validData = data.filter { $0.averageValue > 0 }

        // Calculate the total and average value only for entries that have data
        let totalValue = validData.reduce(0) { $0 + $1.averageValue }
        let averageValue = validData.isEmpty ? 0 : totalValue / Double(validData.count)

        return (minValue, maxValue, averageValue)
    }

    private func getTitleForMetric(TimeFrameVital: TimeFrameVital, minValue: Double, maxValue: Double, averageValue: Double) -> String {
        
        if minValue == maxValue {
            // If minValue == maxValue, show only the average
            return "Average in "
        } else {
            return "(Range) Average in "
        }
    }
    
    // Helper function to display different text based on the selected data section
    private func getInformationText() -> String {
        switch title {
        case "Heart Rate":
            return "Heart Rate"
        default:
            return "Data not available."
        }
    }
    
    private func dataInformation() -> String {
        switch title {
        case "Heart Rate":
            return "DATA INFORMATION: Heart Rate is a measure of the number of times the heart beats per minute."
        default:
            return "Data not available."
        }
    }
    
    // Helper function for detailed popover information
    private func measuredUsing() -> String {
        switch title {
        case "Heart Rate":
            return "MEASURED USING: Apple Watch"
        default:
            return "Data not available."
        }
    }
    
    private func useCase() -> String {
        switch title {
        case "Heart Rate":
            return "USE CASE: Cardiovascular, Diabetes, COPD, Neurological and Psychiatric disorders and Obesity and Metabolic syndrome"
        default:
            return "Data not available."
        }
    }
}
    
    private func getPageCount(for timeFrame: TimeFrameVital, startDate: Date, endDate: Date) -> Int {
        let calendar = Calendar.current
        switch timeFrame {
        case .hourly:
            // Calculate hours between start and end dates
            let hourDifference = calendar.dateComponents([.hour], from: startDate, to: endDate).hour ?? 0
            return max(hourDifference + 1, 1) // Ensure at least 1 page
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

    // Function to round the date down to the nearest hour
    private func floorDateToHour(_ date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: calendar.component(.hour, from: date), minute: 0, second: 0, of: date) ?? date
    }

    // Function to round the date up to the next full hour
    private func ceilDateToHour(_ date: Date) -> Date {
        let calendar = Calendar.current
        let flooredDate = floorDateToHour(date)
        if date > flooredDate {
            return calendar.date(byAdding: .hour, value: 1, to: flooredDate) ?? date
        }
        return flooredDate
    }

    // Function to get the title for the current page based on the time frame
    private func getTitleForCurrentPage(TimeFrameVital: TimeFrameVital, page: Int, startDate: Date, endDate: Date) -> String {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        var title: String = ""
        
        switch TimeFrameVital {
        case .hourly:
            // Round the start date to the nearest full hour
            let startHour = calendar.date(byAdding: .hour, value: page, to: floorDateToHour(startDate)) ?? startDate
            let endHour = calendar.date(byAdding: .hour, value: 1, to: startHour) ?? startHour
            
            dateFormatter.dateStyle = .medium
            let formattedDate = dateFormatter.string(from: startHour)
            dateFormatter.dateFormat = "HH:mm"
            let startTime = dateFormatter.string(from: startHour)
            let endTime = dateFormatter.string(from: endHour)
            
            title = "\(formattedDate), \(startTime) - \(endTime)"
            
        case .daily:
            let pageDate = calendar.date(byAdding: .day, value: page, to: startDate) ?? startDate
            dateFormatter.dateStyle = .full
            title = dateFormatter.string(from: pageDate)
            
        case .weekly:
            let startOfWeek = calendar.date(byAdding: .weekOfYear, value: page, to: startDate) ?? startDate
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? startOfWeek
            dateFormatter.dateFormat = "MMM dd"
            title = "\(dateFormatter.string(from: startOfWeek)) - \(dateFormatter.string(from: endOfWeek))"
            
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

    // Function to filter and aggregate data based on the current page and time frame
private func filterAndAggregateDataForPage(_ data: [ChartDataVital], timeFrame: TimeFrameVital, page: Int, startDate: Date, endDate: Date, title: String) -> [ChartDataVital] {
        let calendar = Calendar.current
        var filteredData: [ChartDataVital] = []
        
        switch timeFrame {
        case .hourly:
            // Round startDate to the nearest full hour
            let hourStart = calendar.date(byAdding: .hour, value: page, to: floorDateToHour(startDate)) ?? startDate
            
            if hourStart <= endDate {
                let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourStart) ?? hourStart
                filteredData = data.filter { $0.date >= hourStart && $0.date < hourEnd }
            }
            
        case .daily:
            let pageDate = calendar.date(byAdding: .day, value: page, to: startDate) ?? startDate
            if pageDate <= endDate {
                let hourlyData = aggregateDataByHour(for: pageDate, data: data, endDate: endDate)
                filteredData = hourlyData
            }
            
        case .weekly:
            let startOfWeek = calendar.date(byAdding: .weekOfYear, value: page, to: startDate) ?? startDate
            if startOfWeek <= endDate {
                let dailyData = (0..<7).compactMap { offset -> ChartDataVital? in
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
                let dailyData = (0..<numberOfDaysInMonth).compactMap { offset -> ChartDataVital? in
                    let date = calendar.date(byAdding: .day, value: offset, to: startOfMonth)!
                    return aggregateDataByDay(for: date, data: data, endDate: endDate)
                }
                filteredData = dailyData
            }
            
        case .sixMonths:
            let startOfSixMonths = calendar.date(byAdding: .month, value: page * 6, to: startDate) ?? startDate
            if startOfSixMonths <= endDate {
                let sixMonthsData = aggregateDataByWeek(for: startOfSixMonths, data: data, weeks: 26, endDate: endDate)
                filteredData = sixMonthsData
            }
            
        case .yearly:
            let startOfYear = calendar.date(byAdding: .year, value: page, to: startDate) ?? startDate
            if startOfYear <= endDate {
                let yearlyData = aggregateDataByMonth(for: startOfYear, data: data, months: 12, endDate: endDate)
                filteredData = yearlyData
            }
        }
        
        return filteredData
    }

    // Aggregate data by the minute for hourly view with min and max values
    private func aggregateDataByMinute(for date: Date, data: [ChartDataVital], endDate: Date) -> [ChartDataVital] {
        let calendar = Calendar.current
        var minuteData: [ChartDataVital] = []
        
        for minute in 0..<60 {
            let startOfMinute = calendar.date(bySettingHour: calendar.component(.hour, from: date), minute: minute, second: 0, of: date)!
            let endOfMinute = calendar.date(bySettingHour: calendar.component(.hour, from: date), minute: minute, second: 59, of: date)!
            
            // Check if the start of minute exceeds the endDate
            if startOfMinute > endDate {
                break
            }
            
            let filteredData = data.filter { $0.date >= startOfMinute && $0.date <= endOfMinute }
            
            let minValue = filteredData.map { $0.minValue }.min() ?? 0.0
            let maxValue = filteredData.map { $0.maxValue }.max() ?? 0.0
            let averageValue = (minValue + maxValue) / 2
            
            minuteData.append(ChartDataVital(date: startOfMinute, minValue: minValue, maxValue: maxValue, averageValue: averageValue))
        }
        
        return minuteData
    }

    // Aggregate data by hour with min and max values
    private func aggregateDataByHour(for date: Date, data: [ChartDataVital], endDate: Date) -> [ChartDataVital] {
        let calendar = Calendar.current
        var hourlyData: [ChartDataVital] = []
        
        for hour in 0..<24 {
            let startOfHour = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
            let endOfHour = calendar.date(bySettingHour: hour, minute: 59, second: 59, of: date)!
            
            // Check if the start of hour exceeds the endDate
            if startOfHour > endDate {
                break
            }
            
            let filteredData = data.filter { $0.date >= startOfHour && $0.date <= endOfHour }
            
            let minValue = filteredData.map { $0.minValue }.min() ?? 0.0
            let maxValue = filteredData.map { $0.maxValue }.max() ?? 0.0
            let averageValue = (minValue + maxValue) / 2
            
            hourlyData.append(ChartDataVital(date: startOfHour, minValue: minValue, maxValue: maxValue, averageValue: averageValue))
        }
        
        return hourlyData
    }

    // Aggregate data by day with min and max values
    private func aggregateDataByDay(for date: Date, data: [ChartDataVital], endDate: Date) -> ChartDataVital {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)!
        
        // Ensure the date range is within bounds
        if startOfDay > endDate {
            return ChartDataVital(date: startOfDay, minValue: 0, maxValue: 0, averageValue: 0)
        }
        
        let filteredData = data.filter { $0.date >= startOfDay && $0.date <= endOfDay }
        
        let minValue = filteredData.map { $0.minValue }.min() ?? 0.0
        let maxValue = filteredData.map { $0.maxValue }.max() ?? 0.0
        let averageValue = (minValue + maxValue) / 2
        
        return ChartDataVital(date: startOfDay, minValue: minValue, maxValue: maxValue, averageValue: averageValue)
    }

    // Aggregate data by week with min and max values
    private func aggregateDataByWeek(for startDate: Date, data: [ChartDataVital], weeks: Int, endDate: Date) -> [ChartDataVital] {
        let calendar = Calendar.current
        var weeklyData: [ChartDataVital] = []
        
        for weekOffset in 0..<weeks {
            let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startDate)!)?.start ?? startDate
            let currentWeekEnd = calendar.date(byAdding: .day, value: 6, to: currentWeekStart)!
            
            // Check if the start of week exceeds the endDate
            if currentWeekStart > endDate {
                break
            }
            
            let filteredData = data.filter { $0.date >= currentWeekStart && $0.date <= currentWeekEnd }
            
            let minValue = filteredData.map { $0.minValue }.min() ?? 0.0
            let maxValue = filteredData.map { $0.maxValue }.max() ?? 0.0
            let averageValue = (minValue + maxValue) / 2
            
            weeklyData.append(ChartDataVital(date: currentWeekStart, minValue: minValue, maxValue: maxValue, averageValue: averageValue))
        }
        
        return weeklyData
    }

    // Aggregate data by month with min and max values
    private func aggregateDataByMonth(for startDate: Date, data: [ChartDataVital], months: Int, endDate: Date) -> [ChartDataVital] {
        let calendar = Calendar.current
        var monthlyData: [ChartDataVital] = []
        
        for monthOffset in 0..<months {
            let currentMonthStart = calendar.date(byAdding: .month, value: monthOffset, to: startDate)!
            let currentMonthEnd = calendar.date(byAdding: .month, value: 1, to: currentMonthStart)!.addingTimeInterval(-1)
            
            // Check if the start of month exceeds the endDate
            if currentMonthStart > endDate {
                break
            }
            
            let filteredData = data.filter { $0.date >= currentMonthStart && $0.date <= currentMonthEnd }
            
            let minValue = filteredData.map { $0.minValue }.min() ?? 0.0
            let maxValue = filteredData.map { $0.maxValue }.max() ?? 0.0
            let averageValue = (minValue + maxValue) / 2
            
            monthlyData.append(ChartDataVital(date: currentMonthStart, minValue: minValue, maxValue: maxValue, averageValue: averageValue))
        }
        
        return monthlyData
    }
    
    private func getInformationText() -> String {
        return "Heart Rate is measured in beats per minute (BPM)."
    }

struct ChartDataVital: Identifiable {
    let id = UUID()
    let date: Date
    let minValue: Double
    let maxValue: Double
    let averageValue: Double
}

struct BoxChartViewVital: View {
    var data: [ChartDataVital]
    var timeFrame: TimeFrameVital
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
            } else if data.allSatisfy({ $0.minValue == 0 && $0.maxValue == 0}) {
                Text("No Data")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                Chart {
                    ForEach(data) { item in
                        if timeFrame == .hourly {
                            // For hourly view, plot raw data points directly
                            PointMark(
                                x: .value("Time", item.date),
                                y: .value("Heart Rate", item.averageValue)  // raw heart rate value
                            )
                            .symbolSize(15)
                            LineMark(
                                x: .value("Time", item.date),
                                y: .value("Heart Rate", item.averageValue)  // raw heart rate value
                            )
                            .symbolSize(1)
                        } else {
                            // Existing logic for other views
                            BarMark(
                                x: .value("Date", item.date),
                                yStart: .value("Min", item.minValue),
                                yEnd: .value("Max", item.maxValue)
                            )
                        }
                    }
                }
                .id(UUID())
                .foregroundStyle(Color.primary)
                .chartXScale(domain: getXScaleDomain())
                .chartXAxis {
                    switch timeFrame {
                    case .hourly:
                        AxisMarks(values: .stride(by: .minute, count: 15)) { value in
                            AxisValueLabel(format: .dateTime.hour().minute())
                            AxisGridLine()
                        }
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
                        AxisMarks(values: .automatic()) { value in
                            AxisValueLabel(format: .dateTime.month(.narrow))
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
                            
                            VStack {
                                // Check if it's a range or just an average (minValue == maxValue)
                                if item.minValue == item.maxValue {
                                    // If minValue equals maxValue, show "Average"
                                    Text("Average")
                                        .font(.caption2)
                                } else {
                                    // Otherwise, show "(Range) Average"
                                    Text("(Range) Average")
                                        .font(.caption2)
                                }

                                // Display the value or the range, with "--" if the value is 0
                                if item.minValue == item.maxValue {
                                    // Show only the average value if minValue == maxValue
                                    Text(item.averageValue == 0 ? "--" : "\(String(format: "%.1f", item.averageValue)) BPM")
                                } else {
                                    // Show the range (minValue-maxValue) with the average in parentheses
                                    Text(item.averageValue == 0 ? "--" : "(\(String(format: "%.1f", item.minValue))-\(String(format: "%.1f", item.maxValue))) \(String(format: "%.1f", item.averageValue)) BPM")
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
                .frame(maxHeight: 200) // Restrict the height of the scrollable list
               }
           }
           .padding()
           .background(Color(UIColor.secondarySystemBackground))
           .cornerRadius(25)
       }

    // Helper function to format the text for Heart Rate (BPM)
    private func getFormattedText(minValue: Double, maxValue: Double, value: Double) -> String {
        guard minValue != 0 || maxValue != 0 else {
            return "--"
        }

        let unit: String = "BPM" // Heart rate is always measured in BPM

        // Check if minValue is equal to maxValue
        if minValue == maxValue {
            return "\(String(format: "%.1f", maxValue)) \(unit)"
        } else {
            // Return formatted string showing the range between minValue and maxValue
            return "\(String(format: "%.1f", minValue))-\(String(format: "%.1f", maxValue)) \(unit)"
        }
    }
    
    // Helper function to get the dynamic title based on data type and time frame
//        private func getDynamicTitle() -> String {
//            switch title {
//            case "Heart Rate":
//                switch timeFrame {
//                case .sixMonths:
//                    return "Heart rate range (weekly)"
//                case .yearly:
//                    return "Heart rate range (monthly)"
//                default:
//                    return "Heart rate"
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
        case .hourly:
            // For hourly, display the actual recorded time in "HH:mm" format
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
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
    vitalView()
}
