#
# Be sure to run `pod lib lint DoSwiftKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DoSwiftKit'
  s.version          = '1.0.0'
  s.summary          = 'Pure, clean Swift debug toolkit with live view inspection, etc. | 纯粹、整洁的 Swift 调试工具包，支持实时视图检查等功能'
  
  s.description      = <<-DESC
  DoSwift is a pure Swift, zero-dependency iOS debugging toolkit rewritten from DoKit.
  Live view inspection is the core: colour picker, alignment ruler, view hierarchy and
  in-place property editing, plus network capture, console, performance sampling,
  UserDefaults and sandbox browsing.

  本工程是基于 Swift 对 DoKit 的彻底重写，零第三方依赖。核心是运行时视图检查：
  取色、量距、看层级、直接修改属性；另有网络抓包、控制台、性能采样、UserDefaults 与沙盒浏览。
  DESC
  
  s.homepage         = 'https://github.com/darkThanBlack/DoSwiftKit'
  s.license          = { :type => 'WTFPL', :file => 'LICENSE' }
  s.author           = { 'darkThanBlack' => '331614794@qq.com' }
  s.source           = { :git => 'https://github.com/darkThanBlack/DoSwiftKit.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '13.0'
  s.swift_versions = '5.9'
  
  s.source_files = 'Code/**/*.{swift,m,h}'
  s.resource_bundles = {
    'DoSwiftKitResources' => ['Resources/**/*.{json,strings,xcprivacy}']
  }
  
  # Build settings
  s.pod_target_xcconfig = {
    'SWIFT_VERSION' => '5.9',
    'IPHONEOS_DEPLOYMENT_TARGET' => '13.0'
  }
  
end
