
import Foundation

// MARK: Run configurations

/// TFLite Delegate used to run the model.
enum Delegates: String, CaseIterable {
  case cpu = "CPU"
  case gpu = "GPU"
  case npu = "NPU"
}

/// Information about a TFLite model file.
struct FileInfo {
  var name: String
  var ext: String
}

/// Type of the pose estimation model to be used.
enum ModelType: String, CaseIterable {
  case posenet = "Posenet"
  case movenetLighting = "Lightning"  // Movenet lightning
  case movenetThunder = "Thunder"  // Movenet thunder
}

