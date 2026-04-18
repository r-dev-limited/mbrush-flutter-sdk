#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint mbrush_flutter_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'mbrush_flutter_sdk'
  s.version          = '0.0.1'
  s.summary          = 'mbrush printer plugin for Flutter.'
  s.description      = <<-DESC
mbrush printer plugin for text chunking, .mbd conversion, and local HTTP upload.
                       DESC
  s.homepage         = 'https://tomas.radvansky.org'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'rdev.co.nz' => 'dev@tomas.radvansky.org' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'mbrush_flutter_sdk_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
