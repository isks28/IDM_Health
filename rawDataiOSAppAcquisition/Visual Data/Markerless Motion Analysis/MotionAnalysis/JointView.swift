import SwiftUI

struct JointView: View {
    var body: some View {
        VStack(spacing: 25) {
            Text("SELECT A JOINT")
                .font(.title)
                .bold()

            let joints = ["SHOULDER", "ELBOW", "KNEE", "HIP", "ANKLE"]

            ForEach(joints, id: \.self) { joint in
                NavigationLinkButton(joint: joint)
            }
        }
        .padding()
        .whiteBackground()
    }
}

struct NavigationLinkButton: View {
    let joint: String

    var body: some View {
        NavigationLink(destination: destinationView(for: joint)) {
            Text(joint)
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

    @ViewBuilder
    private func destinationView(for joint: String) -> some View {
        switch joint {
        case "SHOULDER":
            ShoulderView()
                .whiteBackground()
        case "ELBOW":
            ElbowView()
                .whiteBackground()
        case "KNEE":
            KneeView()
                .whiteBackground()
        case "HIP":
            HipView()
                .whiteBackground()
        case "ANKLE":
            AnkleView()
                .whiteBackground()
        default:
            Text("No View Available")
        }
    }
}

#Preview {
    JointView()
}
