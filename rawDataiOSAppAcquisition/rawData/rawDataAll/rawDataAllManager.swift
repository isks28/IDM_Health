//
//  rawDataAllManager.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI
import CoreMotion
import UserNotifications

class RawDataAllManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let rawDataAllManager = CMMotionManager()
    @Published var isCollectingData = false
    
    // Accelerometer Data Points
    @Published var userAccelerometerData: [String] = []
    @Published var accelerometerDataPointsX: [Double] = []
    @Published var accelerometerDataPointsY: [Double] = []
    @Published var accelerometerDataPointsZ: [Double] = []
    
    // Gyroscope Data Points (Rotation)
    @Published var rotationalData: [String] = []
    @Published var rotationalDataPointsX: [Double] = []
    @Published var rotationalDataPointsY: [Double] = []
    @Published var rotationalDataPointsZ: [Double] = []
    
    // Magnetometer Data Points
    @Published var magneticFieldData: [String] = []
    @Published var magneticDataPointsX: [Double] = []
    @Published var magneticDataPointsY: [Double] = []
    @Published var magneticDataPointsZ: [Double] = []
    
    @Published var savedFilePath: String?
    
    private var locationManager: CLLocationManager?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var stopTime: Date?
    private var recordingMode: String = "RealTime"
    private var currentSamplingRate: Double = 60.0
    
    override init() {
        super.init()
        setupLocationManager()
        requestNotificationPermissions()
        setupAppLifecycleObservers() // Add lifecycle observers
    }
    
    // App lifecycle event observers
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func appDidEnterBackground() {
        print("App entered background")
        if isCollectingData {
            showDataCollectionNotification()  // Show notification when app enters background
        }
    }
    
    @objc private func appWillEnterForeground() {
        print("App will enter foreground")
        removeDataCollectionNotification()  // Remove notification when app enters foreground
    }
    
    @objc private func appDidBecomeActive() {
        print("App became active")
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.startMonitoringSignificantLocationChanges()
    }

    // Request Notification permissions
    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else {
                print("Notification permission denied.")
            }
        }

        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Notifications are not allowed.")
            }
        }
    }
    
    // Show a notification on the lock screen when data collection starts
    func showDataCollectionNotification() {
        let state = UIApplication.shared.applicationState
        if state == .background || state == .inactive {
            print("App is in background, showing notification")
        } else {
            print("App is in foreground")
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Data Collection Running"
        content.body = "Sensor data collection is active."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "dataCollectionNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
    }

    // Remove the notification when data collection stops
    func removeDataCollectionNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dataCollectionNotification"])
    }

    func startRawDataAllCollection(realTime: Bool) {
        guard !isCollectingData else { return }
        
        isCollectingData = true
        userAccelerometerData = []
        rotationalData = []
        magneticFieldData = []
        accelerometerDataPointsX = []
        accelerometerDataPointsY = []
        accelerometerDataPointsZ = []
        rotationalDataPointsX = []
        rotationalDataPointsY = []
        rotationalDataPointsZ = []
        magneticDataPointsX = []
        magneticDataPointsY = []
        magneticDataPointsZ = []
        recordingMode = realTime ? "RealTime" : "TimeInterval"
        
        startBackgroundTask()
        showDataCollectionNotification() // Show the notification
        
        if rawDataAllManager.isDeviceMotionAvailable {
            rawDataAllManager.deviceMotionUpdateInterval = 1.0 / currentSamplingRate // Apply the current sampling rate
            rawDataAllManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
                if let validData = data {
                    let timestamp = validData.timestamp
                    
                    // Collect accelerometer data
                    let userAccDataString = "UserAccelerometer,\(timestamp),\(validData.userAcceleration.x),\(validData.userAcceleration.y),\(validData.userAcceleration.z)"
                    self?.userAccelerometerData.append(userAccDataString)
                    self?.accelerometerDataPointsX.append(validData.userAcceleration.x)
                    self?.accelerometerDataPointsY.append(validData.userAcceleration.y)
                    self?.accelerometerDataPointsZ.append(validData.userAcceleration.z)
                    
                    // Collect gyroscope (rotation) data
                    let userGyroDataString = "UserGyroscope,\(timestamp),\(validData.rotationRate.x),\(validData.rotationRate.y),\(validData.rotationRate.z)"
                    self?.rotationalData.append(userGyroDataString)
                    self?.rotationalDataPointsX.append(validData.rotationRate.x)
                    self?.rotationalDataPointsY.append(validData.rotationRate.y)
                    self?.rotationalDataPointsZ.append(validData.rotationRate.z)
                    
                    // Collect magnetometer data
                    let userMagnetoDataString = "UserMagnetometer,\(timestamp),\(validData.magneticField.field.x),\(validData.magneticField.field.y),\(validData.magneticField.field.z)"
                    self?.magneticFieldData.append(userMagnetoDataString)
                    self?.magneticDataPointsX.append(validData.magneticField.field.x)
                    self?.magneticDataPointsY.append(validData.magneticField.field.y)
                    self?.magneticDataPointsZ.append(validData.magneticField.field.z)
                }
            }
        }
    }
    
    func stopRawDataAllCollection() {
        guard isCollectingData else { return }
        
        isCollectingData = false
        
        rawDataAllManager.stopDeviceMotionUpdates()
        endBackgroundTask()
        removeDataCollectionNotification()  // Remove the notification
        saveDataToCSV()
    }
    
    func updateSamplingRate(rate: Double) {
        currentSamplingRate = rate
        if isCollectingData {
            stopRawDataAllCollection()
            startRawDataAllCollection(realTime: recordingMode == "RealTime")
        }
    }
    
    private func saveDataToCSV() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            return
        }
        
        let folderURL = documentsDirectory.appendingPathComponent("IMU-Data")
        
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create directory: \(error)")
            return
        }
        
        var fileNumber = 1
        var fileURL = folderURL.appendingPathComponent("RawDataAll_\(fileNumber)_\(recordingMode).csv")
        
        while FileManager.default.fileExists(atPath: fileURL.path) {
            fileNumber += 1
            fileURL = folderURL.appendingPathComponent("RawDataAll_\(fileNumber)_\(recordingMode).csv")
        }
        
        let csvHeader = "DataType,TimeStamp,x,y,z\n"
        let csvData = (userAccelerometerData + rotationalData + magneticFieldData).joined(separator: "\n")
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
                        self.stopRawDataAllCollection()
                    }
                    break
                }
                Thread.sleep(forTimeInterval: 1)
            }
            self.endBackgroundTask()
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
                self?.startRawDataAllCollection(realTime: true)
            }
        } else {
            startRawDataAllCollection(realTime: true)
        }
        
        let endInterval = endDate.timeIntervalSince(now)
        Timer.scheduledTimer(withTimeInterval: endInterval, repeats: false) { [weak self] _ in
            self?.stopRawDataAllCollection()
            completion()
        }
    }
    
    // CLLocationManagerDelegate method
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Handle location updates if needed
    }
}
