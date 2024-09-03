//
//  activityManager.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import HealthKit
import Foundation
import SwiftUI

class ActivityManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var stepCountData: [HKQuantitySample] = []
    @Published var activeEnergyBurnedData: [HKQuantitySample] = []
    @Published var appleMoveTimeData: [HKQuantitySample] = []
    @Published var appleStandTimeData: [HKQuantitySample] = []
    @Published var savedFilePath: String?
    
    @Published var startDate: Date
    @Published var endDate: Date
    
    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
        requestAuthorization()
    }
    
    func requestAuthorization() {
        guard let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let activeEnergyBurned = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let appleMoveTime = HKQuantityType.quantityType(forIdentifier: .appleMoveTime),
              let appleStandTime = HKQuantityType.quantityType(forIdentifier: .appleStandTime) else {
            print("One or more Health Activity Data is not available")
            return
        }
        
        let typesToRead: Set = [stepCount, activeEnergyBurned, appleMoveTime, appleStandTime]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if !success {
                print("Authorization failed: \(String(describing: error?.localizedDescription))")
            } else {
                print("Authorization succeeded")
            }
        }
    }
    
    func fetchActivityData(startDate: Date, endDate: Date) {
        fetchStepCountData(startDate: startDate, endDate: endDate)
        fetchActiveEnergyBurnedData(startDate: startDate, endDate: endDate)
        fetchAppleMoveTimeData(startDate: startDate, endDate: endDate)
        fetchAppleStandTimeData(startDate: startDate, endDate: endDate)
    }
    
    private func fetchStepCountData(startDate: Date, endDate: Date) {
            guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
                print("Step Count Type is unavailable")
                return
            }
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
            
            let query = HKSampleQuery(sampleType: stepCountType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { query, results, error in
                if let error = error {
                    print("Failed to fetch step count data: \(error.localizedDescription)")
                    return
                }
                
                guard let results = results as? [HKQuantitySample] else {
                    print("No step count data found")
                    return
                }
                
                DispatchQueue.main.async {
                    self.stepCountData = results
                    print("Fetched \(results.count) step count samples")
                }
            }
            
            healthStore.execute(query)
        }
        
        private func fetchActiveEnergyBurnedData(startDate: Date, endDate: Date) {
            guard let activeEnergyBurnedType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
                print("Active Energy Burned Type is unavailable")
                return
            }
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
            
            let query = HKSampleQuery(sampleType: activeEnergyBurnedType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { query, results, error in
                if let error = error {
                    print("Failed to fetch active energy burned data: \(error.localizedDescription)")
                    return
                }
                
                guard let results = results as? [HKQuantitySample] else {
                    print("No active energy burned data found")
                    return
                }
                
                DispatchQueue.main.async {
                    self.activeEnergyBurnedData = results
                    print("Fetched \(results.count) active energy burned samples")
                }
            }
            
            healthStore.execute(query)
        }
        
        private func fetchAppleMoveTimeData(startDate: Date, endDate: Date) {
            guard let appleMoveTimeType = HKQuantityType.quantityType(forIdentifier: .appleMoveTime) else {
                print("Apple Move Time Type is unavailable")
                return
            }
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
            
            let query = HKSampleQuery(sampleType: appleMoveTimeType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { query, results, error in
                if let error = error {
                    print("Failed to fetch apple move time data: \(error.localizedDescription)")
                    return
                }
                
                guard let results = results as? [HKQuantitySample] else {
                    print("No apple move time data found")
                    return
                }
                
                DispatchQueue.main.async {
                    self.appleMoveTimeData = results
                    print("Fetched \(results.count) apple move time samples")
                }
            }
            
            healthStore.execute(query)
        }
        
        private func fetchAppleStandTimeData(startDate: Date, endDate: Date) {
            guard let appleStandTimeType = HKQuantityType.quantityType(forIdentifier: .appleStandTime) else {
                print("Apple Stand Time Type is unavailable")
                return
            }
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
            
            let query = HKSampleQuery(sampleType: appleStandTimeType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { query, results, error in
                if let error = error {
                    print("Failed to fetch apple stand time data: \(error.localizedDescription)")
                    return
                }
                
                guard let results = results as? [HKQuantitySample] else {
                    print("No apple stand time data found")
                    return
                }
                
                DispatchQueue.main.async {
                    self.appleStandTimeData = results
                    print("Fetched \(results.count) apple stand time samples")
                }
            }
            
            healthStore.execute(query)
        }
    
    func saveDataAsCSV() {
        saveCSV(for: stepCountData, fileName: "step_count_data.csv", valueUnit: HKUnit.count(), unitLabel: "Count")
        saveCSV(for: activeEnergyBurnedData, fileName: "active_energy_burned_data.csv", valueUnit: HKUnit.largeCalorie(), unitLabel: "Kilo Calories")
        saveCSV(for: appleMoveTimeData, fileName: "move_time_data.csv", valueUnit: HKUnit.second(), unitLabel: "Seconds")
        saveCSV(for: appleStandTimeData, fileName: "apple_stand_time_data.csv", valueUnit: HKUnit.second(), unitLabel: "Seconds")
    }
    
    private func saveCSV(for samples: [HKQuantitySample], fileName: String, valueUnit: HKUnit, multiplier: Double = 1.0, unitLabel: String) {
        var csvString = "Date,Value (\(unitLabel))\n"
        
        let dateFormatter = ISO8601DateFormatter()
        
        for sample in samples {
            let value = sample.quantity.doubleValue(for: valueUnit) * multiplier
            let date = sample.startDate
            let dateString = dateFormatter.string(from: date)
            csvString += "\(dateString),\(value) \(unitLabel)\n"
        }
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            return
        }
        
        let folderURL = documentsDirectory.appendingPathComponent("ActivityData")
        
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create directory: \(error)")
            return
        }
        
        let fileURL = folderURL.appendingPathComponent(fileName)
        
        do {
            print("Attempting to save file at \(fileURL.path)")
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("File saved at \(fileURL.path)")
            savedFilePath = fileURL.path
        } catch {
            print("Failed to save file: \(error)")
        }
    }
}
