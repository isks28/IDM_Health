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
    
    func createGaitTask() -> ORKOrderedTask {
        return ORKOrderedTask.walkBackAndForthTask(
            withIdentifier: "GaitTask",
            intendedUseDescription: "Measure walking balance and coordination.",
            walkDuration: 10,
            restDuration: 5,
            options: [.excludeConclusion]
        )
    }
    
    func createBalanceTask() -> ORKOrderedTask {
        return ORKOrderedTask.sixMinuteWalk(
            withIdentifier: "SixMinuteWalk",
            intendedUseDescription: "Measure six minute walk test",
            options: [.excludeConclusion])
    }
}
