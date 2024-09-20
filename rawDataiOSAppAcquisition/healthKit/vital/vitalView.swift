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
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 1
        let customStartDate = calendar.date(from: components) ?? Date()
        
        _vitalManager = StateObject(wrappedValue: VitalManager(startDate: Date(), endDate: Date()))
        _startDate = State(initialValue: customStartDate)
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
                                VitalChartWithTimeFramePicker(title: "Heart Rate", data: vitalManager.heartRateData.map { ChartDataVital(date: $0.date, minValue: $0.minValue, maxValue: $0.maxValue, averageValue: $0.averageValue) })
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
    
    // State to control the selected time frame
    @State private var selectedTimeFrame: VitalTimeFrame = .daily
    
    // Dictionary to track the current page for each time frame independently
    @State private var currentPageForTimeFrames: [VitalTimeFrame: Int] = [
        .hourly: 0,
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
            // Display additional information based on the selected section
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
            
            // Picker for selecting the time frame
            Picker("Time Frame", selection: $selectedTimeFrame) {
                ForEach(VitalTimeFrame.allCases, id: \.self) { timeFrame in
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
            let (sum, average) = calculateAverage(for: selectedTimeFrame, data: filteredData)

            // Display correct title for total or average
            Text("Average Heart Rate in BPM")
                .font(.headline)

            // Show total for daily view, average for others
            Text(sum == 0 ? "--" : "\(String(format: "%.0f", selectedTimeFrame == .daily ? average : average)) BPM")
                .font(.headline)
                .foregroundStyle(Color.mint)
            
            // Display the chart with horizontal paging
            TabView(selection: Binding(
                get: { currentPageForTimeFrames[selectedTimeFrame] ?? 0 },
                set: { newValue in
                    currentPageForTimeFrames[selectedTimeFrame] = newValue
                }
            )) {
                if !data.isEmpty {
                    ForEach((0..<getPageCount(for: selectedTimeFrame)).reversed(), id: \.self) { page in
                        BoxChartViewVital(data: filterAndAggregateDataForPage(data, timeFrame: selectedTimeFrame, page: page), timeFrame: selectedTimeFrame, title: title)
                            .tag(page)
                            .padding(.horizontal)
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
    
    // Function to dynamically adjust the number of pages based on time frame
    private func getPageCount(for timeFrame: VitalTimeFrame) -> Int {
        switch timeFrame {
        case .hourly:
            return 24 // 24 pages for 1 full day
        case .daily:
            return 14  // 14 pages for daily (two week)
        case .weekly:
            return 12  // 12 pages for weekly (three month)
        case .monthly:
            return 12 // 12 pages for monthly (one year)
        case .sixMonths:
            return 4  // 6 pages for 2 years
        case .yearly:
            return 1  // 1 years
        }
    }
    
    // Function to get the title for the current page based on the time frame
    private func getTitleForCurrentPage(timeFrame: VitalTimeFrame, page: Int) -> String {
        let calendar = Calendar.current
        let now = Date()
        let dateFormatter = DateFormatter()
        var title: String = ""
        
        switch timeFrame {
        case .hourly:
            // Get the current time
            let now = Date()
            
            // Calculate the next full hour from the current time (e.g., if now is 15:43, this will return 16:00)
            let nextFullHour = calendar.date(bySettingHour: calendar.component(.hour, from: now) + 1, minute: 0, second: 0, of: now) ?? now
            
            // Calculate the specific hour by adding 'page' to the next full hour
            let startHour = calendar.date(byAdding: .hour, value: -page, to: nextFullHour) ?? nextFullHour
            
            // Calculate the end of the hour (1 hour after the startHour)
            let endHour = calendar.date(byAdding: .hour, value: -1, to: startHour) ?? startHour
            
            // Format the date and time range for the title
            dateFormatter.dateStyle = .medium
            let formattedDate = dateFormatter.string(from: startHour)
            
            // Format the hour range (HH:mm - HH:mm)
            dateFormatter.dateFormat = "HH:mm"
            let startTime = dateFormatter.string(from: startHour)
            let endTime = dateFormatter.string(from: endHour)
            
            // Set the title to display the correct time range and date
            title = "\(formattedDate), \(endTime) - \(startTime)"
        case .daily:
            let pageDate = calendar.date(byAdding: .day, value: -page, to: now) ?? now
            dateFormatter.dateStyle = .full
            title = dateFormatter.string(from: pageDate)
        case .weekly:
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: calendar.date(byAdding: .weekOfYear, value: -page, to: now)!)
            components.weekday = 2 // Monday is the 2nd day of the week
            let mondayOfWeek = calendar.date(from: components) ?? now
            let sundayOfWeek = calendar.date(byAdding: .day, value: 6, to: mondayOfWeek) ?? now
            dateFormatter.dateFormat = "MMM dd"
            title = "\(dateFormatter.string(from: mondayOfWeek)) - \(dateFormatter.string(from: sundayOfWeek))"
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
    
    // Function to filter and aggregate data based on the current page and time frame
    private func filterAndAggregateDataForPage(_ data: [ChartDataVital], timeFrame: VitalTimeFrame, page: Int) -> [ChartDataVital] {
        let calendar = Calendar.current
        let now = Date()
        var filteredData: [ChartDataVital] = []
        
        switch timeFrame {
        case .hourly:
            // Calculate the next full hour from the current time (e.g., if now is 15:43, this will return 16:00)
            let nextFullHour = calendar.date(bySettingHour: calendar.component(.hour, from: now), minute: 0, second: 0, of: now) ?? now
            
            // Calculate the start hour for the current page by moving backward in time
            let hourStart = calendar.date(byAdding: .hour, value: -page, to: nextFullHour) ?? nextFullHour
            
            // Calculate the end of the hour (1 hour after the start hour)
            let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourStart) ?? hourStart
            
            // Filter raw data points for this hour
            filteredData = data.filter { $0.date >= hourStart && $0.date < hourEnd }
        case .daily:
            let pageDate = calendar.date(byAdding: .day, value: -page, to: now) ?? now
            let hourlyData = aggregateDataByHour(for: pageDate, data: data)
            filteredData = hourlyData
        case .weekly:
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: calendar.date(byAdding: .weekOfYear, value: -page, to: now)!)
            let mondayOfWeek = calendar.date(from: components) ?? now
            let dailyData = (0..<8).map { offset -> ChartDataVital in
                let date = calendar.date(byAdding: .day, value: offset, to: mondayOfWeek)!
                if offset == 7 {
                    return ChartDataVital(date: date, minValue: 0, maxValue: 0, averageValue: 0)
                }
                return aggregateDataByDay(for: date, data: data)
            }
            filteredData = dailyData
        case .monthly:
            let pageDate = calendar.date(byAdding: .month, value: -page, to: now) ?? now
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: pageDate))!
            let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
            let numberOfDaysInMonth = range.count
            let dailyData = (0..<numberOfDaysInMonth).map { offset -> ChartDataVital in
                let date = calendar.date(byAdding: .day, value: offset, to: startOfMonth)!
                return aggregateDataByDay(for: date, data: data)
            }
            filteredData = dailyData
        case .sixMonths:
            let startOfSixMonths = calendar.date(byAdding: .month, value: -(page * 6), to: now) ?? now
            let sixMonthsData = aggregateDataByWeek(for: startOfSixMonths, data: data, weeks: 26)
            filteredData = sixMonthsData
        case .yearly:
            let selectedYear = calendar.component(.year, from: now) - page
            let startOfYear = calendar.date(from: DateComponents(year: selectedYear, month: 1))!
            let yearlyData = aggregateDataByMonth(for: startOfYear, data: data, months: 12)
            filteredData = yearlyData
        }
        
        return filteredData
    }

    // Aggregate data by the minute for hourly view with min and max values
    private func aggregateDataByMinute(for date: Date, data: [ChartDataVital]) -> [ChartDataVital] {
        let calendar = Calendar.current
        var minuteData: [ChartDataVital] = []
        
        for minute in 0..<60 {
            let startOfMinute = calendar.date(bySettingHour: calendar.component(.hour, from: date), minute: minute, second: 0, of: date)!
            let endOfMinute = calendar.date(bySettingHour: calendar.component(.hour, from: date), minute: minute, second: 59, of: date)!
            
            let filteredData = data.filter { $0.date >= startOfMinute && $0.date <= endOfMinute }
            
            let minValue = filteredData.map { $0.minValue }.min() ?? 0.0
            let maxValue = filteredData.map { $0.maxValue }.max() ?? 0.0
            let averageValue = (minValue + maxValue) / 2
            
            minuteData.append(ChartDataVital(date: startOfMinute, minValue: minValue, maxValue: maxValue, averageValue: averageValue))
        }
        
        return minuteData
    }

    // Aggregate data by hour with min and max values
    private func aggregateDataByHour(for date: Date, data: [ChartDataVital]) -> [ChartDataVital] {
        let calendar = Calendar.current
        var hourlyData: [ChartDataVital] = []
        
        for hour in 0..<24 {
            let startOfHour = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
            let endOfHour = calendar.date(bySettingHour: hour, minute: 59, second: 59, of: date)!
            
            let filteredData = data.filter { $0.date >= startOfHour && $0.date <= endOfHour }
            
            let minValue = filteredData.map { $0.minValue }.min() ?? 0.0
            let maxValue = filteredData.map { $0.maxValue }.max() ?? 0.0
            let averageValue = (minValue + maxValue) / 2
            
            hourlyData.append(ChartDataVital(date: startOfHour, minValue: minValue, maxValue: maxValue, averageValue: averageValue))
        }
        
        return hourlyData
    }

    // Aggregate data by day with min and max values
    private func aggregateDataByDay(for date: Date, data: [ChartDataVital]) -> ChartDataVital {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)!
        
        let filteredData = data.filter { $0.date >= startOfDay && $0.date <= endOfDay }
        
        let minValue = filteredData.map { $0.minValue }.min() ?? 0.0
        let maxValue = filteredData.map { $0.maxValue }.max() ?? 0.0
        let averageValue = (minValue + maxValue) / 2
        
        return ChartDataVital(date: startOfDay, minValue: minValue, maxValue: maxValue, averageValue: averageValue)
    }

    // Aggregate data by week with min and max values
    private func aggregateDataByWeek(for startDate: Date, data: [ChartDataVital], weeks: Int) -> [ChartDataVital] {
        let calendar = Calendar.current
        var weeklyData: [ChartDataVital] = []
        
        for weekOffset in 0..<weeks {
            let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startDate)!)?.start ?? startDate
            let currentWeekEnd = calendar.date(byAdding: .day, value: 6, to: currentWeekStart)!
            
            let filteredData = data.filter { $0.date >= currentWeekStart && $0.date <= currentWeekEnd }
            
            let minValue = filteredData.map { $0.minValue }.min() ?? 0.0
            let maxValue = filteredData.map { $0.maxValue }.max() ?? 0.0
            let averageValue = (minValue + maxValue) / 2
            
            weeklyData.append(ChartDataVital(date: currentWeekStart, minValue: minValue, maxValue: maxValue, averageValue: averageValue))
        }
        
        return weeklyData
    }

    // Aggregate data by month with min and max values
    private func aggregateDataByMonth(for startDate: Date, data: [ChartDataVital], months: Int) -> [ChartDataVital] {
        let calendar = Calendar.current
        var monthlyData: [ChartDataVital] = []
        
        for monthOffset in 0..<months {
            let currentMonthStart = calendar.date(byAdding: .month, value: monthOffset, to: startDate)!
            let currentMonthEnd = calendar.date(byAdding: .month, value: 1, to: currentMonthStart)!.addingTimeInterval(-1)
            
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
                            .symbolSize(10)
                            LineMark(
                                x: .value("Time", item.date),
                                y: .value("Heart Rate", item.averageValue)  // raw heart rate value
                            )
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
                        AxisMarks(values: .automatic(desiredCount: 12)) { value in
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
            // Get the start and end times in a manner similar to your example
            let now = Date()
            
            // Calculate the next full hour from the current time (e.g., if now is 15:43, this will return 16:00)
            let nextFullHour = calendar.date(bySettingHour: calendar.component(.hour, from: now) + 1, minute: 0, second: 0, of: now) ?? now
            
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
