//
//  magnetometerDataManager.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI
import CoreMotion

class MagnetometerManager: NSObject, ObservableObject, CLLocationManagerDelegate{
    
    private let magnetometerManager = CMMotionManager()
    @Published var isCollectingData = false
    @Published var magnetometerData: [String] = []
    @Published var savedFilePath: String?
    
    private var locationManager: CLLocationManager?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var stopTime: Date?
    private var recordingMode: String = "RealTime"
    
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
    
    func startMagnetometerDataCollection(realTime: Bool) {
        guard !isCollectingData else { return }
        
        isCollectingData = true
        magnetometerData = []
        recordingMode = realTime ? "RealTime" : "TimeInterval"
        
        startBackgroundTask()
        
        if magnetometerManager.isDeviceMotionAvailable {
            magnetometerManager.deviceMotionUpdateInterval = realTime ? 1.0 / 60.0 : 1.0 / 60.0 // 60 Hz - Sampling Rate
            magnetometerManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
                if let validData = data {
                    let userMagnetometerString = "UserMagnetometer,\(validData.timestamp),\(validData.magneticField.field.x),\(validData.magneticField.field.y),\(validData.magneticField.field.z)"
                    self?.magnetometerData.append(userMagnetometerString)
                }
            }
        }
    }
    
    func stopMagnetometerDataCollection() {
            guard isCollectingData else { return }
            
            isCollectingData = false
            
            magnetometerManager.stopDeviceMotionUpdates()
        
            endBackgroundTask()
            
            saveDataToCSV()
        }
    
    private func saveDataToCSV() {
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            return
        }
        
        let folderURL = documentsDirectory.appendingPathComponent("Magnetometer Data")
        
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create directory: \(error)")
            return
        }
        
        var fileNumber = 1
        var fileURL = folderURL.appendingPathComponent("MagnetometerData_\(fileNumber)_\(recordingMode).csv")

            while FileManager.default.fileExists(atPath: fileURL.path) {
                fileNumber += 1
                fileURL = folderURL.appendingPathComponent("MagnetometerData_\(fileNumber)_\(recordingMode).csv")
        }
        
        let csvHeader = "DataType,TimeStamp,x,y,z\n"
        
        let csvData = magnetometerData.joined(separator: "\n")
                
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
                        self.stopMagnetometerDataCollection()
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
                self?.startMagnetometerDataCollection(realTime: true )
            }
        } else {
            startMagnetometerDataCollection(realTime: true)
        }
        
        let endInterval = endDate.timeIntervalSince(now)
        Timer.scheduledTimer(withTimeInterval: endInterval, repeats: false) { [weak self] _ in
            self?.stopMagnetometerDataCollection()
            completion()
        }
    }
    
    // CLLocationManagerDelegate method
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Handle location updates if needed
    }
}
