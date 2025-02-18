# Uncomment the next line to define a global platform for your project
# platform :ios, '12.0'  

# Ignore all warnings from all pods
inhibit_all_warnings!

project 'IDM Health.xcodeproj'  # Specify your project path

target 'rawDataiOSAppAcquisition' do
  platform :ios, '18.0'
  use_frameworks!  # Use dynamic frameworks
  
  # Existing pod
  pod 'LiteRTSwift', '~> 0.0.1-nightly', :subspecs => ['CoreML', 'Metal']

  # Add ResearchKit for Active Tasks like Range of Motion
  pod 'ResearchKit'

end
