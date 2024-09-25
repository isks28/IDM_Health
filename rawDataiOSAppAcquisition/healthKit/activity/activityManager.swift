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
    @Published var distanceWalkingRunningData: [HKQuantitySample] = []   // Added distanceWalkingRunning
    @Published var appleExerciseTimeData: [HKQuantitySample] = []        // Added appleExerciseTime
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
              let appleStandTime = HKQuantityType.quantityType(forIdentifier: .appleStandTime),
              let distanceWalkingRunning = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),  // Added distanceWalkingRunning
              let appleExerciseTime = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)  // Added appleExerciseTime
        else {
            print("One or more Health Activity Data is not available")
            return
        }
        
        let typesToRead: Set = [stepCount, activeEnergyBurned, appleMoveTime, appleStandTime, distanceWalkingRunning, appleExerciseTime]  // Added new types
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if !success {
                print("Authorization failed: \(String(describing: error?.localizedDescription))")
            } else {
                print("Authorization succeeded")
            }
        }
    }
    
    func fetchActivityData(startDate: Date, endDate: Date) {
        fetchRawData(for: .stepCount, startDate: startDate, endDate: endDate) { result in
            self.stepCountData = result
        }
        fetchRawData(for: .activeEnergyBurned, startDate: startDate, endDate: endDate) { result in
            self.activeEnergyBurnedData = result
        }
        fetchRawData(for: .appleMoveTime, startDate: startDate, endDate: endDate) { result in
            self.appleMoveTimeData = result
        }
        fetchRawData(for: .appleStandTime, startDate: startDate, endDate: endDate) { result in
            self.appleStandTimeData = result
        }
        fetchRawData(for: .distanceWalkingRunning, startDate: startDate, endDate: endDate) { result in
            self.distanceWalkingRunningData = result
        }
        fetchRawData(for: .appleExerciseTime, startDate: startDate, endDate: endDate) { result in
            self.appleExerciseTimeData = result
        }
    }
    
    private func fetchRawData(for identifier: HKQuantityTypeIdentifier, startDate: Date, endDate: Date, completion: @escaping ([HKQuantitySample]) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            print("\(identifier.rawValue) Type is unavailable")
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { query, samples, error in
            if let error = error {
                print("Failed to fetch \(identifier.rawValue) data: \(error.localizedDescription)")
                return
            }
            
            guard let quantitySamples = samples as? [HKQuantitySample] else {
                completion([])
                return
            }
            
            DispatchQueue.main.async {
                completion(quantitySamples)
                print("Fetched \(quantitySamples.count) raw samples for \(identifier.rawValue)")
            }
        }
        
        healthStore.execute(query)
    }
    
    func saveDataAsCSV() {
        saveCSV(for: stepCountData, fileName: "step_count_data.csv", valueUnit: HKUnit.count(), unitLabel: "Count")
        saveCSV(for: activeEnergyBurnedData, fileName: "active_energy_burned_data.csv", valueUnit: HKUnit.largeCalorie(), multiplier: 1.0, unitLabel: "Kilo Calories")
        saveCSV(for: appleMoveTimeData, fileName: "move_time_data.csv", valueUnit: HKUnit.second(), unitLabel: "Seconds")
        saveCSV(for: appleStandTimeData, fileName: "apple_stand_time_data.csv", valueUnit: HKUnit.second(), unitLabel: "Seconds")
        saveCSV(for: distanceWalkingRunningData, fileName: "distance_walking_running_data.csv", valueUnit: HKUnit.meter(), unitLabel: "Meters")  // Added CSV for distanceWalkingRunning
        saveCSV(for: appleExerciseTimeData, fileName: "exercise_time_data.csv", valueUnit: HKUnit.second(), unitLabel: "Seconds")  // Added CSV for appleExerciseTime
    }
    
    private func saveCSV(for samples: [HKQuantitySample], fileName: String, valueUnit: HKUnit, multiplier: Double = 1.0, unitLabel: String) {
        var csvString = "Date,Value (\(unitLabel))\n"
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        
        for sample in samples {
            let value = sample.quantity.doubleValue(for: valueUnit) * multiplier
            let date = sample.endDate
            let dateString = dateFormatter.string(from: date)
            csvString += "\(dateString),\(value)\n"
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
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("File saved at \(fileURL.path)")
            savedFilePath = fileURL.path
        } catch {
            print("Failed to save file: \(error)")
        }
    }
}
