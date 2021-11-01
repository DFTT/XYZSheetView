#
# Be sure to run `pod lib lint XYZAd.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#




Pod::Spec.new do |s|
  s.name             = 'XYZSheetView'
  s.version          = '1.1.3'
  s.summary          = 'XYZSheetView...'
  s.description      = <<-DESC
                       XYZSheetView Description...
                       DESC

  s.homepage         = 'https://github.com/DFTT'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'XYZSheetView' => 'lidong@021.com' }
  s.source           = { :git => 'https://github.com/DFTT/XYZSheetView.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '9.0'
  s.frameworks      = 'Foundation', 'UIKit'

  # s.user_target_xcconfig =  {'OTHER_LDFLAGS' => ['-lObjC']}
  # s.pod_target_xcconfig  =  {'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'}

  s.requires_arc = true

  s.source_files = 'XYZSheetView/Classes/**/*.{h,m}'
  s.public_header_files = 'XYZSheetView/Classes/**/*.{h}'
  
end
