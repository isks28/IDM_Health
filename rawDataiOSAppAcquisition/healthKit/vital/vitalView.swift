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

enum VitalTimeFrame: String, CaseIterable {
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
    
    // State variables to control sheet presentation
    @State private var showingHeartRateChart = false
    
    init() {
        _vitalManager = StateObject(wrappedValue: VitalManager(startDate: Date(), endDate: Date()))
        _startDate = State(initialValue: Date())
        _endDate = State(initialValue: Date())
    }
    
    var body: some View {
        VStack {
            Text("Vital Health Data")
                .font(.largeTitle)
                
            Text("To be fetched Data:")
                .font(.headline)
                .padding(.top)
            
            ScrollView {
                VStack {
                    // Heart Rate Section with info button
                    Section(header: Text("Heart Rate")) {
                        HStack {
                            if !vitalManager.heartRateData.isEmpty {
                                Text("Heart Rate Data is Available")
                                    .foregroundStyle(Color.mint)
                                    .multilineTextAlignment(.center)
                            }
                            Button(action: {
                                showingHeartRateChart = true
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(Color.pink)
                            }
                            .sheet(isPresented: $showingHeartRateChart) {
                                VitalChartWithTimeFramePicker(
                                    title: "Heart Rate",
                                    data: vitalManager.heartRateData.map {
                                        ChartDataVital(date: $0.date, minValue: $0.minValue, maxValue: $0.maxValue, averageValue: $0.averageValue)
                                    },
                                    startDate: vitalManager.startDate,
                                    endDate: vitalManager.endDate
                                )
                            }
                        }
                        .padding(.bottom, 10)
                    }
                }
                .padding(.horizontal)
            }
            Text("Set Start and End-Date of Data to be fetched:")
                .font(.headline)
                .padding(.top, 50)
            
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                .onChange(of: startDate) {
                    vitalManager.startDate = startDate
                }
            
            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                .onChange(of: endDate) {
                    vitalManager.endDate = endDate
                }

            Spacer()

            HStack {
                Button(action: {
                    if isRecording {
                        vitalManager.saveDataAsCSV()
                    } else {
                        vitalManager.fetchRawHeartRateData(startDate: startDate, endDate: endDate)
                    }
                    isRecording.toggle()
                }) {
                    Text(isRecording ? "Save Data" : "Fetch Data")
                        .padding()
                        .background(isRecording ? Color.gray : Color.mint)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    if vitalManager.savedFilePath != nil {
                        Text("File saved")
                            .font(.footnote)
                    }
                }
                .padding() // Ensure button is visible
            }
        }
        .padding()
    }
}

struct VitalChartWithTimeFramePicker: View {
    var title: String
    var data: [ChartDataVital]
    var startDate: Date
    var endDate: Date
    
    @State private var selectedTimeFrame: VitalTimeFrame = .daily
    @State private var currentPageForTimeFrames: [VitalTimeFrame: Int] = [
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
                    VStack(alignment: .leading) {
                        Text("Additional Information")
                            .font(.title)
                            .padding(.bottom, 7)
                            .foregroundStyle(Color.pink)
                        Text("Heart rate data is measured using optical sensors on Apple devices.")
                            .font(.body)
                            .padding(.bottom, 3)
                        Text("Use this data to monitor cardiovascular health, fitness, and recovery.")
                            .font(.body)
                            .padding(.bottom, 3)
                    }
                    .frame(width: 300, height: 200)
                }
            }
            .padding(.horizontal)

