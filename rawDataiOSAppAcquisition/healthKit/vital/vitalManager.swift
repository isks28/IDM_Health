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
    let startDate: Date
    let endDate: Date
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
    
    private var dataCache: [HKQuantityTypeIdentifier: [HKQuantitySample]] = [:]
    private let backgroundQueue = DispatchQueue(label: "com.mobilityManager.backgroundQueue", attributes: .concurrent)
    
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
    
    func fetchVitalData(startDate: Date, endDate: Date) {
        // Clear cache for new data fetch
        dataCache.removeAll()
        
        // Fetch each mobility-related data type without aggregation
        fetchData(identifier: .heartRate, startDate: startDate, endDate: endDate) { [weak self] result in
            let statistics = self?.convertSamplesToStatistics(samples: result, unit: HKUnit.percent())
            DispatchQueue.main.async {
                self?.heartRateData = statistics ?? []
            }
        }
    }
    
    private func convertSamplesToStatistics(samples: [HKQuantitySample], unit: HKUnit) -> [VitalStatistics] {
        return samples.map { sample in
            let value = sample.quantity.doubleValue(for: unit)
            
            // Check for heart rate unit
            switch unit {
            case HKUnit.count().unitDivided(by: HKUnit.minute()): // Heart rate in beats per minute
                // No conversion needed for BPM, just use the value as is
                break
            default:
                break // No conversion for other units
            }

            // Use both startDate and endDate of the sample
            return VitalStatistics(startDate: sample.startDate, endDate: sample.endDate, minValue: value, maxValue: value, averageValue: value)
        }
    }
    
    private func fetchData(identifier: HKQuantityTypeIdentifier, startDate: Date, endDate: Date, completion: @escaping ([HKQuantitySample]) -> Void) {
        if let cachedData = dataCache[identifier] {
            completion(cachedData)
            return
        }
        
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            print("\(identifier.rawValue) Type is unavailable")
            completion([])
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, error in
            if let error = error {
                print("Failed to fetch \(identifier.rawValue) data: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let quantitySamples = samples as? [HKQuantitySample] else {
                completion([])
                return
            }
            
            self?.dataCache[identifier] = quantitySamples
            completion(quantitySamples)
        }
        
        backgroundQueue.async {
            self.healthStore.execute(query)
        }
    }
    
    func saveDataAsCSV() {
        saveCSV(for: heartRateData, fileName: "heart_rate_data.csv", unitLabel: "BPM")
    }
    
    private func saveCSV(for samples: [VitalStatistics], fileName: String, unitLabel: String) {
        var csvString = "Date,Value (\(unitLabel))\n"
        
        let dateFormatter = ISO8601DateFormatter()
        
        for sample in samples {
            let dateString = dateFormatter.string(from: sample.endDate)
            let roundedValue = String(format: "%.0f", sample.averageValue)  // Rounding the value to 0 decimal places
            csvString += "\(dateString),\(roundedValue)\n"
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
