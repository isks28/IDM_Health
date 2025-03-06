//
//  GaitAndBalanceManager.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 24.02.25.
//

import ResearchKit
import ResearchKitUI
import ResearchKitActiveTask
import SwiftUI

class GaitAndBalanceManager: NSObject {
    
    static let shared = GaitAndBalanceManager()
    
    private override init() {
        super.init()
    }
    
    func createWalkBackAndForthTask() -> ORKOrderedTask {
        return ORKOrderedTask.walkBackAndForthTask(
            withIdentifier: "WalkAndForthTask",
            intendedUseDescription: "Measure back and forth walk ",
            walkDuration: 10,
            restDuration: 5,
            options: [.excludeConclusion])
    }
    
    func createGaitTask() -> ORKOrderedTask {
        return ORKOrderedTask.timedWalk(
            withIdentifier: "GaitTask",
            intendedUseDescription: "Measure timed walk",
            distanceInMeters: 10.0,
            timeLimit: 30,
            turnAroundTimeLimit: 5,
            includeAssistiveDeviceForm: true,
            options: [.excludeConclusion])
    }
    
    func createShortWalkTask() -> ORKOrderedTask {
        return ORKOrderedTask.shortWalk(
            withIdentifier: "ShotWalkTask",
            intendedUseDescription: "Measure short walk",
            numberOfStepsPerLeg: 25,
            restDuration: 30,
            options: [.excludeConclusion])
    }
    
    func createSixMinuteWalkTask() -> ORKOrderedTask {
        return ORKOrderedTask.sixMinuteWalk(
            withIdentifier: "SixMinuteWalk",
            intendedUseDescription: "Measure six minute walk test",
            options: [.excludeConclusion])
    }
}
