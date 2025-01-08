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
    
    @State private var savedFilePath: String? = nil
    
    @State private var showingInfo = false
    @State private var refreshGraph = UUID()
    
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
            
            ScrollView(.vertical) {
                VStack(spacing: 10) {
                    dataSection(title: "Double Support Time", dataAvailable: !healthKitManager.walkingDoubleSupportData.isEmpty, chartKey: "WalkingDoubleSupport", data: healthKitManager.walkingDoubleSupportData, unit: HKUnit.percent(), chartTitle: "Walking Double Support")
                    
                    dataSection(title: "Walking Asymmetry", dataAvailable: !healthKitManager.walkingAsymmetryData.isEmpty, chartKey: "WalkingAsymmetry", data: healthKitManager.walkingAsymmetryData, unit: HKUnit.percent(), chartTitle: "Walking Asymmetry")
                    
                    dataSection(title: "Walking Speed", dataAvailable: !healthKitManager.walkingSpeedData.isEmpty, chartKey: "WalkingSpeed", data: healthKitManager.walkingSpeedData, unit: HKUnit.meter().unitDivided(by: HKUnit.second()), chartTitle: "Walking Speed")
                    
                    dataSection(title: "Step Length", dataAvailable: !healthKitManager.walkingStepLengthData.isEmpty, chartKey: "WalkingStepLength", data: healthKitManager.walkingStepLengthData, unit: HKUnit.meter(), chartTitle: "Walking Step Length")
                    
                    dataSection(title: "Walking Steadiness", dataAvailable: !healthKitManager.walkingSteadinessData.isEmpty, chartKey: "WalkingSteadiness", data: healthKitManager.walkingSteadinessData, unit: HKUnit.percent(), chartTitle: "Walking Steadiness")
                }
                .padding()
            }
            
            Text("Set Start and End-Date to pulled available data:")
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

                        // Call saveDataAsCSV with the server URL
                        healthKitManager.saveDataAsCSV(serverURL: serverURL)
                    } else {
                        healthKitManager.fetchMobilityData(startDate: startDate, endDate: endDate)
                        print("Data pulled, refreshing graph")
                    }
                    isRecording.toggle()
                }) {
                    Text(isRecording ? "Save and Upload Data" : "Pull Data")
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
        .navigationTitle("Mobility Data")
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
                        Text("Start and end date only collect already recorded data from the iOS Health App")
                            .font(.body)
                            .padding()
                            .padding()
                            .foregroundStyle(Color.primary)
                        Spacer()
                        AnimatedSwipeDownCloseView()
                    }
                    .padding()
                }
            }
        }
    }
    
    @ViewBuilder
    private func dataSection(title: String, dataAvailable: Bool, chartKey: String, data: [MobilityStatistics], unit: HKUnit, chartTitle: String) -> some View {
        Section(header: Text(title)
            .font(.title3)) {
            HStack {
                if !isRecording {
                    
                } else {
                    if dataAvailable {
                        Button(action: {
                            showingChart[chartKey] = true
                        }) {
                            Text("Data is Available")
                                .font(.footnote)
                                .foregroundStyle(Color.blue)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        Text("Data is not Available")
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

    @State private var selectedTimeFrameMobility: TimeFrameMobility = .sixMonths
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
    
    @State private var refreshGraph = UUID()

    @State private var precomputedPageData: [TimeFrameMobility: [Int: [ChartDataMobility]]] = [:]
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
            
            Picker("Time Frame", selection: $selectedTimeFrameMobility) {
                ForEach(TimeFrameMobility.allCases, id: \.self) { timeFrame in
                    Text(timeFrame.rawValue).tag(timeFrame)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedTimeFrameMobility) { _, _ in
                updateFilteredData()
            }
            
            HStack {
                Button(action: {
                    showDatePicker = true
                }) {
                    Text(getTitleForCurrentPage(TimeFrameMobility: selectedTimeFrameMobility, page: currentPageForTimeFrameMobilitys[selectedTimeFrameMobility] ?? 0, startDate: startDate, endDate: endDate))
                        .foregroundColor(.primary)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(.white)
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
                .sheet(isPresented: $showDatePicker) {
                    VStack {
                        if selectedTimeFrameMobility == .yearly {
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
                        } else if selectedTimeFrameMobility == .monthly || selectedTimeFrameMobility == .sixMonths {
                            DatePicker("Select Month and Year", selection: $selectedDate, in: startDate...endDate, displayedComponents: [.date])
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .onChange(of: selectedDate) { _, newDate in
                                    let calendar = Calendar.current
                                    let timeZone = TimeZone.current
                                    print("Newly selected date before any adjustments: \(newDate)")
                                    
                                    var components = calendar.dateComponents([.year, .month], from: newDate)
                                    
                                    if let selectedYear = components.year, let selectedMonth = components.month {
                                        print("Selected Year: \(selectedYear), Selected Month: \(selectedMonth)")
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
                
                Text(getTitleForMetric(TimeFrameMobility: selectedTimeFrameMobility, minValue: minValue, maxValue: maxValue, averageValue: averageValue))
                    .font(.footnote)
                    .foregroundColor(.primary)
                
                Text(": ")
                    .foregroundColor(.primary)
                
                Text(getValueText(timeFrame: selectedTimeFrameMobility, minValue: minValue, maxValue: maxValue, averageValue: averageValue))
                    .foregroundColor(.primary)
                
                Text(getUnitForMetric(title: title))
                    .foregroundColor(.primary)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 5)
            
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
            updateFilteredData()
            jumpToPage(for: endDate)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                refreshGraph = UUID()
            }
        }
    }
    
    private func getAvailableTimeFrames(for title: String) -> [TimeFrameMobility] {
        if title == "Walking Steadiness" {
            return TimeFrameMobility.allCases.filter { $0 != .daily && $0 != .weekly }
        } else {
            return TimeFrameMobility.allCases
        }
    }

    private func updateFilteredData() {
        DispatchQueue.global(qos: .userInitiated).async {
            var newPrecomputedData: [Int: [ChartDataMobility]] = [:]
            let pageCount = getPageCount(for: selectedTimeFrameMobility, startDate: startDate, endDate: endDate)

            for page in 0..<pageCount {
                let filtered = filterAndAggregateDataForPage(data, timeFrame: selectedTimeFrameMobility, page: page, startDate: startDate, endDate: endDate, title: title)
                newPrecomputedData[page] = filtered
            }

            let (computedMinValue, computedMaxValue, computedAverageValue) = calculateMinMaxAndAverage(
                for: selectedTimeFrameMobility,
                data: newPrecomputedData[currentPageForTimeFrameMobilitys[selectedTimeFrameMobility] ?? 0] ?? [],
                startDate: startDate,
                endDate: endDate,
                currentPage: currentPageForTimeFrameMobilitys[selectedTimeFrameMobility] ?? 0
            )

            DispatchQueue.main.async {
                precomputedPageData[selectedTimeFrameMobility] = newPrecomputedData
                minValue = computedMinValue
                maxValue = computedMaxValue
                averageValue = computedAverageValue
            }
        }
    }

    private func updateDisplayedData() {
        if let pageData = precomputedPageData[selectedTimeFrameMobility]?[currentPageForTimeFrameMobilitys[selectedTimeFrameMobility] ?? 0] {
            let (computedMinValue, computedMaxValue, computedAverageValue) = calculateMinMaxAndAverage(
                for: selectedTimeFrameMobility,
                data: pageData,
                startDate: startDate,
                endDate: endDate,
                currentPage: currentPageForTimeFrameMobilitys[selectedTimeFrameMobility] ?? 0
            )
            minValue = computedMinValue
            maxValue = computedMaxValue
            averageValue = computedAverageValue
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
            Link("Digital Medicine Society Library of Digital Endpoints", destination: URL(string: "https://dimesociety.org/library-of-digital-endpoints/")!)
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

    private func getValueText(timeFrame: TimeFrameMobility, minValue: Double, maxValue: Double, averageValue: Double) -> String {
        if minValue == 0 && maxValue == 0 && averageValue == 0 {
            return "--"
        }
        
        if minValue == maxValue {
            return "\(String(format: "%.1f", averageValue))"
        } else {
            let rangeText = "(\(String(format: "%.1f", minValue))-\(String(format: "%.1f", maxValue)))"
            return "\(String(format: "%.1f", averageValue)) \(rangeText)"
        }
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
        
    private func calculateMinMaxAndAverage(for timeFrame: TimeFrameMobility, data: [ChartDataMobility], startDate: Date, endDate: Date, currentPage: Int) -> (minValue: Double, maxValue: Double, averageValue: Double) {
        let nonZeroData = data.filter { $0.minValue > 0 }
        
        let minValue = nonZeroData.map { $0.minValue }.min() ?? 0.0
        let maxValue = data.map { $0.maxValue }.max() ?? 0.0

        let validData = data.filter { $0.value > 0 }

        let totalValue = validData.reduce(0) { $0 + $1.value }
        let averageValue = validData.isEmpty ? 0 : totalValue / Double(validData.count)

        return (minValue, maxValue, averageValue)
    }

    private func getTitleForMetric(TimeFrameMobility: TimeFrameMobility, minValue: Double, maxValue: Double, averageValue: Double) -> String {
        
        if minValue == maxValue {
            return "Average"
        } else {
            return " Average (Range)"
        }
    }
    
    private func getInformationText() -> String {
        switch title {
        case "Walking Double Support":
            return "Walking Double Support"
        case "Walking Asymmetry":
            return "Walking Asymmetry"
        case "Walking Speed":
            return "Walking Speed"
        case "Walking Step Length":
            return "Walking Step Length"
        case "Walking Steadiness":
            return "Walking Steadiness"
        default:
            return "Data not available."
        }
    }
    
    private func dataInformation() -> String {
        switch title {
        case "Walking Double Support":
            return "DATA INFORMATION: Percentage of time when both feet are in contact with the found while walking. Only measured when walking on steady ground."
        case "Walking Asymmetry":
            return "DATA INFORMATION: Difference in time spent on each foot during walking. Expressed as a percentage. A low percentage signifies a symmetrical wakling pattern between the left and right foot"
        case "Walking Speed":
            return "DATA INFORMATION: Speed when walking steadily over flat ground"
        case "Walking Step Length":
            return "DATA INFORMATION: Distance between feet during walking"
        case "Walking Steadiness":
            return "DATA INFORMATION: Steadiness of walking calculated using walking speed, step length, double support time and wlaking asymmetry data"
        default:
            return "Data not available."
        }
    }
    
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
            return "USE CASE: Parkinson's disease, stroke recovery, and musculoskeletal disorders"
        case "Walking Asymmetry":
            return "USE CASE: Neurological conditions, stroke recovery, sklerosis and knee injuries"
        case "Walking Speed":
            return "USE CASE: Fraility, parkinson, sklerosis and post surgical recovery"
        case "Walking Step Length":
            return "USE CASE: Parkinson's disease, stroke recovery, musculoskeletal disorders, age-related decline in mobility"
        case "Walking Steadiness":
            return "USE CASE: Balance disorders, parkinson, sklerosis and stroke recovery"
        default:
            return "Data not available."
        }
    }
}
    
    private func getPageCount(for TimeFrameMobility: TimeFrameMobility, startDate: Date, endDate: Date) -> Int {
        let calendar = Calendar.current
        switch TimeFrameMobility {
        case .daily:
            let dayDifference = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
            return max(dayDifference + 1, 1)
        case .weekly:
            let weekDifference = calendar.dateComponents([.weekOfYear], from: startDate, to: endDate).weekOfYear ?? 0
            return max(weekDifference + 1, 1)
        case .monthly:
            let monthDifference = calendar.dateComponents([.month], from: startDate, to: endDate).month ?? 0
            return max(monthDifference + 1, 1)
        case .sixMonths:
            let monthDifference = calendar.dateComponents([.month], from: startDate, to: endDate).month ?? 0
            return max((monthDifference / 6) + 1, 1)
        case .yearly:
            let startYear = calendar.component(.year, from: startDate)
            let endYear = calendar.component(.year, from: endDate)
            return max(endYear - startYear + 1, 1)
        }
    }
    
    private func filterAndAggregateDataForPage(_ data: [ChartDataMobility], timeFrame: TimeFrameMobility, page: Int, startDate: Date, endDate: Date, title: String) -> [ChartDataMobility] {
        let calendar = Calendar.current
        var filteredData: [ChartDataMobility] = []

        switch timeFrame {
        case .daily:
            let pageDate = calendar.date(byAdding: .day, value: page, to: startDate) ?? startDate
            if pageDate <= endDate {
                let hourlyData = aggregateDataByHour(for: pageDate, data: data, endDate: endDate, title: title)
                filteredData = hourlyData
            }
            
        case .weekly:
            let startOfWeek = calendar.date(byAdding: .weekOfYear, value: page, to: startDate) ?? startDate
            if startOfWeek <= endDate {
                let dailyData = (0..<7).compactMap { offset -> ChartDataMobility? in
                    let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek)!
                    return aggregateDataByDay(for: date, data: data, endDate: endDate, title: title)
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
                    if date <= endDate {
                        return aggregateDataByDay(for: date, data: data, endDate: endDate, title: title)
                    }
                    return nil
                }
                filteredData = dailyData
            }
            
        case .sixMonths:
            let startOfSixMonths = calendar.date(byAdding: .month, value: page * 6, to: startDate) ?? startDate
            if startOfSixMonths <= endDate {
                let sixMonthsData = aggregateDataByWeek(for: startOfSixMonths, data: data, weeks: 26, title: title)
                filteredData = sixMonthsData.filter { $0.date <= endDate }
            }
            
        case .yearly:
            let startYear = calendar.component(.year, from: startDate)
            let endYear = calendar.component(.year, from: endDate)
            
            if page < (endYear - startYear + 1) {
                let currentYear = startYear + page
                if let startOfYear = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)),
                   let endOfYear = calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31)) {
                    let yearlyData = aggregateDataByMonth(for: startOfYear, data: data, months: 12, title: title)
                    filteredData = yearlyData.filter { $0.date >= startOfYear && $0.date <= endOfYear }
                }
            }
        }

        return filteredData
    }

    private func aggregateDataByHour(for date: Date, data: [ChartDataMobility], endDate: Date, title: String) -> [ChartDataMobility] {
        let calendar = Calendar.current
        var hourlyData: [ChartDataMobility] = []

        for hour in 0..<24 {
            let startOfHour = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
            let endOfHour = calendar.date(bySettingHour: hour, minute: 59, second: 59, of: date)!

            if startOfHour > endDate {
                break
            }

            let filteredData = data.filter { $0.date >= startOfHour && $0.date <= endOfHour }

            if title == "Walking Asymmetry" {
                let totalValue = filteredData.reduce(0) { $0 + $1.value }
                let averageValue = filteredData.isEmpty ? 0 : totalValue / Double(filteredData.count)
                hourlyData.append(ChartDataMobility(date: startOfHour, minValue: 0, maxValue: 0, value: averageValue))
            } else {
                let minValue = filteredData.map { $0.minValue }.min() ?? 0.0
                let maxValue = filteredData.map { $0.maxValue }.max() ?? 0.0
                let averageValue = (minValue + maxValue) / 2
                hourlyData.append(ChartDataMobility(date: startOfHour, minValue: minValue, maxValue: maxValue, value: averageValue))
            }
        }

        return hourlyData
    }

    private func aggregateDataByDay(for date: Date, data: [ChartDataMobility], endDate: Date, title: String) -> ChartDataMobility {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? endDate

        let filteredData = data.filter { $0.date >= startOfDay && $0.date <= endOfDay }

        if title == "Walking Asymmetry" {
            let totalValue = filteredData.reduce(0) { $0 + $1.value }
            let averageValue = filteredData.isEmpty ? 0 : totalValue / Double(filteredData.count)
            return ChartDataMobility(date: startOfDay, minValue: 0, maxValue: 0, value: averageValue)
        } else {
            let minValue = filteredData.map { $0.minValue }.min() ?? 0.0
            let maxValue = filteredData.map { $0.maxValue }.max() ?? 0.0
            let averageValue = (minValue + maxValue) / 2
            return ChartDataMobility(date: startOfDay, minValue: minValue, maxValue: maxValue, value: averageValue)
        }
    }

    private func aggregateDataByWeek(for startDate: Date, data: [ChartDataMobility], weeks: Int, title: String) -> [ChartDataMobility] {
        let calendar = Calendar.current
        var weeklyData: [ChartDataMobility] = []

        for weekOffset in 0..<weeks {
            let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startDate)!)?.start ?? startDate
            let currentWeekEnd = calendar.date(byAdding: .day, value: 6, to: currentWeekStart)!

            let filteredData = data.filter { $0.date >= currentWeekStart && $0.date <= currentWeekEnd }

            if title == "Walking Asymmetry" {
                let totalValue = filteredData.reduce(0) { $0 + $1.value }
                let averageValue = filteredData.isEmpty ? 0 : totalValue / Double(filteredData.count)
                weeklyData.append(ChartDataMobility(date: currentWeekStart, minValue: 0, maxValue: 0, value: averageValue))
            } else {
                let minValue = filteredData.map { $0.minValue }.min() ?? 0.0
                let maxValue = filteredData.map { $0.maxValue }.max() ?? 0.0
                let averageValue = (minValue + maxValue) / 2
                weeklyData.append(ChartDataMobility(date: currentWeekStart, minValue: minValue, maxValue: maxValue, value: averageValue))
            }
        }

        return weeklyData
    }

    private func aggregateDataByMonth(for startDate: Date, data: [ChartDataMobility], months: Int, title: String) -> [ChartDataMobility] {
        let calendar = Calendar.current
        var monthlyData: [ChartDataMobility] = []

        for monthOffset in 0..<months {
            let currentMonthStart = calendar.date(byAdding: .month, value: monthOffset, to: startDate)!
            let currentMonthEnd = calendar.date(byAdding: .month, value: 1, to: currentMonthStart)!.addingTimeInterval(-1)

            let filteredData = data.filter { $0.date >= currentMonthStart && $0.date <= currentMonthEnd }

            if title == "Walking Asymmetry" {
                let totalValue = filteredData.reduce(0) { $0 + $1.value }
                let averageValue = filteredData.isEmpty ? 0 : totalValue / Double(filteredData.count)
                monthlyData.append(ChartDataMobility(date: currentMonthStart, minValue: 0, maxValue: 0, value: averageValue))
            } else {
                let minValue = filteredData.map { $0.minValue }.min() ?? 0.0
                let maxValue = filteredData.map { $0.maxValue }.max() ?? 0.0
                let averageValue = (minValue + maxValue) / 2
                monthlyData.append(ChartDataMobility(date: currentMonthStart, minValue: minValue, maxValue: maxValue, value: averageValue))
            }
        }

        return monthlyData
    }

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
    @State private var isLoading: Bool = true

    var body: some View {
        VStack(alignment: .center) {

            if isLoading {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(2)
                        .padding()
                    
                    Text("Pulling Data...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isLoading = false
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
                            if item.value != 0 {
                                PointMark(
                                    x: .value("Date", item.date),
                                    y: .value("Value", item.value)
                                )
                                .symbolSize(25)
                            }
                        }
                        else if title == "Walking Steadiness" && timeFrame == .yearly {
                            let adjustedMinValue = item.minValue != 0 ? item.minValue - 1 : item.minValue
                            BarMark(
                                x: .value("Date", item.date),
                                yStart: .value("Min", adjustedMinValue),
                                yEnd: .value("Max", item.maxValue)
                            )
                            .offset(x: getOffsetForTimeFrame(timeFrame))
                        }
                        
                        else if title == "Walking Asymmetry" {
                            LineMark(
                                x: .value("Date", item.date),
                                y: .value("Average", item.value)
                            )
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", item.date),
                                y: .value("Average", item.value)
                            )
                            .symbolSize(25)
                        }
                        else if item.minValue == item.maxValue {
                            let adjustedMinValue = item.minValue != 0 ? item.minValue - 1 : item.minValue
                            BarMark(
                                x: .value("Date", item.date),
                                yStart: .value("Min", adjustedMinValue),
                                yEnd: .value("Max", item.maxValue)
                            )
                        }
                        else {
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
                        AxisMarks(values: [0, 20, 40, 100]) {
                            AxisGridLine()
                        }

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

                ScrollView {
                    ForEach(timeFrame == .weekly ? Array(data.prefix(7)) : data) { item in
                        HStack {
                            Text(formatDateForTimeFrame(item.date)) 
                            Spacer()
                            
                            VStack {
                                if title == "Walking Asymmetry" && item.value != 0 {
                                    Text(item.value == 0 ? "--" : "\(String(format: "%.1f", item.value)) %")
                                } else if item.minValue == item.maxValue {
                                    Text(item.value == 0 ? "--" : "\(String(format: "%.1f", item.value)) (\(String(format: "%.1f", item.minValue))-\(String(format: "%.1f", item.maxValue)))")
                                } else {
                                    Text(item.value == 0 ? "--" : "\(String(format: "%.1f", item.value)) (\(String(format: "%.1f", item.minValue))-\(String(format: "%.1f", item.maxValue)))")
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
   }

    private func getFormattedText(minValue: Double, maxValue: Double, value: Double) -> String {
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

        if title == "Walking Asymmetry" {
            return "\(String(format: "%.1f", value)) \(unit)"
        } else {
            if minValue == maxValue {
                return "\(String(format: "%.1f", maxValue)) \(unit)"
            } else {
                return "\(String(format: "%.1f", minValue))-\(String(format: "%.1f", maxValue)) \(unit)"
            }
        }
    }
    
    private func getOffsetForTimeFrame(_ timeFrame: TimeFrameMobility) -> CGFloat {
            switch timeFrame {
            case .daily:
                return 6
            case .weekly:
                return 20
            case .monthly:
                return 5
            case .sixMonths:
                return 0
            case .yearly:
                return 11.5
            }
        }

    private func formatDateForTimeFrame(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        switch timeFrame {
        case .daily:
            formatter.dateFormat = "HH:mm"
            let startHour = formatter.string(from: date)
            let endHour = formatter.string(from: calendar.date(byAdding: .hour, value: 1, to: date) ?? date)
            return "\(startHour) - \(endHour)"
        
        case .weekly:
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        
        case .monthly:
            formatter.dateFormat = "d"
            let day = formatter.string(from: date)
            return day + ordinalSuffix(for: day)
        
        case .sixMonths:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? date
            formatter.dateFormat = "MMM dd"

            let startDate = formatter.string(from: startOfWeek)
            let endDate = formatter.string(from: endOfWeek)

            return "\(startDate) - \(endDate)"
        
        case .yearly:
            formatter.dateFormat = "MMM"
            return formatter.string(from: date)
        }
    }

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
    
    private func getXScaleDomain() -> ClosedRange<Date> {
        let calendar = Calendar.current
        guard let firstDate = data.first?.date, let lastDate = data.last?.date else {
            return Date()...Date()
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
