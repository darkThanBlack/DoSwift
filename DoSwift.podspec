#
# Be sure to run `pod lib lint DoSwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DoSwift'
  s.version          = '1.0.0'
  s.summary          = 'Pure Swift debug tool inspired by DoKit | 纯 Swift 版 DoKit'
  
  s.description      = <<-DESC
  Pure, clean Swift debug toolkit with live view inspection, etc. | 纯粹、整洁的 Swift 调试工具包，支持实时视图检查等功能。
  DESC
  
  s.homepage         = 'https://github.com/darkThanBlack/DoSwift'
  s.license          = { :type => 'WTFPL', :file => 'LICENSE' }
  s.author           = { 'darkThanBlack' => '331614794@qq.com' }
  s.source           = { :git => 'https://github.com/darkThanBlack/DoSwift.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '13.0'
  s.swift_versions = '5.9'
  
  s.source_files = 'Code/**/*.{swift,m,h}'
  s.resource_bundles = {
    'DoSwiftResources' => ['Resources/**/*.{json,strings}']
  }
  
  # Build settings
  s.pod_target_xcconfig = {
    'SWIFT_VERSION' => '5.7',
    'IPHONEOS_DEPLOYMENT_TARGET' => '13.0'
  }
  
end
