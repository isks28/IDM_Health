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
    
    func fetchRawHeartRateData(startDate: Date, endDate: Date) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            print("Heart rate data unavailable")
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { [weak self] query, results, error in
            if let error = error {
                print("Error fetching heart rate data: \(error.localizedDescription)")
                return
            }
            
            var rawData: [VitalStatistics] = []
            
            if let samples = results as? [HKQuantitySample] {
                for sample in samples {
                    let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    let date = sample.startDate
                    // For raw data, min, max, avg are the same because it's a single point.
                    let stat = VitalStatistics(date: date, minValue: heartRate, maxValue: heartRate, averageValue: heartRate)
                    rawData.append(stat)
                }
            }
            
            DispatchQueue.main.async {
                self?.heartRateData = rawData
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
