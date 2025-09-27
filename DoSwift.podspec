#
# Be sure to run `pod lib lint DoSwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DoSwift'
  s.version          = '0.1.0'
  s.summary          = 'A pure Swift iOS debugging toolkit based on DoKit-iOS refactoring.'

  s.description      = <<-DESC
DoSwift is a pure Swift iOS debugging toolkit library refactored from DoKit-iOS.
It features a standard UIWindow handling framework inspired by MOONAssistiveTouch,
supports floating controls and multi-level menus, and provides a plugin-based architecture
for debugging tools.
                       DESC

  s.homepage         = 'https://github.com/darkThanBlack/DoSwift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'darkThanBlack' => 'darkthanblack@example.com' }
  s.source           = { :git => 'https://github.com/darkThanBlack/DoSwift.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_versions = '5.9'

  # All source files in one library
  s.source_files = 'Sources/DoSwift/**/*'

  # Framework settings
  s.frameworks = 'UIKit', 'Foundation'
  s.requires_arc = true

  # Build settings
  s.pod_target_xcconfig = {
    'SWIFT_VERSION' => '5.9',
    'IPHONEOS_DEPLOYMENT_TARGET' => '13.0'
  }
end
