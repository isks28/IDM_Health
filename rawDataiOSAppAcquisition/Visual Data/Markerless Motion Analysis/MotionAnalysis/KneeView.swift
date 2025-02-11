//
//  KneeView.swift
//  MotionAnalysis
//
//  Created by Prashast Singh on 04.11.24.
//

import SwiftUI
import Foundation

struct KneeView : View {
    var body: some View {
        VStack(spacing: 20) {
            Text("LEFT KNEE MOVEMENTS")
                .font(.system(size: 30, weight: .bold))
            
            NavigationLink(destination: StoryboardViewWrapper(joint: .knee , bodySide: .left, recordDirection: .side)) {
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
            
            Text("RIGHT KNEE MOVEMENTS")
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
            
            
            
        }
        .padding()
    }
}
