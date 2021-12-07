platform :ios, '11.4'

inhibit_all_warnings!

def projectPods
  use_frameworks!
  pod 'SwiftGen'
  pod 'lottie-ios'
  pod 'TagListView'
  pod 'Charts'
  pod 'ZXingObjC'
  pod 'SwiftGen'
end

target 'TousAntiCovid' do
  projectPods
end





target 'StorageSDK' do
  use_frameworks!
  pod 'KeychainSwift'
  pod 'RealmSwift'
end

target 'RobertSDK' do
  use_frameworks!
  pod 'SwCrypt'
end



post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.4'
    end
  end
end
