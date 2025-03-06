//
//  GaitAndBalanceView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 24.02.25.
//

import ResearchKit
import ResearchKitUI
import ResearchKitActiveTask
import SwiftUI
import CoreMotion

struct GaitAndBalanceView: View {
    enum TaskType: String {
        case gait = "Gait"
        case balance = "Balance"
        case short = "Short"
        case walkBackAndForth = "WalkBackAndForth"
    }
    
    var taskType: TaskType
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        GaitAndBalanceTaskViewController(taskType: taskType, presentationMode: presentationMode)
            .edgesIgnoringSafeArea(.all)
    }
}

struct GaitAndBalanceTaskViewController: UIViewControllerRepresentable {
    var taskType: GaitAndBalanceView.TaskType
    var presentationMode: Binding<PresentationMode>
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> ORKTaskViewController {
        let task: ORKOrderedTask
        let outputDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ResearchKitData", isDirectory: true)
        
        switch taskType {
        case .gait:
            task = GaitAndBalanceManager.shared.createGaitTask()
        case .balance:
            task = GaitAndBalanceManager.shared.createSixMinuteWalkTask()
        case .short:
            task = GaitAndBalanceManager.shared.createShortWalkTask()
        case .walkBackAndForth:
            task = GaitAndBalanceManager.shared.createWalkBackAndForthTask()
        }
        
        let completionStep = ORKCompletionStep(identifier: "CompletionStep")
        completionStep.title = "Test Completed"
        completionStep.text = "Thank you for completing the test! Your results have been saved."
        
        let modifiedTask = ORKOrderedTask(identifier: "ModifiedTask", steps: task.steps + [completionStep])
        
        let taskViewController = ORKTaskViewController(task: modifiedTask, taskRun: nil)
        taskViewController.delegate = context.coordinator
        taskViewController.outputDirectory = outputDirectory
        
        return taskViewController
    }
    
    func updateUIViewController(_ uiViewController: ORKTaskViewController, context: Context) {}

    class Coordinator: NSObject, ORKTaskViewControllerDelegate {
        var parent: GaitAndBalanceTaskViewController
        
        init(_ parent: GaitAndBalanceTaskViewController) {
            self.parent = parent
        }
        
        func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskFinishReason, error: Error?) {
            if reason == .completed {
                DispatchQueue.global(qos: .background).async {
                    self.saveAllResultsToSingleCSV(taskViewController: taskViewController, outputDirectory: taskViewController.outputDirectory!, taskType: self.parent.taskType)
                    
                    DispatchQueue.main.async {
                        let alert = UIAlertController(
                            title: "Results Saved",
                            message: "Your test data has been recorded successfully.",
                            preferredStyle: .alert
                        )
                        
                        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            taskViewController.dismiss(animated: true) {
                                self.parent.presentationMode.wrappedValue.dismiss()
                            }
                        })
                        
                        taskViewController.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
        
        /// Merges all recorded motion files into a single CSV
        func saveAllResultsToSingleCSV(taskViewController: ORKTaskViewController, outputDirectory: URL, taskType: GaitAndBalanceView.TaskType) {
            let fileManager = FileManager.default
            let saveDirectory = outputDirectory.appendingPathComponent("GaitAndBalance")

            do {
                try fileManager.createDirectory(at: saveDirectory, withIntermediateDirectories: true, attributes: nil)

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
                let timestampString = dateFormatter.string(from: Date())

                let fileName = "MergedGaitAndBalanceData_\(timestampString).csv"
                let fileURL = saveDirectory.appendingPathComponent(fileName)

                var csvString = "Timestamp,TaskType,StepCount,WalkingSpeed(m/s),StrideLength(m),AccelerationX,AccelerationY,AccelerationZ,GyroX,GyroY,GyroZ\n"

                if let stepResults = taskViewController.result.results as? [ORKStepResult] {
                    for stepResult in stepResults {
                        if let fileResults = stepResult.results?.compactMap({ $0 as? ORKFileResult }) {
                            for fileResult in fileResults {
                                if let filePath = fileResult.fileURL, let data = try? Data(contentsOf: filePath) {
                                    let motionData = MotionEntry.parseMotionFile(data)
                                    for entry in motionData {
                                        csvString += "\(entry.timestamp),\(taskType.rawValue),\(entry.stepCount),\(entry.walkingSpeed),\(entry.strideLength),\(entry.accelerationX),\(entry.accelerationY),\(entry.accelerationZ),\(entry.gyroX),\(entry.gyroY),\(entry.gyroZ)\n"
                                    }
                                }
                            }
                        }
                    }
                }

                try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                print("Merged CSV file saved successfully at: \(fileURL.path)")

            } catch {
                print("Error saving merged CSV file: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Motion Data Parsing
struct MotionEntry {
    let timestamp: TimeInterval
    let stepCount: Int
    let walkingSpeed: Double
    let strideLength: Double
    let accelerationX: Double
    let accelerationY: Double
    let accelerationZ: Double
    let gyroX: Double
    let gyroY: Double
    let gyroZ: Double

    static func parseMotionFile(_ data: Data) -> [MotionEntry] {
        var motionEntries: [MotionEntry] = []
        let lines = String(data: data, encoding: .utf8)?.components(separatedBy: "\n") ?? []
        
        var previousTimestamp: TimeInterval = 0.0
        var totalSteps = 0
        let totalDistance = 10.0  // Assuming 10 meters for Timed Walk Task
        let timeLimit: TimeInterval = 30  // Seconds

        for line in lines.dropFirst() { // Skip header line
            let columns = line.components(separatedBy: ",")
            if columns.count < 7 { continue }

            if let timestamp = TimeInterval(columns[0]),
               let accelX = Double(columns[1]),
               let accelY = Double(columns[2]),
               let accelZ = Double(columns[3]),
               let gyroX = Double(columns[4]),
               let gyroY = Double(columns[5]),
               let gyroZ = Double(columns[6]) {

                let accelerationMagnitude = sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ)
                if accelerationMagnitude > 1.2 {  // Simple step detection threshold
                    totalSteps += 1
                }

                let elapsedTime = timestamp - previousTimestamp
                let walkingSpeed = (elapsedTime > 0) ? (totalDistance / timeLimit) : 0.0
                let strideLength = (totalSteps > 0) ? (totalDistance / Double(totalSteps)) : 0.0

                motionEntries.append(MotionEntry(
                    timestamp: timestamp,
                    stepCount: totalSteps,
                    walkingSpeed: walkingSpeed,
                    strideLength: strideLength,
                    accelerationX: accelX,
                    accelerationY: accelY,
                    accelerationZ: accelZ,
                    gyroX: gyroX,
                    gyroY: gyroY,
                    gyroZ: gyroZ
                ))

                previousTimestamp = timestamp
            }
        }
        return motionEntries
    }
}
