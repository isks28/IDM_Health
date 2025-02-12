import SwiftUI
import UIKit

struct StoryboardViewWrapper: UIViewControllerRepresentable {
    var joint : Joint
    var bodySide : BodySide
    var recordDirection: RecordDirection // New enum for record direction

    func makeUIViewController(context: Context) -> ViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        viewController.selectedJoint = joint
        viewController.selectedBodySide = bodySide
        viewController.recordDirection = recordDirection // Pass record direction to ViewController
        return viewController
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
}



