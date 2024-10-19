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
    
    let baseFolder: String = "VitalData"
    
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
            .quantityType(forIdentifier: .heartRate)!
        ]
        
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
        
        // Fetch heart rate data
        fetchData(identifier: .heartRate, startDate: startDate, endDate: endDate) { [weak self] result in
            let statistics = self?.convertSamplesToStatistics(samples: result, unit: HKUnit.count().unitDivided(by: HKUnit.minute()))
            DispatchQueue.main.async {
                self?.heartRateData = statistics ?? []
            }
        }
    }
    
    private func convertSamplesToStatistics(samples: [HKQuantitySample], unit: HKUnit) -> [VitalStatistics] {
        // Group samples by date or desired interval, and calculate min, max, and average
        var statistics: [VitalStatistics] = []
        
        // Process samples and calculate min, max, and average
        for sample in samples {
            let heartRateValue = sample.quantity.doubleValue(for: unit)  // Value in BPM
            
            let vitalStat = VitalStatistics(
                startDate: sample.startDate,
                endDate: sample.endDate,
                minValue: heartRateValue,
                maxValue: heartRateValue,
                averageValue: heartRateValue
            )
            statistics.append(vitalStat)
        }
        
        return statistics
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
    
    func saveDataAsCSV(serverURL: URL) {
        backgroundQueue.async{
            self.saveCSV(for: self.heartRateData, fileName: "heart_rate_data.csv", unitLabel: "BPM", serverURL: serverURL, baseFolder: self.baseFolder, decimalPlaces: 0)
        }
    }
    
    private func saveCSV(for samples: [VitalStatistics], fileName: String, unitLabel: String, serverURL: URL, baseFolder: String, decimalPlaces: Int) {
        // Add headers for the CSV
        var csvString = "Recorded Date and Time,Value (\(unitLabel))\n"
        
        let dateFormatter = ISO8601DateFormatter()  // ISO8601 for formatting dates
        dateFormatter.timeZone = TimeZone.current
        
        for sample in samples {
            let dateString = dateFormatter.string(from: sample.endDate)
            let formatString = "%.\(decimalPlaces)f"  // Format the value based on the decimal places
            let value = String(format: formatString, sample.averageValue.isNaN ? 0 : sample.averageValue)  // Handle NaN and format value
            csvString += "\(dateString),\(value)\n"
        }
        
        // Get the local documents directory to save locally
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            return
        }
        
        // Use the baseFolder parameter to define where to save the file (e.g., "VitalData", "ActivityData")
        let folderURL = documentsDirectory.appendingPathComponent(baseFolder)
        
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create directory: \(error)")
            return
        }
        
        let fileURL = folderURL.appendingPathComponent(fileName)
        
        // Save the CSV file locally
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("File saved locally at \(fileURL.path)")
            savedFilePath = fileURL.path
            
            // After saving locally, upload the file to the web server
            self.uploadFile(fileURL: fileURL, serverURL: serverURL, category: baseFolder)
        } catch {
            print("Failed to save file locally: \(error)")
        }
    }

    func uploadFile(fileURL: URL, serverURL: URL, category: String) {
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        let fileName = fileURL.lastPathComponent
        let mimeType = "text/csv"  // Assuming you're uploading CSV files
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"category\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(category)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(try! Data(contentsOf: fileURL))
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        let task = URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
            if let error = error {
                print("Error uploading file: \(error)")
                return
            }
            print("File uploaded successfully to server")
        }
        
        task.resume()
    }
}
