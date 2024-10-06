//
//  mobilityManager.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import HealthKit
import Foundation
import SwiftUI

// Define a struct to store min, max, and average values with the date
struct MobilityStatistics {
    let date: Date
    let minValue: Double
    let maxValue: Double
    let averageValue: Double
}

class HealthKitMobilityManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var walkingDoubleSupportData: [MobilityStatistics] = []
    @Published var walkingAsymmetryData: [MobilityStatistics] = []
    @Published var walkingSpeedData: [MobilityStatistics] = []
    @Published var walkingStepLengthData: [MobilityStatistics] = []
    @Published var walkingSteadinessData: [MobilityStatistics] = []
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
        let typesToRead: Set<HKQuantityType> = [
            .quantityType(forIdentifier: .walkingDoubleSupportPercentage)!,
            .quantityType(forIdentifier: .walkingAsymmetryPercentage)!,
            .quantityType(forIdentifier: .walkingSpeed)!,
            .quantityType(forIdentifier: .walkingStepLength)!,
            .quantityType(forIdentifier: .appleWalkingSteadiness)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if !success {
                print("Authorization failed: \(String(describing: error?.localizedDescription))")
            } else {
                print("Authorization succeeded")
            }
        }
    }
    
    func fetchMobilityData(startDate: Date, endDate: Date) {
        // Clear cache for new data fetch
        dataCache.removeAll()
        
        // Fetch each mobility-related data type with min, max, and average calculations
        fetchData(identifier: .walkingDoubleSupportPercentage, startDate: startDate, endDate: endDate) { [weak self] result in
            let statistics = self?.computeStatistics(from: result, unit: HKUnit.percent())
            DispatchQueue.main.async {
                if let stats = statistics {
                    self?.walkingDoubleSupportData = [MobilityStatistics(date: Date(), minValue: stats.minValue, maxValue: stats.maxValue, averageValue: stats.averageValue)]
                }
            }
        }
        
        fetchData(identifier: .walkingAsymmetryPercentage, startDate: startDate, endDate: endDate) { [weak self] result in
            let statistics = self?.computeStatistics(from: result, unit: HKUnit.percent())
            DispatchQueue.main.async {
                if let stats = statistics {
                    self?.walkingAsymmetryData = [MobilityStatistics(date: Date(), minValue: stats.minValue, maxValue: stats.maxValue, averageValue: stats.averageValue)]
                }
            }
        }
        
        fetchData(identifier: .walkingSpeed, startDate: startDate, endDate: endDate) { [weak self] result in
            let statistics = self?.computeStatistics(from: result, unit: HKUnit.meter().unitDivided(by: HKUnit.second()))
            DispatchQueue.main.async {
                if let stats = statistics {
                    self?.walkingSpeedData = [MobilityStatistics(date: Date(), minValue: stats.minValue, maxValue: stats.maxValue, averageValue: stats.averageValue)]
                }
            }
        }
        
        fetchData(identifier: .walkingStepLength, startDate: startDate, endDate: endDate) { [weak self] result in
            let statistics = self?.computeStatistics(from: result, unit: HKUnit.meter())
            DispatchQueue.main.async {
                if let stats = statistics {
                    self?.walkingStepLengthData = [MobilityStatistics(date: Date(), minValue: stats.minValue, maxValue: stats.maxValue, averageValue: stats.averageValue)]
                }
            }
        }
        
        fetchData(identifier: .appleWalkingSteadiness, startDate: startDate, endDate: endDate) { [weak self] result in
            let statistics = self?.computeStatistics(from: result, unit: HKUnit.percent())
            DispatchQueue.main.async {
                if let stats = statistics {
                    self?.walkingSteadinessData = [MobilityStatistics(date: Date(), minValue: stats.minValue, maxValue: stats.maxValue, averageValue: stats.averageValue)]
                }
            }
        }
    }

    // Helper function to compute min, max, and average from the fetched data
    private func computeStatistics(from samples: [HKQuantitySample], unit: HKUnit) -> (minValue: Double, maxValue: Double, averageValue: Double)? {
        guard !samples.isEmpty else { return nil }
        
        var minValue = Double.greatestFiniteMagnitude
        var maxValue = Double.leastNormalMagnitude
        var totalValue: Double = 0.0
        
        for sample in samples {
            let value = sample.quantity.doubleValue(for: unit)
            minValue = min(minValue, value)
            maxValue = max(maxValue, value)
            totalValue += value
        }
        
        let averageValue = totalValue / Double(samples.count)
        return (minValue, maxValue, averageValue)
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
        saveCSV(for: walkingDoubleSupportData, fileName: "walking_double_support_data.csv", unitLabel: "%")
        saveCSV(for: walkingAsymmetryData, fileName: "walking_asymmetry_data.csv", unitLabel: "%")
        saveCSV(for: walkingSpeedData, fileName: "walking_speed_data.csv", unitLabel: "m/s")
        saveCSV(for: walkingStepLengthData, fileName: "walking_step_length_data.csv", unitLabel: "m")
        saveCSV(for: walkingSteadinessData, fileName: "walking_steadiness_data.csv", unitLabel: "%")
    }
    
    private func saveCSV(for samples: [MobilityStatistics], fileName: String, unitLabel: String) {
        var csvString = "Date,Min Value (\(unitLabel)),Max Value (\(unitLabel)),Average Value (\(unitLabel))\n"
        
        let dateFormatter = ISO8601DateFormatter()
        
        for sample in samples {
            let dateString = dateFormatter.string(from: sample.date)
            let minValue = String(format: "%.2f", sample.minValue)
            let maxValue = String(format: "%.2f", sample.maxValue)
            let averageValue = String(format: "%.2f", sample.averageValue)
            csvString += "\(dateString),\(minValue),\(maxValue),\(averageValue)\n"
        }
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            return
        }
        
        let folderURL = documentsDirectory.appendingPathComponent("MobilityData")
        
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
