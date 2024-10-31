//
//  SixMinuteWalkTestManager.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 31.10.24.
//

import SwiftUI
import CoreMotion
import CoreLocation
import UserNotifications

class SixMinuteWalkTestManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let pedometer = CMPedometer()
    @Published var isCollectingData = false
    @Published var stepCount: Int = 0
    @Published var distance: Double? // Distance in meters from GPS
    @Published var averageActivePace: Double? // Average active pace in meters per second
    @Published var currentPace: Double? // Current pace in meters per second
    @Published var currentCadence: Double? // Current cadence in steps per second
    @Published var floorAscended: Int? // Floors ascended, if available
    @Published var floorDescended: Int? // Floors descended, if available
    @Published var savedFilePath: String?
    
    let baseFolder: String = "ProcessedStepCountsData"
    
    private var locationManager: CLLocationManager?
    private var initialLocation: CLLocation?
    private var stopTime: Date?

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
            showDataCollectionNotification()  // Show notification when app enters background
        }
    }
    
    @objc private func appWillEnterForeground() {
        removeDataCollectionNotification()  // Remove notification when app enters foreground
    }
    
    @objc private func appDidBecomeActive() {}

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
    }
    
    // Show a notification when data collection starts
    func showDataCollectionNotification() {
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

    // Start step count collection for 6MWT
    func startStepCountCollection() {
        guard !isCollectingData else { return }
        
        isCollectingData = true
        stepCount = 0
        distance = nil
        averageActivePace = nil
        currentPace = nil
        currentCadence = nil
        floorAscended = nil
        floorDescended = nil
        
        // Start GPS tracking
        initialLocation = nil
        locationManager?.startUpdatingLocation()
        
        showDataCollectionNotification()
        
        // Start pedometer updates
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
                if let distance = pedometerData.distance?.doubleValue {
                    self?.distance = distance
                }
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
        
        // Stop data collection after 6 minutes (6MWT)
        stopTime = Date().addingTimeInterval(6 * 60)
        Timer.scheduledTimer(withTimeInterval: 6 * 60, repeats: false) { [weak self] _ in
            self?.stopStepCountCollection()
        }
    }
    
    func stopStepCountCollection() {
        guard isCollectingData else { return }
        
        isCollectingData = false
        pedometer.stopUpdates()
        locationManager?.stopUpdatingLocation()
        removeDataCollectionNotification()
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

    // CLLocationManagerDelegate method for updating location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        // Set the initial location if it’s the first reading
        if initialLocation == nil {
            initialLocation = newLocation
        } else if let initialLocation = initialLocation {
            // Calculate distance from the initial point
            let distanceInMeters = newLocation.distance(from: initialLocation)
            distance = distanceInMeters
        }
    }
}
