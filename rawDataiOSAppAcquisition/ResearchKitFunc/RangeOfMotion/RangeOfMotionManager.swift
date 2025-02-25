//
//  RangeOfMotionManager.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 18.02.25.
//

import ResearchKit
import ResearchKitUI
import ResearchKitActiveTask

class RangeOfMotionManager: NSObject {
    
    // Singleton instance
    static let shared = RangeOfMotionManager()
    
    private override init() {
        super.init()
    }
    
    // Function to create a shoulder range of motion task
    func createLeftShoulderRangeOfMotionTask() -> ORKOrderedTask {
        return ORKOrderedTask.shoulderRangeOfMotionTask(
            withIdentifier: "LeftShoulderRangeOfMotionTask",
            limbOption: .left,
            intendedUseDescription: "Measure left shoulder flexibility.",
            options: []
        )
    }
    
    func createRightShoulderRangeOfMotionTask() -> ORKOrderedTask {
        return ORKOrderedTask.shoulderRangeOfMotionTask(
            withIdentifier: "RightShoulderRangeOfMotionTask",
            limbOption: .right, // ORKPredefinedTaskLimbOption.left
            intendedUseDescription: "Measure right shoulder flexibility.",
            options: []
        )
    }
    
    // Function to create a knee range of motion task
    func createLeftKneeRangeOfMotionTask() -> ORKOrderedTask {
        return ORKOrderedTask.kneeRangeOfMotionTask(
            withIdentifier: "LeftKneeRangeOfMotionTask",
            limbOption: .left, // ORKPredefinedTaskLimbOption.left
            intendedUseDescription: "Measure knee flexibility.",
            options: []
        )
    }
    
    func createRightKneeRangeOfMotionTask() -> ORKOrderedTask {
        return ORKOrderedTask.kneeRangeOfMotionTask(
            withIdentifier: "RightKneeRangeOfMotionTask",
            limbOption: .right, // ORKPredefinedTaskLimbOption.left
            intendedUseDescription: "Measure knee flexibility.",
            options: []
        )
    }
}
