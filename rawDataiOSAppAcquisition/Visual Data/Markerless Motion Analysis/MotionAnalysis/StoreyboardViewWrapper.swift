import SwiftUI
import UIKit

struct StoryboardViewWrapper: UIViewControllerRepresentable {
    var shoulderSide: ShoulderSide
    var recordDirection: RecordDirection // New enum for record direction

    func makeUIViewController(context: Context) -> ViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        viewController.selectedShoulder = shoulderSide
        viewController.recordDirection = recordDirection // Pass record direction to ViewController
        return viewController
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
}



