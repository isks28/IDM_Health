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
            NavigationLink(destination: RangeOfMotionView(taskType: .shoulder)) {
                HStack {
                    Image(systemName: "person.crop.square.badge.camera")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 40)
                        .foregroundStyle(Color.blue)
                    Text("Range of motion")
                        .font(.title2)
                    Spacer()
                }
            }
            
            NavigationLink(destination: RangeOfMotionView(taskType: .knee)) {
                HStack {
                    Image(systemName: "person.crop.square.badge.camera")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 40)
                        .foregroundStyle(Color.blue)
                    Text("Range of motion")
                        .font(.title2)
                    Spacer()
                }
            }
        }
        .navigationTitle("Range of Motion Tasks")
    }
}
