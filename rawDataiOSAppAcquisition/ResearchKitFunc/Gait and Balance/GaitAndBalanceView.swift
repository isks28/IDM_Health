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

struct GaitAndBalanceView: View {
    enum TaskType {
        case gait
        case balance
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
            task = GaitAndBalanceManager.shared.createBalanceTask()
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
                    if let stepResults = taskViewController.result.results as? [ORKStepResult] {
                        for stepResult in stepResults {
                            if let motionResult = stepResult.results?.first as? ORKFileResult {
                                self.saveResultsToCSV(result: motionResult, outputDirectory: taskViewController.outputDirectory!)
                                
                                DispatchQueue.main.async {
                                    let alert = UIAlertController(title: "Showing saved results:", message: "Your test data has been recorded successfully.", preferredStyle: .alert)
                                    
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
        
        func saveResultsToCSV(result: ORKFileResult, outputDirectory: URL) {
            let fileManager = FileManager.default
            let saveDirectory = outputDirectory.appendingPathComponent("GaitAndBalance")
            
            do {
                try fileManager.createDirectory(at: saveDirectory, withIntermediateDirectories: true, attributes: nil)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
                let timestampString = dateFormatter.string(from: Date())
                
                let fileName = "GaitAndBalanceData_\(timestampString).csv"
                let fileURL = saveDirectory.appendingPathComponent(fileName)
                
                let csvString = "Timestamp,TestType\n\(timestampString),\(parent.taskType)\n"
                try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                print("CSV file saved successfully at: \(fileURL.path)")
            } catch {
                print("Error saving CSV file: \(error.localizedDescription)")
            }
        }
    }
}
