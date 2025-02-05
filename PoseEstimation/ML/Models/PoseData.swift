

import UIKit

// MARK: Detection result
/// Time required to run pose estimation on one frame.
struct Times {
  var preprocessing: TimeInterval
  var inference: TimeInterval
  var postprocessing: TimeInterval
  var total: TimeInterval { preprocessing + inference + postprocessing }
}

/// An enum describing a body part (e.g. nose, left eye etc.).
enum BodyPart: String, CaseIterable {
  case nose = "nose"
  case leftEye = "left eye"
  case rightEye = "right eye"
  case leftEar = "left ear"
  case rightEar = "right ear"
  case leftShoulder = "left shoulder"
  case rightShoulder = "right shoulder"
  case leftElbow = "left elbow"
  case rightElbow = "right elbow"
  case leftWrist = "left wrist"
  case rightWrist = "right wrist"
  case leftHip = "left hip"
  case rightHip = "right hip"
  case leftKnee = "left knee"
  case rightKnee = "right knee"
  case leftAnkle = "left ankle"
  case rightAnkle = "right ankle"

  /// Get the index of the body part in the array returned by pose estimation models.
  var position: Int {
    return BodyPart.allCases.firstIndex(of: self) ?? 0
  }
}

/// A body keypoint (e.g. nose) 's detection result.
struct KeyPoint {
  var bodyPart: BodyPart = .nose
  var coordinate: CGPoint = .zero
  var score: Float32 = 0.0
}

/// A person detected by a pose estimation model.
struct Person {
  var keyPoints: [KeyPoint]
  var score: Float32
}
