//
//  RangeOfMotionContentView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 18.02.25.
//

import SwiftUI

struct RangeOfMotionContentView: View {
    var body: some View {
        List {
            NavigationLink(destination: RangeOfMotionView(taskType: .leftShoulder)) {
                HStack {
                    Text("Left shoulder")
                        .font(.title2)
                    Spacer()
                }
            }
            
            NavigationLink(destination: RangeOfMotionView(taskType: .rightShoulder)) {
                HStack {
                    Text("Right shoulder")
                        .font(.title2)
                    Spacer()
                }
            }
            
            NavigationLink(destination: RangeOfMotionView(taskType: .leftKnee)) {
                HStack {
                    Text("Left knee")
                        .font(.title2)
                    Spacer()
                }
            }
            
            NavigationLink(destination: RangeOfMotionView(taskType: .rightKnee)) {
                HStack {
                    Text("RIght knee")
                        .font(.title2)
                    Spacer()
                }
            }
        }
        .navigationTitle("Range of Motion")
    }
}
