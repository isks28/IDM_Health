//
//  RangeOfMotionManager.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 18.02.25.
//

import ResearchKit

class RangeOfMotionManager: NSObject {
    
    // Singleton instance
    static let shared = RangeOfMotionManager()
    
    private override init() {
        super.init()
    }
    
    // Function to create a shoulder range of motion task
    func createShoulderRangeOfMotionTask() -> ORKOrderedTask {
        return ORKOrderedTask.shoulderRangeOfMotionTask(
            withIdentifier: "ShoulderRangeOfMotionTask",
            limbOption: .left, // ORKPredefinedTaskLimbOption.left
            intendedUseDescription: "Measure shoulder flexibility.",
            options: []
        )
    }
    
    // Function to create a knee range of motion task
    func createKneeRangeOfMotionTask() -> ORKOrderedTask {
        return ORKOrderedTask.kneeRangeOfMotionTask(
            withIdentifier: "KneeRangeOfMotionTask",
            limbOption: .left, // ORKPredefinedTaskLimbOption.left
            intendedUseDescription: "Measure knee flexibility.",
            options: []
        )
    }
}