            Picker("Time Frame", selection: $selectedTimeFrame) {
                ForEach(VitalTimeFrame.allCases, id: \.self) { timeFrame in
                    Text(timeFrame.rawValue).tag(timeFrame)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            // Title with clickable functionality to show date picker
            Button(action: {
                showDatePicker = true
            }) {
                Text(getTitleForCurrentPage(timeFrame: selectedTimeFrame, page: currentPageForTimeFrames[selectedTimeFrame] ?? 0, startDate: startDate, endDate: endDate))
                    .font(.title2)
                    .padding(.bottom, 8)
            }
            .sheet(isPresented: $showDatePicker) {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    in: startDate...endDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .onChange(of: selectedDate) { _, newDate in
                    jumpToPage(for: selectedDate)
                }
                .padding()
            }

            let filteredData = filterAndAggregateDataForPage(
                data,
                timeFrame: selectedTimeFrame,
                page: currentPageForTimeFrames[selectedTimeFrame] ?? 0,
                startDate: startDate,
                endDate: endDate
            )

            let (sum, average) = calculateAverage(for: selectedTimeFrame, data: filteredData)

            Text("Average Heart Rate in BPM")
                .font(.headline)

            Text(sum == 0 ? "--" : "\(String(format: "%.0f", selectedTimeFrame == .daily ? average : average)) BPM")
                .font(.headline)
                .foregroundStyle(Color.mint)

            TabView(selection: Binding(
                get: { currentPageForTimeFrames[selectedTimeFrame] ?? 0 },
                set: { newValue in currentPageForTimeFrames[selectedTimeFrame] = newValue }
            )) {
                if !data.isEmpty {
                    ForEach((0..<getPageCount(for: selectedTimeFrame, startDate: startDate, endDate: endDate)), id: \.self) { page in
                        BoxChartViewVital(data: filterAndAggregateDataForPage(data, timeFrame: selectedTimeFrame, page: page, startDate: startDate, endDate: endDate), timeFrame: selectedTimeFrame, title: title)
                            .tag(page)
                            .padding()
                    }
                } else {
                    Text("No Data")
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .padding(.bottom)

            Spacer()
        }
        .padding()
    }

    private func jumpToPage(for date: Date) {
        let calendar = Calendar.current
        switch selectedTimeFrame {
        case .hourly:
            let hoursDifference = calendar.dateComponents([.hour], from: startDate, to: date).hour ?? 0
            currentPageForTimeFrames[selectedTimeFrame] = max(hoursDifference, 0)
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
    
    private func calculateAverage(for timeFrame: VitalTimeFrame, data: [ChartDataVital]) -> (sum: Double, average: Double) {
        let totalSum = data.map { $0.averageValue }.reduce(0, +)
        
        // Count only the data points that have a value greater than 0
        let nonZeroDataCount = data.filter { $0.averageValue > 0 }.count
        
        let count: Int
        count = nonZeroDataCount > 0 ? nonZeroDataCount : 1  // Avoid division by zero
        
        // Calculate the average only if we have valid data points
        let average = count > 0 ? totalSum / Double(count) : 0.0
        return (sum: totalSum, average: average)
    }
    
    private func getPageCount(for timeFrame: VitalTimeFrame, startDate: Date, endDate: Date) -> Int {
        let calendar = Calendar.current
        switch timeFrame {
        case .hourly:
            // Calculate hours between start and end dates
            let hourDifference = calendar.dateComponents([.hour], from: startDate, to: endDate).hour ?? 0
            return max(hourDifference, 1) // Ensure at least 1 page
        case .daily:
            // Calculate days between start and end dates
            let dayDifference = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
            return max(dayDifference, 1) // Ensure at least 1 page
        case .weekly:
            // Calculate weeks between start and end dates
            let weekDifference = calendar.dateComponents([.weekOfYear], from: startDate, to: endDate).weekOfYear ?? 0
            return max(weekDifference, 1) // Ensure at least 1 page
        case .monthly:
            // Calculate months between start and end dates
            let monthDifference = calendar.dateComponents([.month], from: startDate, to: endDate).month ?? 0
            return max(monthDifference, 1) // Ensure at least 1 page
        case .sixMonths:
            // Calculate 6-month intervals between start and end dates
            let monthDifference = calendar.dateComponents([.month], from: startDate, to: endDate).month ?? 0
            return max(monthDifference / 6, 1) // Ensure at least 1 page
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
    private func getTitleForCurrentPage(timeFrame: VitalTimeFrame, page: Int, startDate: Date, endDate: Date) -> String {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        var title: String = ""
        
        switch timeFrame {
        case .hourly:
            // Round the start date to the nearest full hour
            let startHour = calendar.date(byAdding: .hour, value: page, to: floorDateToHour(startDate)) ?? startDate
            let endHour = calendar.date(byAdding: .hour, value: 1, to: startHour) ?? startHour
            
            // Format the date and time range for the title
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
    private func filterAndAggregateDataForPage(_ data: [ChartDataVital], timeFrame: VitalTimeFrame, page: Int, startDate: Date, endDate: Date) -> [ChartDataVital] {
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
    var timeFrame: VitalTimeFrame
    var title: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)

            if data.allSatisfy({ $0.minValue == 0 && $0.maxValue == 0}) {
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
                .foregroundStyle(Color.pink)
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
                            Text(formatDateForTimeFrame(item.date))
                            Spacer()
                            if timeFrame == .hourly {
                                // For the hourly view, display the raw heart rate value
                                Text("\(String(format: "%.0f", item.averageValue)) BPM")  // Display the raw heart rate value
                            } else {
                                // For other views, show min-max range
                                if item.minValue == 0 && item.maxValue == 0 {
                                    Text("-- BPM")
                                } else {
                                    Text("\(String(format: "%.0f", item.minValue)) - \(String(format: "%.0f", item.maxValue)) BPM")
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 3)
                        .padding(.horizontal)
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .shadow(radius: 5)
    }

    private func getOffsetForTimeFrame(_ timeFrame: VitalTimeFrame) -> CGFloat {
        switch timeFrame {
        case .hourly:
            return 8
        case .daily:
            return 6
        case .weekly:
            return 20
        case .monthly:
            return 5
        case .sixMonths:
            return 0
        case .yearly:
            return 10
        }
    }

    private func formatDateForTimeFrame(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        switch timeFrame {
        case .hourly:
            // For hourly, display the actual recorded time in "HH:mm" format
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        case .daily:
            formatter.dateFormat = "HH"
            let startHour = formatter.string(from: date)
            let endHour = formatter.string(from: calendar.date(byAdding: .hour, value: 1, to: date) ?? date)
            return "\(startHour)-\(endHour)"
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
            return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
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
    
    // Function to round the date down to the nearest hour
    private func floorDateToHour(_ date: Date) -> Date {
        let calendar = Calendar.current
        // Round down the date to the nearest full hour (setting minutes and seconds to 0)
        return calendar.date(bySettingHour: calendar.component(.hour, from: date), minute: 0, second: 0, of: date) ?? date
    }

    // Function to round the date up to the next full hour
    private func ceilDateToHour(_ date: Date) -> Date {
        let calendar = Calendar.current
        // Round the date up to the next full hour
        let flooredDate = floorDateToHour(date)
        if date > flooredDate {
            return calendar.date(byAdding: .hour, value: 1, to: flooredDate) ?? date
        }
        return flooredDate
    }

    private func getXScaleDomain() -> ClosedRange<Date> {
        let calendar = Calendar.current
        guard let firstDate = data.first?.date, let lastDate = data.last?.date else {
            // No data case, default to showing the current hour
            let now = Date()
            let startOfCurrentHour = floorDateToHour(now)
            let endOfCurrentHour = calendar.date(byAdding: .hour, value: 1, to: startOfCurrentHour)!
            return startOfCurrentHour...endOfCurrentHour
        }

        if timeFrame == .hourly {
            // Calculate the specific hour to start at the earliest data point
            let startHour = floorDateToHour(firstDate)
            
            // Calculate the end hour as 1 hour after the last data point
            let endHour = ceilDateToHour(lastDate)
            
            // Return the startHour...endHour for the X-axis domain
            return startHour...endHour
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
        return firstDate...lastDate
    }
}

#Preview {
    vitalView()
}
