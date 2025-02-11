//
//  HipView.swift
//  MotionAnalysis
//
//  Created by Prashast Singh on 04.11.24.
//

import SwiftUI
import Foundation

//
//  KneeView.swift
//  MotionAnalysis
//
//  Created by Prashast Singh on 04.11.24.
//

import SwiftUI
import Foundation

struct HipView : View {
    var body: some View {
        VStack(spacing: 20) {
            Text("LEFT HIP MOVEMENTS")
                .font(.system(size: 30, weight: .bold))
            
            NavigationLink(destination: StoryboardViewWrapper(joint: .hip , bodySide: .left, recordDirection: .side)) {
                Text("FLEXION EXTENSION")
                    .font(.title2)
                    .frame(width: 350, height: 80)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 5)
                )
            }
            
            NavigationLink(destination: StoryboardViewWrapper(joint: .hip , bodySide: .left, recordDirection: .front)) {
                Text("ABDUCTION ADDUCTION")
                    .font(.title2)
                    .frame(width: 350, height: 80)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 5)
                )
            }
            
            Text("RIGHT HIP MOVEMENTS")
                .font(.system(size: 30, weight: .bold))
            NavigationLink(destination: StoryboardViewWrapper(joint: .hip , bodySide: .right, recordDirection: .side)) {
                Text("FLEXION EXTENSION")
                    .font(.title2)
                    .frame(width: 350, height: 80)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 5)
                )
            }
            
            NavigationLink(destination: StoryboardViewWrapper(joint: .hip , bodySide: .left, recordDirection: .front)) {
                Text("ABDUCTION ADDUCTION")
                    .font(.title2)
                    .frame(width: 350, height: 80)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 5)
                )
            }
            
        }
        .padding()
    }
}

