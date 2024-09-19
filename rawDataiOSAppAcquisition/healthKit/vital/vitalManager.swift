//
//  vitalManager.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 19.09.24.
//

import HealthKit
import Foundation
import SwiftUI

// Define a struct to store min, max, and average values with the date
struct VitalStatistics {
    let date: Date
    let minValue: Double
    let maxValue: Double
    let averageValue: Double
}

class VitalManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var heartRateData: [VitalStatistics] = []  // Heart rate data storage for min, max, average
    @Published var savedFilePath: String?
    
    @Published var startDate: Date
    @Published var endDate: Date
    
    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
        requestAuthorization()
    }
    
    func requestAuthorization() {
        guard let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            print("Heart Rate Data is not available")
            return
        }
        
        let typesToRead: Set = [heartRate]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if !success {
                print("Authorization failed: \(String(describing: error?.localizedDescription))")
            } else {
                print("Authorization succeeded")
            }
        }
    }
    
    func fetchHeartRateData(startDate: Date, endDate: Date) {
        fetchAggregatedData(for: .heartRate, startDate: startDate, endDate: endDate, interval: DateComponents(hour: 1)) { result in
            self.heartRateData = result
        }
    }
    
    // Fetch and store min, max, and average values
    private func fetchAggregatedData(for identifier: HKQuantityTypeIdentifier, startDate: Date, endDate: Date, interval: DateComponents, completion: @escaping ([VitalStatistics]) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            print("\(identifier.rawValue) Type is unavailable")
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        // Fetching min, max, and average values
        let query = HKStatisticsCollectionQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: [.discreteMin, .discreteMax, .discreteAverage], anchorDate: startDate, intervalComponents: interval)
        
        query.initialResultsHandler = { _, results, error in
            if let error = error {
                print("Failed to fetch \(identifier.rawValue) data: \(error.localizedDescription)")
                return
            }
            
            var aggregatedData: [VitalStatistics] = []
            
            results?.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                if let avgQuantity = statistics.averageQuantity(),
                   let minQuantity = statistics.minimumQuantity(),
                   let maxQuantity = statistics.maximumQuantity() {
                    
                    let avgValue = avgQuantity.doubleValue(for: HKUnit(from: "count/min"))
                    let minValue = minQuantity.doubleValue(for: HKUnit(from: "count/min"))
                    let maxValue = maxQuantity.doubleValue(for: HKUnit(from: "count/min"))
                    
                    // Store the min, max, and average values along with the date
                    let vitalStat = VitalStatistics(date: statistics.startDate, minValue: minValue, maxValue: maxValue, averageValue: avgValue)
                    
                    aggregatedData.append(vitalStat)
                }
            }
            
            DispatchQueue.main.async {
                completion(aggregatedData)
                print("Fetched \(aggregatedData.count) samples (min, max, avg) for \(identifier.rawValue)")
            }
        }
        
        healthStore.execute(query)
    }
    
    func saveDataAsCSV() {
        saveCSV(for: heartRateData, fileName: "heart_rate_data.csv", unitLabel: "BPM")
    }
    
    private func saveCSV(for samples: [VitalStatistics], fileName: String, unitLabel: String) {
        var csvString = "Date,Min Value (\(unitLabel)),Max Value (\(unitLabel)),Average Value (\(unitLabel))\n"
        
        let dateFormatter = ISO8601DateFormatter()
        
        for sample in samples {
            let dateString = dateFormatter.string(from: sample.date)
            csvString += "\(dateString),\(sample.minValue),\(sample.maxValue),\(sample.averageValue)\n"
        }
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            return
        }
        
        let folderURL = documentsDirectory.appendingPathComponent("VitalData")
        
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create directory: \(error)")
            return
        }
        
        let fileURL = folderURL.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("File saved at \(fileURL.path)")
            savedFilePath = fileURL.path
        } catch {
            print("Failed to save file: \(error)")
        }
    }
}
