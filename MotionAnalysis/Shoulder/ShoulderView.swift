//
//  ShoulderView.swift
//  MotionAnalysis
//
//  Created by Prashast Singh on 04.11.24.
//
import SwiftUI
import Foundation

struct ShoulderView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("LEFT SHOULDER MOVEMENTS")
                    .font(.system(size: 30, weight: .bold))
                
                NavigationLink(destination: StoryboardViewWrapper(shoulderSide: .left, recordDirection: .side)) {
                    Text("FLEXION EXTENSION")
                        .font(.system(size: 25, weight: .bold))
                        .frame(width: 300, height: 100)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                NavigationLink(destination: StoryboardViewWrapper(shoulderSide: .left, recordDirection: .front)) {
                    Text("ABDUCTION ADDUCTION")
                        .font(.system(size: 25, weight: .bold))
                        .frame(width: 300, height: 100)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Text("RIGHT SHOULDER MOVEMENTS")
                    .font(.system(size: 30, weight: .bold))
                
                NavigationLink(destination: StoryboardViewWrapper(shoulderSide: .right, recordDirection: .side)) {
                    Text("FLEXION EXTENSION")
                        .font(.system(size: 25, weight: .bold))
                        .frame(width: 300, height: 100)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                NavigationLink(destination: StoryboardViewWrapper(shoulderSide: .right, recordDirection: .front)) {
                    Text("ABDUCTION ADDUCTION")
                        .font(.system(size: 25, weight: .bold))
                        .frame(width: 300, height: 100)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
            .whiteBackground()
        }
    }
}
