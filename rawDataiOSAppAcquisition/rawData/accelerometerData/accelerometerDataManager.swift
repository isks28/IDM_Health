//
//  accelerometerDataManager.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI
import CoreMotion
import UserNotifications

class AccelerometerManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let accelerometerManager = CMMotionManager()
    @Published var isCollectingData = false
    @Published var accelerometerData: [String] = []
    @Published var accelerometerDataPointsX: [Double] = []
    @Published var accelerometerDataPointsY: [Double] = []
    @Published var accelerometerDataPointsZ: [Double] = []
    @Published var savedFilePath: String?

    let baseFolder: String = "AccelerometerData"
    
    private var locationManager: CLLocationManager?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var stopTime: Date?
    private var recordingMode: String = "RealTime"
    private var currentSamplingRate: Double = 60.0
    private var serverURL: URL?

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

        // Ensure notifications are allowed
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
        }

        let content = UNMutableNotificationContent()
        content.title = "Data Collection Running"
        content.body = "Accelerometer data collection is active."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "dataCollectionNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
    }
    
    func showDataCollectionStoppedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Data Collection Stopped"
        content.body = "Accelerometer data collection has stopped and the data has been saved."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "dataCollectionStoppedNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing stop notification: \(error)")
            }
        }
    }

    // Remove the notification when data collection stops
    func removeDataCollectionNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dataCollectionNotification"])
    }

    func startAccelerometerDataCollection(realTime: Bool, serverURL: URL) {
        guard !isCollectingData else { return }

        self.serverURL = serverURL
        isCollectingData = true
        accelerometerData = []
        accelerometerDataPointsX = []
        accelerometerDataPointsY = []
        accelerometerDataPointsZ = []
        recordingMode = realTime ? "RealTime" : "TimeInterval"

        startBackgroundTask()
        showDataCollectionNotification() // Show the notification

        if accelerometerManager.isDeviceMotionAvailable {
            accelerometerManager.deviceMotionUpdateInterval = 1.0 / currentSamplingRate
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
        removeDataCollectionNotification() // Remove the notification
        showDataCollectionStoppedNotification() // show the notification if data collection is stopped

        if let serverURL = serverURL {
            saveDataToCSV(serverURL: serverURL, baseFolder: self.baseFolder, recordingMode: self.recordingMode)
        }
    }
    
    func resetData() {
            // Reset any internal data states to prepare for a fresh start when the view is reopened
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
        }

    func updateSamplingRate(rate: Double) {
        currentSamplingRate = rate
        if isCollectingData {
            stopAccelerometerDataCollection()
            startAccelerometerDataCollection(realTime: recordingMode == "RealTime", serverURL: self.serverURL!)
        }
    }

    func saveDataToCSV(serverURL: URL, baseFolder: String, recordingMode: String) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            return
        }

        let folderURL = documentsDirectory.appendingPathComponent(baseFolder).appendingPathComponent(recordingMode)

        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create directory: \(error)")
            return
        }

        let csvHeader = "DataType,TimeStamp,x,y,z\n"
        let csvData = accelerometerData.joined(separator: "\n")
        let csvString = csvHeader + csvData
        
        // Compute a hash of the current data to see if it's already been saved
        let dataHash = csvString.hashValue
        
        // Check if the file with the same data (hash) already exists
        let fileURL = folderURL.appendingPathComponent("AccelerometerData_\(dataHash)_\(recordingMode).csv")
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            print("File with the same data already exists: \(fileURL.path)")
            savedFilePath = fileURL.path
            return
        }

        do {
            print("Attempting to save file at \(fileURL.path)")
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("File saved at \(fileURL.path)")
            savedFilePath = fileURL.path

            self.uploadFile(fileURL: fileURL, serverURL: serverURL, category: baseFolder)
        } catch {
            print("Failed to save file: \(error)")
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
            self.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    func scheduleDataCollection(startDate: Date, endDate: Date, serverURL: URL, baseFolder: String, completion: @escaping () -> Void) {
            let now = Date()
            stopTime = endDate

            // Since this is scheduled, set the recording mode to "ScheduledTime"
            recordingMode = "TimeInterval"

            if startDate > now {
                let startInterval = startDate.timeIntervalSince(now)
                Timer.scheduledTimer(withTimeInterval: startInterval, repeats: false) { [weak self] _ in
                    self?.startAccelerometerDataCollection(realTime: false, serverURL: serverURL)
                }
            } else {
                startAccelerometerDataCollection(realTime: false, serverURL: serverURL)
            }

            let endInterval = endDate.timeIntervalSince(now)
            Timer.scheduledTimer(withTimeInterval: endInterval, repeats: false) { [weak self] _ in
                self?.stopAccelerometerDataCollection()
                self?.removeDataCollectionNotification()
                self?.showDataCollectionStoppedNotification()
                completion()
            }
        }

    // CLLocationManagerDelegate method
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Handle location updates if needed
    }
}
