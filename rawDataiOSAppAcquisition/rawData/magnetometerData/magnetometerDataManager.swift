//
//  magnetometerDataManager.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI
import CoreMotion
import UserNotifications

class MagnetometerManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let magnetometerManager = CMMotionManager()
    @Published var isCollectingData = false
    @Published var magnetometerData: [String] = []
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
        content.body = "Magnetometer data collection is active."
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

    func startMagnetometerDataCollection(realTime: Bool) {
        guard !isCollectingData else { return }
        
        isCollectingData = true
        magnetometerData = []
        recordingMode = realTime ? "RealTime" : "TimeInterval"
        
        startBackgroundTask()
        showDataCollectionNotification() // Show the notification
        
        if magnetometerManager.isDeviceMotionAvailable {
            magnetometerManager.deviceMotionUpdateInterval = 1.0 / currentSamplingRate // Apply the current sampling rate
            magnetometerManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
                if let validData = data {
                    let timestamp = validData.timestamp
                    let userMagnetometerString = "UserMagnetometer,\(timestamp),\(validData.magneticField.field.x),\(validData.magneticField.field.y),\(validData.magneticField.field.z)"
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
        removeDataCollectionNotification()  // Remove the notification
        saveDataToCSV()
    }
    
    func updateSamplingRate(rate: Double) {
        currentSamplingRate = rate
        if isCollectingData {
            stopMagnetometerDataCollection()
            startMagnetometerDataCollection(realTime: recordingMode == "RealTime")
        }
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
                self?.startMagnetometerDataCollection(realTime: true)
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
