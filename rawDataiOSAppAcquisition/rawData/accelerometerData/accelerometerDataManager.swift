//
//  accelerometerDataManager.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI
import CoreMotion

class AccelerometerManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let accelerometerManager = CMMotionManager()
    @Published var isCollectingData = false
    @Published var accelerometerData: [String] = []
    @Published var accelerometerDataPointsX: [Double] = []
    @Published var accelerometerDataPointsY: [Double] = []
    @Published var accelerometerDataPointsZ: [Double] = []
    @Published var savedFilePath: String?
    
    private var locationManager: CLLocationManager?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var stopTime: Date?
    private var recordingMode: String = "RealTime"
    private var currentSamplingRate: Double = 60.0
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.startUpdatingLocation()
    }
    
    func startAccelerometerDataCollection(realTime: Bool) {
        guard !isCollectingData else { return }
        
        isCollectingData = true
        accelerometerData = []
        accelerometerDataPointsX = []
        accelerometerDataPointsY = []
        accelerometerDataPointsZ = []
        recordingMode = realTime ? "RealTime" : "TimeInterval"
        
        startBackgroundTask()
        
        if accelerometerManager.isDeviceMotionAvailable {
            accelerometerManager.deviceMotionUpdateInterval = 1.0 / currentSamplingRate // Apply the current sampling rate
            accelerometerManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
                if let validData = data {
                    let timestamp = validData.timestamp
                    let userAccDataString = "UserAcceleration,\(timestamp),\(validData.userAcceleration.x),\(validData.userAcceleration.y),\(validData.userAcceleration.z)"
                    self?.accelerometerData.append(userAccDataString)
                    
                    let dataPointX = validData.userAcceleration.x
                    self?.accelerometerDataPointsX.append(dataPointX)
                    let dataPointY = validData.userAcceleration.y
                    self?.accelerometerDataPointsY.append(dataPointY)
                    let dataPointZ = validData.userAcceleration.z
                    self?.accelerometerDataPointsZ.append(dataPointZ)
                }
            }
        }
    }
    
    func stopAccelerometerDataCollection() {
        guard isCollectingData else { return }
        
        isCollectingData = false
        
        accelerometerManager.stopDeviceMotionUpdates()
        endBackgroundTask()
        saveDataToCSV()
    }
    
    func updateSamplingRate(rate: Double) {
        currentSamplingRate = rate
        if isCollectingData {
            stopAccelerometerDataCollection()
            startAccelerometerDataCollection(realTime: recordingMode == "RealTime")
        }
    }
    
    private func saveDataToCSV() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            return
        }
        
        let folderURL = documentsDirectory.appendingPathComponent("IMUData")
        
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create directory: \(error)")
            return
        }
        
        var fileNumber = 1
        var fileURL = folderURL.appendingPathComponent("AccelerometerData_\(fileNumber)_\(recordingMode).csv")
        
        while FileManager.default.fileExists(atPath: fileURL.path) {
            fileNumber += 1
            fileURL = folderURL.appendingPathComponent("AccelerometerData_\(fileNumber)_\(recordingMode).csv")
        }
        
        let csvHeader = "DataType,TimeStamp,x,y,z\n"
        let csvData = accelerometerData.joined(separator: "\n")
        let csvString = csvHeader + csvData
        
        do {
            print("Attempting to save file at \(fileURL.path)")
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("File saved at \(fileURL.path)")
            savedFilePath = fileURL.path
        } catch {
            print("Failed to save file: \(error)")
        }
    }
    
    private func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "IMUBackgroundTask") {
            self.endBackgroundTask()
        }
        
        DispatchQueue.global(qos: .background).async {
            while self.isCollectingData {
                if let stopTime = self.stopTime, Date() >= stopTime {
                    DispatchQueue.main.async {
                        self.stopAccelerometerDataCollection()
                    }
                    break
                }
                Thread.sleep(forTimeInterval: 1)
            }
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    func scheduleDataCollection(startDate: Date, endDate: Date, completion: @escaping () -> Void) {
        let now = Date()
        stopTime = endDate
        
        if startDate > now {
            let startInterval = startDate.timeIntervalSince(now)
            Timer.scheduledTimer(withTimeInterval: startInterval, repeats: false) { [weak self] _ in
                self?.startAccelerometerDataCollection(realTime: true)
            }
        } else {
            startAccelerometerDataCollection(realTime: true)
        }
        
        let endInterval = endDate.timeIntervalSince(now)
        Timer.scheduledTimer(withTimeInterval: endInterval, repeats: false) { [weak self] _ in
            self?.stopAccelerometerDataCollection()
            completion()
        }
    }
    
    // CLLocationManagerDelegate method
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Handle location updates if needed
    }
}
