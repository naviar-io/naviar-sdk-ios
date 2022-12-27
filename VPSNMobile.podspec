Pod::Spec.new do |s|
  s.name             = 'VPSNMobile'
  s.version          = '0.3.5'
  s.summary          = 'VPSNMobile'
  s.homepage         = 'https://github.com/naviar-io/naviar-sdk-ios'
  s.license          = { :type => 'MIT License', :file => 'LICENSE' }
  s.author           = { "naviar.io" => "info@naviar.io" }
  s.source           = { :git => 'https://github.com/naviar-io/naviar-sdk-ios.git', :tag => "#{s.version}" }
  s.ios.deployment_target = '12.0'
  s.swift_version = '5.0'
  s.source_files = 'VPSNMobile/**/*.{swift}'
  s.frameworks   = 'Foundation', 'UIKit', 'CoreLocation', 'SceneKit', 'Accelerate'
  s.weak_frameworks   = 'ARKit'
  s.requires_arc = true
  s.static_framework = true
  s.dependency 'TensorFlowLiteSwift', '2.5.0'
  s.dependency 'TensorFlowLiteSwift/Metal', '2.5.0'
  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
end