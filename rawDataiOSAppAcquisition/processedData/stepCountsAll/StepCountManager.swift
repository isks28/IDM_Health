//
//  StepCountManager.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 11.10.24.
//

import SwiftUI
import CoreMotion
import CoreLocation
import UserNotifications

class StepCountManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let pedometer = CMPedometer()
    @Published var isCollectingData = false
    @Published var stepCount: Int = 0
    @Published var distanceGPS: Double = 0.0 // Distance in meters from GPS
    @Published var distancePedometer: Double = 0.0 // Distance in meters estimated from steps
    @Published var averageActivePace: Double? // Average active pace in meters per second
    @Published var currentPace: Double? // Current pace in meters per second
    @Published var currentCadence: Double? // Current cadence in steps per second
    @Published var floorAscended: Int? // Floors ascended, if available
    @Published var floorDescended: Int? // Floors descended, if available
    @Published var savedFilePath: String?
    @Published var stepLengthInMeters: Double = 0.7 // Approximate step length in meters
    
    let baseFolder: String = "ProcessedStepCountsData"
    
    private var locationManager: CLLocationManager?
    private var previousLocation: CLLocation?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var stopTime: Date?
    private var recordingMode: String = "RealTime"
    private var serverURL: URL?

    override init() {
        super.init()
        setupLocationManager()
        requestNotificationPermissions()
        setupAppLifecycleObservers()
    }
    
    // App lifecycle event observers
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func appDidEnterBackground() {
        if isCollectingData {
            backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "KeepDataCollectionActive") {
                UIApplication.shared.endBackgroundTask(self.backgroundTask)
                self.backgroundTask = .invalid
            }
        }
        showDataCollectionNotification()
    }
    
    @objc private func appWillEnterForeground() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        removeDataCollectionNotification()
    }
    
    @objc private func appDidBecomeActive() {}
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false
        locationManager?.startUpdatingLocation()
        locationManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager?.distanceFilter = 4.9 // Customize this value as appropriate
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
        content.body = "Step count data collection is active."
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

    // Start step count collection
    func startStepCountCollection(realTime: Bool, serverURL: URL) {
        guard !isCollectingData else { return }
        
        self.serverURL = serverURL
        isCollectingData = true
        stepCount = 0
        distanceGPS = 0.0
        distancePedometer = 0.0
        averageActivePace = nil
        currentPace = nil
        currentCadence = nil
        floorAscended = nil
        floorDescended = nil
        recordingMode = realTime ? "RealTime" : "TimeInterval"
        
        locationManager?.startUpdatingLocation()
        startBackgroundTask()
        showDataCollectionNotification() // Show the notification
        
        guard CMPedometer.isStepCountingAvailable() else {
            print("Step counting is not available on this device")
            return
        }

        pedometer.startUpdates(from: Date()) { [weak self] pedometerData, error in
            guard let pedometerData = pedometerData, error == nil else {
                print("Error fetching pedometer data: \(String(describing: error))")
                return
            }
            
            DispatchQueue.main.async {
                self?.stepCount = pedometerData.numberOfSteps.intValue
                self?.distancePedometer = Double(pedometerData.numberOfSteps.intValue) * (self?.stepLengthInMeters ?? 0.7)
                if let averageActivePace = pedometerData.averageActivePace?.doubleValue {
                    self?.averageActivePace = averageActivePace
                }
                if let currentPace = pedometerData.currentPace?.doubleValue {
                    self?.currentPace = currentPace
                }
                if let currentCadence = pedometerData.currentCadence?.doubleValue {
                    self?.currentCadence = currentCadence
                }
                if let floorsAscended = pedometerData.floorsAscended?.intValue {
                    self?.floorAscended = floorsAscended
                }
                if let floorsDescended = pedometerData.floorsDescended?.intValue {
                    self?.floorDescended = floorsDescended
                }
            }
        }
    }
    
    func stopStepCountCollection() {
        guard isCollectingData else { return }
        
        isCollectingData = false
        pedometer.stopUpdates()
        
        locationManager?.stopUpdatingLocation()
        endBackgroundTask()
        removeDataCollectionNotification()  // Remove the notification
        
        if let serverURL = serverURL {
            saveDataToCSV(serverURL: serverURL, baseFolder: self.baseFolder, recordingMode: self.recordingMode)
        }
    }
    
    // Update current pace and cadence
    func updateCurrentPaceAndCadence() {
        guard CMPedometer.isPaceAvailable(), CMPedometer.isCadenceAvailable() else {
            print("Pace or Cadence is not available on this device")
            return
        }
        
        let now = Date()
        pedometer.queryPedometerData(from: now.addingTimeInterval(-1), to: now) { [weak self] pedometerData, error in
            guard let pedometerData = pedometerData, error == nil else {
                print("Error fetching pedometer data: \(String(describing: error))")
                return
            }
            
            DispatchQueue.main.async {
                if let currentPace = pedometerData.currentPace?.doubleValue {
                    self?.currentPace = currentPace
                }
                if let currentCadence = pedometerData.currentCadence?.doubleValue {
                    self?.currentCadence = currentCadence
                }
            }
        }
    }
    
    // Save collected data to CSV
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

        // Create a date formatter for converting the timestamp to local time string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"  // Desired date format
        dateFormatter.timeZone = TimeZone.current  // Local timezone

        // Get the current date and time for the CSV entry
        let currentDate = Date()
        let formattedDate = dateFormatter.string(from: currentDate)
        
        // Prepare CSV header and data with floors ascended/descended included
        let csvHeader = "DataType,TimeStamp,StepCount,Distance (m),AverageActivePace (m/s),CurrentPace (m/s),CurrentCadence (steps/s),FloorsAscended,FloorsDescended\n"
        let csvData = "WalkingData,\(formattedDate),\(stepCount),\(distanceGPS),\(distancePedometer),\(averageActivePace ?? 0),\(currentPace ?? 0),\(currentCadence ?? 0),\(floorAscended ?? 0),\(floorDescended ?? 0)"
        
        let csvString = csvHeader + csvData  // Include formatted timestamp in the CSV data

        // Compute a hash of the current data to see if it's already been saved
        let dataHash = csvString.hashValue
        
        // Create a unique file name based on the current data hash
        let fileName = "StepCountData_\(formattedDate)_\(dataHash)_\(recordingMode).csv"
        let fileURL = folderURL.appendingPathComponent(fileName)
        
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

    
    // Upload the file to the server
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
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "StepCountBackgroundTask") {
            self.endBackgroundTask()
        }
        
        DispatchQueue.global(qos: .background).async {
            while self.isCollectingData {
                if let stopTime = self.stopTime, Date() >= stopTime {
                    DispatchQueue.main.async {
                        self.stopStepCountCollection()
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
    
    func scheduleStepCountCollection(startDate: Date, endDate: Date, serverURL: URL, baseFolder: String, completion: @escaping () -> Void) {
        let now = Date()
        stopTime = endDate
        
        recordingMode = "TimeInterval"
        
        if startDate > now {
            let startInterval = startDate.timeIntervalSince(now)
            Timer.scheduledTimer(withTimeInterval: startInterval, repeats: false) { [weak self] _ in
                self?.startStepCountCollection(realTime: false, serverURL: serverURL)
            }
        } else {
            startStepCountCollection(realTime: false, serverURL: serverURL)
        }
        
        let endInterval = endDate.timeIntervalSince(now)
        Timer.scheduledTimer(withTimeInterval: endInterval, repeats: false) { [weak self] _ in
            self?.stopStepCountCollection()
            completion()
        }
    }
    
    // CLLocationManagerDelegate method for updating location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let newLocation = locations.last else { return }
            
        let movementThreshold: CLLocationDistance = 4.9
            
            if let previousLocation = previousLocation {
                let distanceInMeters = newLocation.distance(from: previousLocation)
                
                if distanceInMeters >= movementThreshold {
                    distanceGPS += distanceInMeters
                    self.previousLocation = newLocation
                } else {
                    print("Ignoring small movement: \(distanceInMeters) meters")
                }
            } else {
                previousLocation = newLocation
            }
        }
    }
