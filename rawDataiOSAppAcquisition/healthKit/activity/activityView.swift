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
    
    @State private var refreshGraph = UUID()
    
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
                    dataSection(title: "Stand Time", dataAvailable: !healthKitManager.appleStandTimeData.isEmpty, chartKey: "StandTime", data: healthKitManager.appleStandTimeData, unit: HKUnit.minute(), chartTitle: "Stand Time (min)")
                    dataSection(title: "Distance Walking/Running", dataAvailable: !healthKitManager.distanceWalkingRunningData.isEmpty, chartKey: "DistanceWalkingRunning", data: healthKitManager.distanceWalkingRunningData, unit: HKUnit.meter(), chartTitle: "Distance Walking/Running (Km)")
                    dataSection(title: "Exercise Time", dataAvailable: !healthKitManager.appleExerciseTimeData.isEmpty, chartKey: "ExerciseTime", data: healthKitManager.appleExerciseTimeData, unit: HKUnit.minute(), chartTitle: "Exercise Time (min)")
                }
                .padding([.leading, .bottom, .trailing])
            }
            .onAppear {
                print("View appeared, forcing data pull and refresh")
                healthKitManager.fetchActivityData(startDate: startDate, endDate: endDate)
                refreshGraph = UUID()
                
            }
            .onChange(of: healthKitManager.stepCountData) { _, newData in
                print("Step count data changed, forcing graph refresh")
                refreshGraph = UUID()
            }
            
            Text("Set Start and End-Date to pull available data:")
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
                        let serverURL = ServerConfig.serverURL
                        print("serverURL is \(serverURL)")
                        
                        healthKitManager.saveDataAsCSV(serverURL: serverURL)
                    } else {
                        healthKitManager.fetchActivityData(startDate: startDate, endDate: endDate)
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
        .navigationTitle("Activity Data")
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
    private func dataSection(title: String, dataAvailable: Bool, chartKey: String, data: [HKQuantitySample], unit: HKUnit, chartTitle: String) -> some View {
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
                        ChartWithTimeFramePicker(title: chartTitle, data: data.map {
                            ChartDataactivity(date: $0.startDate, value: $0.quantity.doubleValue(for: unit))
                        }, startDate: healthKitManager.startDate, endDate: healthKitManager.endDate)
                            .id(refreshGraph)
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

    @State private var precomputedPageData: [TimeFrame: [Int: [ChartDataactivity]]] = [:]
    @State private var sum: Double = 0
    @State private var average: Double = 0

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
                Button(action: {
                    showDatePicker = true
                }) {
                    Text(getTitleForCurrentPage(timeFrame: selectedTimeFrame, page: currentPageForTimeFrames[selectedTimeFrame] ?? 0, startDate: startDate, endDate: endDate))
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
                        if selectedTimeFrame == .yearly {
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
                
                Text(getTitleForMetric(timeFrame: selectedTimeFrame))
                    .font(.footnote)
                    .foregroundColor(.primary)
                
                Text(": ")
                    .foregroundColor(.primary)
                
                Text(getValueText(timeFrame: selectedTimeFrame, sum: sum, average: average))
                    .foregroundColor(.primary)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 5)
            
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
                            .id(refreshGraph)
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
            DispatchQueue.main.async {
                updateFilteredData()
                jumpToPage(for: endDate)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    refreshGraph = UUID() 
                }
            }
        }
    }

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

    private func getValueText(timeFrame: TimeFrame, sum: Double, average: Double) -> String {
        let unit = getUnitForMetric(title: title) // Get the unit based on the title
        
        switch (title, timeFrame) {
        case ("Active Energy Burned in KiloCalorie", .daily):
            return sum == 0 ? "-- \(unit)" : "\(String(format: "%.1f", sum / 1000)) \(unit)"
            
        case ("Active Energy Burned in KiloCalorie", _):
            return average == 0 ? "-- \(unit)" : "\(String(format: "%.0f", average / 1000)) \(unit)"
            
        case ("Step Count", .daily):
            return sum == 0 ? "-- \(unit)" : "\(String(format: "%.0f", sum)) \(unit)"
            
        case ("Step Count", _):
            return average == 0 ? "-- \(unit)" : "\(String(format: "%.0f", average)) \(unit)"
            
        case ("Stand Time (min)", .daily):
            return sum == 0 ? "-- \(unit)" : "\(String(format: "%.0f", sum)) \(unit)"
            
        case ("Stand Time (min)", _):
            return average == 0 ? "-- \(unit)" : "\(String(format: "%.0f", average)) \(unit)"
            
        case ("Distance Walking/Running (Km)", .daily):
            return sum == 0 ? "-- \(unit)" : "\(String(format: "%.2f", sum / 1000)) \(unit)"
            
        case ("Distance Walking/Running (Km)", _):
            return average == 0 ? "-- \(unit)" : "\(String(format: "%.1f", average / 1000)) \(unit)"
            
        case ("Exercise Time (min)", .daily):
            return sum == 0 ? "-- \(unit)" : "\(String(format: "%.0f", sum)) \(unit)"
            
        case ("Exercise Time (min)", _):
            return average == 0 ? "-- \(unit)" : "\(String(format: "%.0f", average)) \(unit)"
            
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

        let filteredData = data.filter { $0.date >= intervalStartDate && $0.date <= intervalEndDate && $0.value > 0 }

        for entry in filteredData {
            totalSum += entry.value
            
            dataPointsCount += 1
        }

        let average = dataPointsCount > 0 ? totalSum / Double(dataPointsCount) : 0

        print("Data points count: \(dataPointsCount)")
        print("Total Sum: \(totalSum)")

        return (sum: totalSum, average: average)
    }

    private func getTitleForMetric(timeFrame: TimeFrame) -> String {
        let description: String
        
        switch title {
        case "Step Count":
            switch timeFrame {
            case .daily:
                description = "Total"
            case .weekly:
                description = "Average"
            case .sixMonths:
                description = "Daily average"
            case .yearly:
                description = "Daily average"
            default:
                description = "Average"
            }
            
        case "Active Energy Burned in KiloCalorie":
            switch timeFrame {
            case .daily:
                description = "Total"
            case .weekly:
                description = "Average"
            case .sixMonths:
                description = "Daily average"
            case .yearly:
                description = "Daily average"
            default:
                description = "Average"
            }
            
        case "Move Time (min)":
            switch timeFrame {
            case .daily:
                description = "Total"
            case .weekly:
                description = "Average"
            case .sixMonths:
                description = "Daily average"
            case .yearly:
                description = "Daily average"
            default:
                description = "Average"
            }
            
        case "Stand Time (min)":
            switch timeFrame {
            case .daily:
                description = "Total"
            case .weekly:
                description = "Average"
            case .sixMonths:
                description = "Daily average"
            case .yearly:
                description = "Daily average"
            default:
                description = "Average"
            }
            
        case "Distance Walking/Running (Km)":
            switch timeFrame {
            case .daily:
                description = "Total"
            case .weekly:
                description = "Average"
            case .sixMonths:
                description = "Daily average"
            case .yearly:
                description = "Daily average"
            default:
                description = "Average"
            }
            
        case "Exercise Time (min)":
            switch timeFrame {
            case .daily:
                description = "Total"
            case .weekly:
                description = "Average"
            case .sixMonths:
                description = "Daily average"
            case .yearly:
                description = "Daily average"
            default:
                description = "Average"
            }
            
        default:
            switch timeFrame {
            case .daily:
                description = "Total"
            case .weekly:
                description = "Average"
            case .sixMonths:
                description = "Daily average"
            case .yearly:
                description = "Daily average"
            default:
                description = "Average"
            }
        }
        
        return description
    }

    private func getInformationText() -> String {
        switch title {
        case "Step Count":
            return "Step Count"
        case "Active Energy Burned in KiloCalorie":
            return "Active Energy Burned"
        case "Move Time (min)":
            return ""
        case "Stand Time (min)":
            return "Stand Time"
        case "Distance Walking/Running (Km)":
            return "Distance Walking/Running"
        case "Exercise Time (min)":
            return "Exercise Time"
        default:
            return "Data not available."
        }
    }
    
    private func dataInformation() -> String {
        switch title {
        case "Step Count":
            return "DATA INFORMATION: Number of steps taken"
        case "Active Energy Burned in KiloCalorie":
            return "DATA INFORMATION: Energy burned through physical activity, excluding energy burned at rest (basal metabolic rate)"
        case "Move Time (min)":
            return ""
        case "Stand Time (min)":
            return "DATA INFORMATION: Time spent standing"
        case "Distance Walking/Running (Km)":
            return "DATA INFORMATION: Distance covered walking or running"
        case "Exercise Time (min)":
            return "DATA INFORMATION: Time spent exercising"
        default:
            return "More information about this section is not available."
        }
    }
    
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
            return "USE CASE: Cardiovascular disease, diabetes, Parkinson's disease, musculoskeletal disorders"
        case "Active Energy Burned in KiloCalorie":
            return "USE CASE: Weight management, metabolic disorders, cardiovascular disease, and diabetes"
        case "Move Time (min)":
            return "USE CASE: Cardiovascular disease, Obesity and Diabetes"
        case "Stand Time (min)":
            return "USE CASE: Sedentary time, cardiovascular disease, diabetes, obesity"
        case "Distance Walking/Running (Km)":
            return "USE CASE: Cardiovascular disease, post-surgical rehabilitation, diabetes"
        case "Exercise Time (min)":
            return "USE CASE: Cardiovascular disease, diabetes, mental health"
        default:
            return "More information about this section is not available."
        }
    }
}
    
    private func getPageCount(for timeFrame: TimeFrame, startDate: Date, endDate: Date) -> Int {
        let calendar = Calendar.current
        switch timeFrame {
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
                
                let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: pageDate))!
                
                let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
                let numberOfDaysInMonth = range.count
                
                let dailyData = (0..<numberOfDaysInMonth).map { offset -> ChartDataactivity in
                    let date = calendar.date(byAdding: .day, value: offset, to: startOfMonth)!
                    return aggregateDataByDay(for: date, data: data)
                }
                filteredData = dailyData
                
            case .sixMonths:
                let startOfSixMonths = calendar.date(byAdding: .month, value: (page * 6), to: startDate) ?? startDate
                
                let sixMonthsData = aggregateDataByWeek(for: startOfSixMonths, data: data, weeks: 26)
                filteredData = sixMonthsData

            case .yearly:
                let startYear = calendar.component(.year, from: startDate)
                let endYear = calendar.component(.year, from: endDate)
                
                if page < (endYear - startYear + 1) {
                    let currentYear = startYear + page
                    if let startOfYear = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)),
                       let endOfYear = calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31)) {
                        let yearlyData = aggregateDataByMonth(for: startOfYear, data: data, months: 12)
                        filteredData = yearlyData.filter { $0.date >= startOfYear && $0.date <= endOfYear }
                    }
                }
            }
                
            return filteredData
        }

    private func aggregateDataByHour(for date: Date, data: [ChartDataactivity], endDate: Date) -> [ChartDataactivity] {
        let calendar = Calendar.current
        var hourlyData: [ChartDataactivity] = []

        for hour in 0..<24 {
            let startOfHour = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
            let endOfHour = calendar.date(bySettingHour: hour, minute: 59, second: 59, of: date)!

            if startOfHour > endDate {
                break
            }

            let filteredData = data.filter { $0.date >= startOfHour && $0.date <= endOfHour }

            let hourlySum = filteredData.map { $0.value }.reduce(0, +)

            hourlyData.append(ChartDataactivity(date: startOfHour, value: hourlySum))
        }

        return hourlyData
    }

    private func aggregateDataByDay(for date: Date, data: [ChartDataactivity]) -> ChartDataactivity {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)!

        var dailyValue = 0.0

        for item in data {
            let sampleStart = item.date
            let sampleEnd = calendar.date(byAdding: .second, value: Int(item.value), to: sampleStart) ?? sampleStart

            if sampleStart <= endOfDay && sampleEnd >= startOfDay {
                let overlapStart = max(sampleStart, startOfDay)
                let overlapEnd = min(sampleEnd, endOfDay)

                let overlapDuration = overlapEnd.timeIntervalSince(overlapStart)
                let totalDuration = sampleEnd.timeIntervalSince(sampleStart)

                let proportion = overlapDuration / totalDuration
                dailyValue += item.value * proportion
            }
        }

        return ChartDataactivity(date: startOfDay, value: dailyValue)
    }

    private func aggregateDataByWeek(for startDate: Date, data: [ChartDataactivity], weeks: Int) -> [ChartDataactivity] {
        let calendar = Calendar.current
        var weeklyData: [ChartDataactivity] = []

        for weekOffset in 0..<weeks {
            let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startDate)!)?.start ?? startDate
            let currentWeekEnd = calendar.date(byAdding: .day, value: 6, to: currentWeekStart)!

            var weeklyValue = 0.0
            var daysWithData = Set<Date>()
            
            for item in data {
                let sampleStart = item.date
                let sampleEnd = calendar.date(byAdding: .second, value: Int(item.value), to: sampleStart) ?? sampleStart

                if sampleStart <= currentWeekEnd && sampleEnd >= currentWeekStart {
                    let overlapStart = max(sampleStart, currentWeekStart)
                    let overlapEnd = min(sampleEnd, currentWeekEnd)

                    let overlapDuration = overlapEnd.timeIntervalSince(overlapStart)
                    let totalDuration = sampleEnd.timeIntervalSince(sampleStart)

                    let proportion = overlapDuration / totalDuration
                    weeklyValue += item.value * proportion

                    var overlapDate = calendar.startOfDay(for: overlapStart)
                    while overlapDate <= overlapEnd {
                        daysWithData.insert(overlapDate)
                        overlapDate = calendar.date(byAdding: .day, value: 1, to: overlapDate)!
                    }
                }
            }

            let dailyAverage = daysWithData.count > 0 ? weeklyValue / Double(daysWithData.count) : 0.0

            weeklyData.append(ChartDataactivity(date: currentWeekStart, value: dailyAverage))
        }

        return weeklyData
    }

    private func aggregateDataByMonth(for startDate: Date, data: [ChartDataactivity], months: Int) -> [ChartDataactivity] {
        let calendar = Calendar.current
        var monthlyData: [ChartDataactivity] = []
        
        for monthOffset in 0..<months {
            let currentMonthStart = calendar.date(byAdding: .month, value: monthOffset, to: startDate)!
            let currentMonthEnd = calendar.date(byAdding: .month, value: 1, to: currentMonthStart)!.addingTimeInterval(-1)
            
            var monthlyValue = 0.0
            var daysWithData = Set<Date>()

            for item in data {
                let sampleStart = item.date
                let sampleEnd = calendar.date(byAdding: .second, value: Int(item.value), to: sampleStart) ?? sampleStart

                if sampleStart <= currentMonthEnd && sampleEnd >= currentMonthStart {
                    let overlapStart = max(sampleStart, currentMonthStart)
                    let overlapEnd = min(sampleEnd, currentMonthEnd)

                    let overlapDuration = overlapEnd.timeIntervalSince(overlapStart)
                    let totalDuration = sampleEnd.timeIntervalSince(sampleStart)

                    let proportion = overlapDuration / totalDuration
                    monthlyValue += item.value * proportion

                    var overlapDate = calendar.startOfDay(for: overlapStart)
                    while overlapDate <= overlapEnd {
                        daysWithData.insert(overlapDate)
                        overlapDate = calendar.date(byAdding: .day, value: 1, to: overlapDate)!
                    }
                }
            }
            
            let dailyAverage = daysWithData.count > 0 ? monthlyValue / Double(daysWithData.count) : 0.0

            monthlyData.append(ChartDataactivity(date: currentMonthStart, value: dailyAverage))
        }
        
        return monthlyData
    }

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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
                        BarMark(
                            x: .value("Date", item.date),
                            y: .value("Value", (title == "Active Energy Burned in KiloCalorie" || title == "Distance Walking/Running (Km)") ? item.value / 1000 : item.value)
                        )
                        .offset(x: getOffsetForTimeFrame(timeFrame))
                    }
                }
                .id(UUID())
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
                            Text(formatDateForTimeFrame(item.date))
                            Spacer()
                            
                            if title == "Active Energy Burned in KiloCalorie" {
                                VStack {
                                    
                                    if timeFrame == .yearly || timeFrame == .sixMonths {
                                        Text("Daily average")
                                            .font(.caption2)
                                    } else if timeFrame == .monthly || timeFrame == .weekly || timeFrame == .daily {
                                        Text("Total")
                                            .font(.caption2)
                                    }

                                    HStack {
                                        Text(item.value == 0 ? "--" : "\(String(format: "%.0f", item.value / 1000))")
                                        Text("kcal")
                                    }
                                }
                            }
                            
                            if title == "Step Count" {
                                VStack {
                                    if timeFrame == .yearly || timeFrame == .sixMonths {
                                        Text("Daily average")
                                            .font(.caption2)
                                    } else if timeFrame == .monthly || timeFrame == .weekly || timeFrame == .daily {
                                        Text("Total")
                                            .font(.caption2)
                                    }

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
            print("BoxChartViewActivity appeared with new data")
        }
    }

        private func getOffsetForTimeFrame(_ timeFrame: TimeFrame) -> CGFloat {
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
                return 12.5
            }
        }

    private func formatDateForTimeFrame(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        switch timeFrame {
        case .daily:
            
            formatter.dateFormat = "HH"
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
                return firstDate...lastDate
            }
        }
    }

#Preview {
    activityView()
}
