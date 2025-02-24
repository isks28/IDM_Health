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
        case leftShoulder
        case rightShoulder
        case leftKnee
        case rightKnee
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

        switch taskType {
        case .leftShoulder:
            task = ORKOrderedTask.shoulderRangeOfMotionTask(
                withIdentifier: "LeftShoulderRangeOfMotionTask",
                limbOption: .left,
                intendedUseDescription: "Measure left shoulder flexibility.",
                options: [.excludeConclusion]
            )
        case .rightShoulder:
            task = ORKOrderedTask.shoulderRangeOfMotionTask(
                withIdentifier: "RightShoulderRangeOfMotionTask",
                limbOption: .right,
                intendedUseDescription: "Measure right shoulder flexibility.",
                options: [.excludeConclusion]
            )
        case .leftKnee:
            task = ORKOrderedTask.kneeRangeOfMotionTask(
                withIdentifier: "LeftKneeRangeOfMotionTask",
                limbOption: .left,
                intendedUseDescription: "Measure left knee flexibility.",
                options: [.excludeConclusion]
            )
        case .rightKnee:
            task = ORKOrderedTask.kneeRangeOfMotionTask(
                withIdentifier: "RightKneeRangeOfMotionTask",
                limbOption: .right,
                intendedUseDescription: "Measure right knee flexibility.",
                options: [.excludeConclusion]
            )
        }

        let completionStep = ORKCompletionStep(identifier: "CompletionStep")
        completionStep.title = "Test Completed"
        completionStep.text = "Thank you for completing the test! result will be saved and alert view to review the results will be displayed when Done button is clicked!"
        
        let modifiedTask = ORKOrderedTask(identifier: "ModifiedTask", steps: task.steps + [completionStep])

        let taskViewController = ORKTaskViewController(task: modifiedTask, taskRun: nil)
        taskViewController.delegate = context.coordinator
        taskViewController.outputDirectory = outputDirectory
        
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
                                
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "dd MMMM yyyy, HH:mm:ss"
                                let formattedDate = dateFormatter.string(from: motionResult.startDate)

                                let minAngle = String(format: "%.2f", motionResult.minimum)
                                let maxAngle = String(format: "%.2f", motionResult.maximum)
                                let startAngle = String(format: "%.2f", motionResult.start)
                                let finishAngle = String(format: "%.2f", motionResult.finish)
                                let range = String(format: "%.2f", motionResult.range)

                                DispatchQueue.main.async {
                                    let alert = UIAlertController(title: "Showing saved results:", message: """
                                        Timestamp: \(formattedDate)
                                        Minimum Angle: \(minAngle)°
                                        Maximum Angle: \(maxAngle)°
                                        Start Angle: \(startAngle)°
                                        Finish Angle: \(finishAngle)°
                                        Range: \(range)°
                                        """, preferredStyle: .alert)
                                    
                                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                                        taskViewController.dismiss(animated: true) {
                                            self.parent.presentationMode.wrappedValue.dismiss()
                                        }
                                    }))
                                    
                                    taskViewController.present(alert, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        func saveResultsToCSV(motionResult: ORKRangeOfMotionResult, outputDirectory: URL) {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMMM yyyy, HH:mm:ss"
            let formattedDate = dateFormatter.string(from: motionResult.startDate)
            
            let timestamp = formattedDate
            let minAngle = motionResult.minimum
            let maxAngle = motionResult.maximum
            let startAngle = motionResult.start
            let finishAngle = motionResult.finish
            let range = motionResult.range

            print("DEBUG - Range of Motion Result: \(motionResult)")
            print("Timestamp: \(timestamp)")
            print("Minimum Angle: \(minAngle)")
            print("Maximum Angle: \(maxAngle)")
            print("Start Angle: \(startAngle)")
            print("Finish Angle: \(finishAngle)")
            print("Range Angle: \(range)")

            let csvString = "Date,Time,Minimum Angle,Maximum Angle,Start Angle,Finish Angle,Range\n\(timestamp),\(minAngle),\(maxAngle),\(startAngle),\(finishAngle),\(range)\n"

            let fileManager = FileManager.default
            let rangeOfMotionDir = outputDirectory.appendingPathComponent("RangeOfMotion")
            let jointDir: String

            switch parent.taskType {
            case .leftShoulder: jointDir = "Left Shoulder"
            case .rightShoulder: jointDir = "Right Shoulder"
            case .leftKnee: jointDir = "Left Knee"
            case .rightKnee: jointDir = "Right Knee"
            }

            let saveDirectory = rangeOfMotionDir.appendingPathComponent(jointDir)

            do {
                try fileManager.createDirectory(at: saveDirectory, withIntermediateDirectories: true, attributes: nil)
                
                // Create a unique filename with timestamp
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
                let timestampString = dateFormatter.string(from: motionResult.startDate)
                
                let fileName = "RangeOfMotionData_\(timestampString).csv"
                let fileURL = saveDirectory.appendingPathComponent(fileName)
                
                try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                print("CSV file saved successfully at: \(fileURL.path)")
            } catch {
                print("Error saving CSV file: \(error.localizedDescription)")
            }
        }
    }
}
