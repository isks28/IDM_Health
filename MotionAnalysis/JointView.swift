import SwiftUI

struct JointView: View {
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("SELECT A JOINT")
                    .font(.system(size: 35, weight: .bold))
                
                    
                
                let joints = ["SHOULDER", "ELBOW", "KNEE", "HIP", "ANKLE"]
                
                ForEach(joints, id: \.self) { joint in
                    NavigationLinkButton(joint: joint)
                }
            }
            .padding()
            .whiteBackground()
        }
    }
}


struct NavigationLinkButton: View {
    let joint: String
    
    var body: some View {
        NavigationLink(destination: destinationView(for: joint)) {
            Text(joint)
                .font(.system(size: 25, weight: .bold))
                .frame(width: 300, height: 100)
                .background(Color.black)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
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

