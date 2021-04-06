# Uncomment the next line to define a global platform for your project
 platform :ios, '10.3'

def common
  pod 'Alamofire', '~> 5.1.0'
  pod 'Firebase/Analytics', '~> 7.5.0'
  pod 'Firebase/Crashlytics'
  pod 'IQKeyboardManagerSwift', '~> 6.5.5'
  pod 'MaterialComponents', '~> 118.2.0'
  pod 'PhoneNumberKit', '~> 3.3.1'
  pod 'RxSwift', '~> 5'
  pod 'RxCocoa', '~> 5'
  pod 'Starscream', '~> 3.1'
  pod 'SwiftJWT','~> 3.2.0'
  pod 'SwiftKeychainWrapper', '~> 3.4.0'
  pod 'SwiftLint', '~> 0.43.1'
  pod 'PureLayout', '~> 3.1.6'
  pod 'SwiftyGif', '~> 5.4.0'

end

target 'Armore' do
  use_frameworks!
  platform :ios, '10.3'

  # Pods for Armore
  common
end

target 'ArmoreUITests' do
  use_frameworks!
  platform :ios, '10.3'

  # Pods for Armore
  common
  pod 'Swifter', '~> 1.5.0'
end

target 'ArmoreTests' do
  use_frameworks!
  platform :ios, '10.3'

  # Pods for Armore
  common
  pod 'Swifter', '~> 1.5.0'
end

# Workaround to get rid of a bunch of warnings:
# https://www.jessesquires.com/blog/2020/07/20/xcode-12-drops-support-for-ios-8-fix-for-cocoapods/
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
