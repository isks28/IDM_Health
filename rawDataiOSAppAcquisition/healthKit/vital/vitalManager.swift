//
//  vitalManager.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 19.09.24.
//

import HealthKit
import Foundation
import SwiftUI

class VitalManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var heartRateData: [HKQuantitySample] = []  // Heart rate data storage
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
    
    private func fetchAggregatedData(for identifier: HKQuantityTypeIdentifier, startDate: Date, endDate: Date, interval: DateComponents, completion: @escaping ([HKQuantitySample]) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            print("\(identifier.rawValue) Type is unavailable")
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsCollectionQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .discreteAverage, anchorDate: startDate, intervalComponents: interval)
        
        query.initialResultsHandler = { _, results, error in
            if let error = error {
                print("Failed to fetch \(identifier.rawValue) data: \(error.localizedDescription)")
                return
            }
            
            var aggregatedData: [HKQuantitySample] = []
            results?.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                if let avgQuantity = statistics.averageQuantity() {
                    let sample = HKQuantitySample(type: quantityType, quantity: avgQuantity, start: statistics.startDate, end: statistics.endDate)
                    aggregatedData.append(sample)
                }
            }
            
            DispatchQueue.main.async {
                completion(aggregatedData)
                print("Fetched \(aggregatedData.count) hourly samples for \(identifier.rawValue)")
            }
        }
        
        healthStore.execute(query)
    }
    
    func saveDataAsCSV() {
        saveCSV(for: heartRateData, fileName: "heart_rate_data.csv", valueUnit: HKUnit(from: "count/min"), unitLabel: "BPM")
    }
    
    private func saveCSV(for samples: [HKQuantitySample], fileName: String, valueUnit: HKUnit, multiplier: Double = 1.0, unitLabel: String) {
        var csvString = "Date,Value (\(unitLabel))\n"
        
        let dateFormatter = ISO8601DateFormatter()
        
        for sample in samples {
            let value = sample.quantity.doubleValue(for: valueUnit) * multiplier
            let date = sample.startDate
            let dateString = dateFormatter.string(from: date)
            csvString += "\(dateString),\(value)\n"
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
