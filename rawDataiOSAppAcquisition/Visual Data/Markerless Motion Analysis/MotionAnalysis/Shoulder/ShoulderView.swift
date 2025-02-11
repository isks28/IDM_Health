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
                    .font(.title)
                    .bold()
                
                NavigationLink(destination: StoryboardViewWrapper(shoulderSide: .left, recordDirection: .side)) {
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
                
                NavigationLink(destination: StoryboardViewWrapper(shoulderSide: .left, recordDirection: .front)) {
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
                
                Text("RIGHT SHOULDER MOVEMENTS")
                    .font(.title)
                    .bold()
                
                NavigationLink(destination: StoryboardViewWrapper(shoulderSide: .right, recordDirection: .side)) {
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
                
                NavigationLink(destination: StoryboardViewWrapper(shoulderSide: .right, recordDirection: .front)) {
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
            .whiteBackground()
        }
    }
}
