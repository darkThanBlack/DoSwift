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
  s.summary          = 'Pure Swift debug tool inspired by DoKit | 纯 Swift 版 DoKit'
  
  s.description      = <<-DESC
  This project is a complete rewrite of DoKit by Swift, retaining only the core capabilities that have been redesigned. |
  本工程是基于 Swift 对 DoKit 的彻底重写，只保留重新设计过的核心能力。
  DESC
  
  s.homepage         = 'https://github.com/darkThanBlack/DoSwift'
  s.license          = { :type => 'WTFPL', :file => 'LICENSE' }
  s.author           = { 'darkThanBlack' => 'darkthanblack@example.com' }
  s.source           = { :git => 'https://github.com/darkThanBlack/DoSwift.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '13.0'
  s.swift_versions = '5.7'
  
  s.source_files = 'Code/**/*.{swift,m,h}'
  s.resource_bundles = {
    'DoSwiftResources' => ['Resources/**/*.{json}']
  }
  
  # Build settings
  s.pod_target_xcconfig = {
    'SWIFT_VERSION' => '5.7',
    'IPHONEOS_DEPLOYMENT_TARGET' => '13.0'
  }
  
end
