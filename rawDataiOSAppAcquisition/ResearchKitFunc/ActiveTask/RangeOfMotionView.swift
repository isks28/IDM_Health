//
//  RangeOfMotionView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 18.02.25.
//

import SwiftUI
import ResearchKit
import ResearchKitUI
import ResearchKitActiveTask

struct RangeOfMotionView: View {
    enum TaskType {
        case shoulder
        case knee
    }
    
    var taskType: TaskType
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        RangeOfMotionTaskViewController(taskType: taskType, presentationMode: presentationMode)
            .edgesIgnoringSafeArea(.all)
    }
}

struct RangeOfMotionTaskViewController: UIViewControllerRepresentable {
    var taskType: RangeOfMotionView.TaskType
    var presentationMode: Binding<PresentationMode>
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> ORKTaskViewController {
        let task: ORKOrderedTask
        let outputDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ResearchKitData", isDirectory: true)
        
        // ✅ Include motion sensor recording for higher accuracy
        let motionRecorder = ORKDeviceMotionRecorderConfiguration(
            identifier: "motionRecorder",
            frequency: 50.0 // 50 Hz sampling rate
        )

        switch taskType {
        case .shoulder:
            task = ORKOrderedTask.shoulderRangeOfMotionTask(
                withIdentifier: "ShoulderRangeOfMotionTask",
                limbOption: .left,
                intendedUseDescription: "Measure shoulder flexibility.",
                options: []
            )
        case .knee:
            task = ORKOrderedTask.kneeRangeOfMotionTask(
                withIdentifier: "KneeRangeOfMotionTask",
                limbOption: .left,
                intendedUseDescription: "Measure knee flexibility.",
                options: []
            )
        }

        let taskViewController = ORKTaskViewController(task: task, taskRun: nil)
        taskViewController.delegate = context.coordinator
        taskViewController.outputDirectory = outputDirectory // ✅ Ensure data is stored properly
        
        return taskViewController
    }
    
    func updateUIViewController(_ uiViewController: ORKTaskViewController, context: Context) {}

    class Coordinator: NSObject, ORKTaskViewControllerDelegate {
        var parent: RangeOfMotionTaskViewController
        
        init(_ parent: RangeOfMotionTaskViewController) {
            self.parent = parent
        }
        
        func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskFinishReason, error: Error?) {
            if reason == .completed {
                DispatchQueue.global(qos: .background).async {
                    if let stepResults = taskViewController.result.results as? [ORKStepResult] {
                        for stepResult in stepResults {
                            if let motionResult = stepResult.results?.first as? ORKRangeOfMotionResult {
                                self.saveResultsToCSV(motionResult: motionResult, outputDirectory: taskViewController.outputDirectory!)
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    taskViewController.dismiss(animated: true) {
                        self.parent.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        
        func saveResultsToCSV(motionResult: ORKRangeOfMotionResult, outputDirectory: URL) {
            let timestamp = motionResult.startDate
            let minAngle = motionResult.minimum
            let maxAngle = motionResult.maximum

            // Debugging Output
            print("DEBUG - Range of Motion Result: \(motionResult)")
            print("Timestamp: \(timestamp)")
            print("Start Angle: \(minAngle)")
            print("Finish Angle: \(maxAngle)")

            let csvString = "Timestamp,Minimum Angle,Maximum Angle\n\(timestamp),\(minAngle),\(maxAngle)\n"

            let fileManager = FileManager.default
            let rangeOfMotionDir = outputDirectory.appendingPathComponent("RangeOfMotion")
            let jointDir = parent.taskType == .shoulder ? "Left Shoulder" : "Left Knee"
            let saveDirectory = rangeOfMotionDir.appendingPathComponent(jointDir)

            do {
                try fileManager.createDirectory(at: saveDirectory, withIntermediateDirectories: true, attributes: nil)
                let fileURL = saveDirectory.appendingPathComponent("RangeOfMotionData.csv")
                try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                print("CSV file saved successfully at: \(fileURL.path)")
            } catch {
                print("Error saving CSV file: \(error.localizedDescription)")
            }
        }
    }
}
