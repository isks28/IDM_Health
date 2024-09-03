//
//  mobilityManager.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import HealthKit
import Foundation
import SwiftUI

class HealthKitMobilityManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var walkingDoubleSupportData: [HKQuantitySample] = []
    @Published var walkingAsymmetryData: [HKQuantitySample] = []
    @Published var walkingSpeedData: [HKQuantitySample] = []
    @Published var walkingStepLengthData: [HKQuantitySample] = []
    @Published var walkingSteadinessData: [HKQuantitySample] = []
    @Published var savedFilePath: String?
    
    @Published var startDate: Date
    @Published var endDate: Date
    
    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
        requestAuthorization()
    }
    
    func requestAuthorization() {
        guard let walkingDoubleSupport = HKQuantityType.quantityType(forIdentifier: .walkingDoubleSupportPercentage),
              let walkingAsymmetry = HKQuantityType.quantityType(forIdentifier: .walkingAsymmetryPercentage),
              let walkingSpeed = HKQuantityType.quantityType(forIdentifier: .walkingSpeed),
              let walkingStepLength = HKQuantityType.quantityType(forIdentifier: .walkingStepLength),
              let walkingSteadiness = HKQuantityType.quantityType(forIdentifier: .appleWalkingSteadiness) else {
            print("One or more Health Mobility Data is not available")
            return
        }

        let typesToRead: Set = [walkingDoubleSupport, walkingAsymmetry, walkingSpeed, walkingStepLength, walkingSteadiness]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if !success {
                print("Authorization failed: \(String(describing: error?.localizedDescription))")
            } else {
                print("Authorization succeeded")
            }
        }
    }
    
    func fetchMobilityData() {
        fetchWalkingDoubleSupportData()
        fetchWalkingAsymmetryData()
        fetchWalkingSpeedData()
        fetchStepLengthData()
        fetchWalkingSteadinessData()
    }
    
    private func fetchWalkingDoubleSupportData() {
        guard let walkingDoubleSupportType = HKQuantityType.quantityType(forIdentifier: .walkingDoubleSupportPercentage) else {
            print("Walking Double Support Type is unavailable")
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        
        let query = HKSampleQuery(sampleType: walkingDoubleSupportType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { query, results, error in
            if let error = error {
                print("Failed to fetch walking double support data: \(error.localizedDescription)")
                return
            }
            
            guard let results = results as? [HKQuantitySample] else {
                print("No walking double support data found")
                return
            }
            
            DispatchQueue.main.async {
                self.walkingDoubleSupportData = results
                print("Fetched \(results.count) walking double support samples")
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchWalkingAsymmetryData() {
        guard let walkingAsymmetryType = HKQuantityType.quantityType(forIdentifier: .walkingAsymmetryPercentage) else {
            print("Walking Asymmetry Type is unavailable")
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        
        let query = HKSampleQuery(sampleType: walkingAsymmetryType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { query, results, error in
            if let error = error {
                print("Failed to fetch walking asymmetry data: \(error.localizedDescription)")
                return
            }
            
            guard let results = results as? [HKQuantitySample] else {
                print("No walking asymmetry data found")
                return
            }
            
            DispatchQueue.main.async {
                self.walkingAsymmetryData = results
                print("Fetched \(results.count) walking asymmetry samples")
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchWalkingSpeedData() {
        guard let walkingSpeedType = HKQuantityType.quantityType(forIdentifier: .walkingSpeed) else {
            print("Walking Speed Type is unavailable")
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        
        let query = HKSampleQuery(sampleType: walkingSpeedType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { query, results, error in
            if let error = error {
                print("Failed to fetch walking speed data: \(error.localizedDescription)")
                return
            }
            
            guard let results = results as? [HKQuantitySample] else {
                print("No walking speed data found")
                return
            }
            
            DispatchQueue.main.async {
                self.walkingSpeedData = results
                print("Fetched \(results.count) walking speed samples")
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchStepLengthData() {
        guard let stepLengthType = HKQuantityType.quantityType(forIdentifier: .walkingStepLength) else {
            print("Step Length Type is unavailable")
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        
        let query = HKSampleQuery(sampleType: stepLengthType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { query, results, error in
            if let error = error {
                print("Failed to fetch step length data: \(error.localizedDescription)")
                return
            }
            
            guard let results = results as? [HKQuantitySample] else {
                print("No step length data found")
                return
            }
            
            DispatchQueue.main.async {
                self.walkingStepLengthData = results
                print("Fetched \(results.count) step length samples")
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchWalkingSteadinessData() {
        guard let walkingSteadinessType = HKQuantityType.quantityType(forIdentifier: .appleWalkingSteadiness) else {
            print("Walking Steadiness Type is unavailable")
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        
        let query = HKSampleQuery(sampleType: walkingSteadinessType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { query, results, error in
            if let error = error {
                print("Failed to fetch walking steadiness data: \(error.localizedDescription)")
                return
            }
            
            guard let results = results as? [HKQuantitySample] else {
                print("No walking steadiness data found")
                return
            }
            
            DispatchQueue.main.async {
                self.walkingSteadinessData = results
                print("Fetched \(results.count) walking steadiness samples")
            }
        }
        
        healthStore.execute(query)
    }
    
    func saveDataAsCSV() {
        saveCSV(for: walkingDoubleSupportData, fileName: "walking_double_support_data.csv", valueUnit: HKUnit.percent(), multiplier: 100, unitLabel: "%")
        saveCSV(for: walkingAsymmetryData, fileName: "walking_asymmetry_data.csv", valueUnit: HKUnit.percent(), multiplier: 100, unitLabel: "%")
        saveCSV(for: walkingSpeedData, fileName: "walking_speed_data.csv", valueUnit: HKUnit.meter().unitDivided(by: HKUnit.second()), multiplier: 3.6, unitLabel: "km/h")
        saveCSV(for: walkingStepLengthData, fileName: "walking_step_length_data.csv", valueUnit: HKUnit.meter(), unitLabel: "m")
        saveCSV(for: walkingSteadinessData, fileName: "walking_steadiness_data.csv", valueUnit: HKUnit.percent(), multiplier: 100, unitLabel: "%")
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
        
        let folderURL = documentsDirectory.appendingPathComponent("MobilityData")
        
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
