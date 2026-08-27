source 'https://github.com/CocoaPods/Specs.git'

# Uncomment the next line to define a global platform for your project
platform :ios, '16.0'

target 'FreeAudiobooks' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  pod 'GoogleSignIn'
  pod 'FirebaseCore'
  pod 'FirebaseFirestore'
  pod 'FirebaseAuth'
  pod 'FirebaseRemoteConfig'
  pod 'FirebasePerformance'
  pod 'FirebaseStorage'
  pod 'FirebaseMessaging'
  pod 'FirebaseAnalytics'
  pod 'FirebaseCrashlytics'
  pod 'FirebaseFunctions'
  pod 'FBSDKCoreKit'
  pod 'NVActivityIndicatorView'
  pod 'PopupDialog'
  pod 'BEMCheckBox'
  pod 'TextFieldEffects'
  pod 'Kingfisher', '7.8.1'
  pod 'Instructions'
  pod 'lottie-ios'
  pod 'BetterSegmentedControl'
  pod 'Cosmos', '~> 25.0'
  pod 'Google-Mobile-Ads-SDK'
  pod 'SuperwallKit', '4.16.3'
  pod 'SkeletonView', '~> 1.30'

  # Pods for FreeAudiobooks

  target 'FreeAudiobooksTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
    if target.name == 'BoringSSL-GRPC'
      target.source_build_phase.files.each do |file|
        if file.settings && file.settings['COMPILER_FLAGS']
          flags = file.settings['COMPILER_FLAGS'].split
          flags.reject! { |flag| flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
          file.settings['COMPILER_FLAGS'] = flags.join(' ')
        end
      end
    end
  end
  
  # Issue with CocoaPods & Xcode 15. Should be able to remove soon...: https://github.com/CocoaPods/CocoaPods/issues/12012
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        xcconfig_path = config.base_configuration_reference.real_path
        xcconfig = File.read(xcconfig_path)
        xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
        File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
      end
    end
end
