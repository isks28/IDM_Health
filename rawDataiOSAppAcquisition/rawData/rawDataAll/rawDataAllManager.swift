//
//  rawDataManager.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 29.10.24.
//

import SwiftUI
import CoreMotion
import UserNotifications

class RawDataManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let rawDataManager = CMMotionManager()
    @Published var isCollectingData = false
    
    @Published var AccelerometerData: [String] = []
    @Published var accelerometerDataPointsX: [Double] = []
    @Published var accelerometerDataPointsY: [Double] = []
    @Published var accelerometerDataPointsZ: [Double] = []
    
    @Published var gyroscopeData: [String] = []
    @Published var gyroscopeDataPointsX: [Double] = []
    @Published var gyroscopeDataPointsY: [Double] = []
    @Published var gyroscopeDataPointsZ: [Double] = []
    
    @Published var magnetometerData: [String] = []
    @Published var magnetometerDataPointsX: [Double] = []
    @Published var magnetometerDataPointsY: [Double] = []
    @Published var magnetometerDataPointsZ: [Double] = []
    
    @Published var savedFilePath: String?
    
    private var currentStartTime: Date?
    private var currentEndTime: Date?
    
    let baseFolder: String = "RawData"
    
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
        setupAppLifecycleObservers()
    }
    
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func appDidEnterBackground() {
        print("App entered background")
        if rawDataManager.isAccelerometerActive && rawDataManager.isGyroActive && rawDataManager.isMagnetometerActive {
            showDataCollectionNotification(startTime: currentStartTime, endTime: currentEndTime)
        }
    }
    
    @objc private func appWillEnterForeground() {
        print("App will enter foreground")
        removeDataCollectionNotification()
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
    
    func showDataCollectionNotification(startTime: Date? = nil, endTime: Date? = nil) {
        _ = startTime ?? currentStartTime
        _ = endTime ?? currentEndTime
        
        let state = UIApplication.shared.applicationState
        if state == .background || state == .inactive {
            print("App is running in the background, showing notification")
        } else {
            print("App is in foreground")
        }

        let content = UNMutableNotificationContent()
        content.title = "Raw Data All Running"
        
        print("recordingMode: \(recordingMode)")
            if let start = startTime, let end = endTime {
                print("Start time: \(start), End time: \(end)")
            } else {
                print("Start time or End time is nil")
            }
        
        if recordingMode == "RealTime" {
                content.body = "Collecting RealTime data..."
            } else if recordingMode == "TimeInterval", let start = startTime, let end = endTime {
                let formatter = DateFormatter()
                formatter.dateFormat = "d. MMM, HH:mm"
                let startFormatted = formatter.string(from: start)
                let endFormatted = formatter.string(from: end)
                content.body = "Collecting TimeInterval data... (\(startFormatted) - \(endFormatted))"
            } else {
                content.body = "Collecting data..."
            }
        
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
        content.title = "Raw Data All Stopped"
        content.body = "Data has been saved"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "dataCollectionStoppedNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing stop notification: \(error)")
            }
        }
    }

    func removeDataCollectionNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dataCollectionNotification"])
    }

    func startrawDataCollection(realTime: Bool, serverURL: URL) {
        guard !isCollectingData else { return }
        
        self.serverURL = serverURL
        isCollectingData = true
        AccelerometerData = []
        gyroscopeData = []
        magnetometerData = []
        accelerometerDataPointsX = []
        accelerometerDataPointsY = []
        accelerometerDataPointsZ = []
        gyroscopeDataPointsX = []
        gyroscopeDataPointsY = []
        gyroscopeDataPointsZ = []
        magnetometerDataPointsX = []
        magnetometerDataPointsY = []
        magnetometerDataPointsZ = []
        recordingMode = realTime ? "RealTime" : "TimeInterval"
        
        startBackgroundTask()
        showDataCollectionNotification()
        
        rawDataManager.accelerometerUpdateInterval = 1.0 / currentSamplingRate
        rawDataManager.gyroUpdateInterval = 1.0 / currentSamplingRate
        rawDataManager.magnetometerUpdateInterval = 1.0 / currentSamplingRate
        
        if rawDataManager.isAccelerometerAvailable {
            rawDataManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
                if let accData = data {
                    let timestamp = Date().timeIntervalSince1970
                    let accDataString = "Accelerometer,\(timestamp),\(accData.acceleration.x),\(accData.acceleration.y),\(accData.acceleration.z)"
                    self?.AccelerometerData.append(accDataString)
                    self?.accelerometerDataPointsX.append(accData.acceleration.x)
                    self?.accelerometerDataPointsY.append(accData.acceleration.y)
                    self?.accelerometerDataPointsZ.append(accData.acceleration.z)
                }
            }
        }
        
        if rawDataManager.isGyroAvailable {
            rawDataManager.startGyroUpdates(to: .main) { [weak self] (data, error) in
                if let gyroData = data {
                    let timestamp = Date().timeIntervalSince1970
                    let gyroDataString = "Gyroscope,\(timestamp),\(gyroData.rotationRate.x),\(gyroData.rotationRate.y),\(gyroData.rotationRate.z)"
                    self?.gyroscopeData.append(gyroDataString)
                    self?.gyroscopeDataPointsX.append(gyroData.rotationRate.x)
                    self?.gyroscopeDataPointsY.append(gyroData.rotationRate.y)
                    self?.gyroscopeDataPointsZ.append(gyroData.rotationRate.z)
                }
            }
        }
        
        if rawDataManager.isMagnetometerAvailable {
            rawDataManager.startMagnetometerUpdates(to: .main) { [weak self] (data, error) in
                if let magData = data {
                    let timestamp = Date().timeIntervalSince1970
                    let magDataString = "Magnetometer,\(timestamp),\(magData.magneticField.x),\(magData.magneticField.y),\(magData.magneticField.z)"
                    self?.magnetometerData.append(magDataString)
                    self?.magnetometerDataPointsX.append(magData.magneticField.x)
                    self?.magnetometerDataPointsY.append(magData.magneticField.y)
                    self?.magnetometerDataPointsZ.append(magData.magneticField.z)
                }
            }
        }
    }

    func stoprawDataCollection() {
        guard isCollectingData else { return }
        
        isCollectingData = false
        
        rawDataManager.stopAccelerometerUpdates()
        rawDataManager.stopGyroUpdates()
        rawDataManager.stopMagnetometerUpdates()
        endBackgroundTask()
        removeDataCollectionNotification()
        showDataCollectionStoppedNotification()
        
        if let serverURL = serverURL {
            saveDataToCSV(serverURL: serverURL, baseFolder: self.baseFolder, recordingMode: self.recordingMode)
        }
    }
    
    func resetData() {
            AccelerometerData = []
            gyroscopeData = []
            magnetometerData = []
            accelerometerDataPointsX = []
            accelerometerDataPointsY = []
            accelerometerDataPointsZ = []
            gyroscopeDataPointsX = []
            gyroscopeDataPointsY = []
            gyroscopeDataPointsZ = []
            magnetometerDataPointsX = []
            magnetometerDataPointsY = []
            magnetometerDataPointsZ = []
        }
    
    func updateSamplingRate(rate: Double) {
        currentSamplingRate = rate
        if isCollectingData {
            stoprawDataCollection()
            startrawDataCollection(realTime: recordingMode == "RealTime", serverURL: self.serverURL!)
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
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        dateFormatter.timeZone = TimeZone.current
        
        let isoDateFormatter = ISO8601DateFormatter()
        isoDateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let csvHeader = "DataType,DateAndTime,TimeStamp,x,y,z\n"
        
        let csvData = (AccelerometerData + gyroscopeData + magnetometerData).map { dataEntry -> String in
            var components = dataEntry.split(separator: ",").map(String.init)
            if let timestamp = Double(components[1]) {
                let date = Date(timeIntervalSince1970: timestamp)
                components[1] = dateFormatter.string(from: date)
            }
            return components.joined(separator: ",")
        }.joined(separator: "\n")
        
        let csvString = csvHeader + csvData
        
        let uniqueFilename = UUID().uuidString
        let fileURL = folderURL.appendingPathComponent("rawDataAll_\(uniqueFilename)_\(recordingMode).csv")
        
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
        let mimeType = "text/csv"

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
                        self.stoprawDataCollection()
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
        recordingMode = "TimeInterval"
        
        currentStartTime = startDate
        currentEndTime = endDate
        
        if startDate > now {
            let startInterval = startDate.timeIntervalSince(now)
            Timer.scheduledTimer(withTimeInterval: startInterval, repeats: false) { [weak self] _ in
                self?.startrawDataCollection(realTime: false, serverURL: serverURL)
                self?.showDataCollectionNotification(startTime: startDate, endTime: endDate)
            }
        } else {
            startrawDataCollection(realTime: false, serverURL: serverURL)
            showDataCollectionNotification(startTime: startDate, endTime: endDate)
        }
        
        let endInterval = endDate.timeIntervalSince(now)
        Timer.scheduledTimer(withTimeInterval: endInterval, repeats: false) { [weak self] _ in
            self?.stoprawDataCollection()
            self?.removeDataCollectionNotification()
            self?.showDataCollectionStoppedNotification()
            completion()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }
}
