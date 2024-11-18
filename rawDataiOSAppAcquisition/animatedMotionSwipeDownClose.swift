//
//  animatedChevronMotionClose.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 17.10.24.
//

import SwiftUI


struct AnimatedSwipeDownCloseView: View {
    @State private var bounce = false
    @State private var showText = false

    var body: some View {
        Image(systemName: "chevron.compact.down")
            .font(.largeTitle)
            .offset(y: bounce ? 10 : 0)
            .animation(
                Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true),
                value: bounce
            )
            .onAppear {
                bounce = true
            }
        Text("Swipe down to close")
                    .padding(.top)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .opacity(showText ? 1 : 0)
                    .animation(
                        Animation.easeInOut(duration: 2).repeatForever(autoreverses: true),
                        value: showText
                    )
                    .onAppear {
                        showText = true
                    }
    }
}

#Preview {
    AnimatedSwipeDownCloseView()
}
