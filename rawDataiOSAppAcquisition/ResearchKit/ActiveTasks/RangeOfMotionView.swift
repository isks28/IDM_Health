//
//  RangeOfMotionView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 18.02.25.
//

import SwiftUI
import ResearchKit

struct RangeOfMotionView: View {
    enum TaskType {
        case shoulder
        case knee
    }
    
    var taskType: TaskType
    
    var body: some View {
        RangeOfMotionTaskViewController(taskType: taskType)
            .edgesIgnoringSafeArea(.all)
    }
}

struct RangeOfMotionTaskViewController: UIViewControllerRepresentable {
    var taskType: RangeOfMotionView.TaskType
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> ORKTaskViewController {
        let task: ORKOrderedTask
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
        return taskViewController
    }
    
    func updateUIViewController(_ uiViewController: ORKTaskViewController, context: Context) {
        // No update needed
    }
    
    class Coordinator: NSObject, ORKTaskViewControllerDelegate {
        var parent: RangeOfMotionTaskViewController
        
        init(_ parent: RangeOfMotionTaskViewController) {
            self.parent = parent
        }
        
        func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
            taskViewController.dismiss(animated: true, completion: nil)
        }
    }
}
