#
# Be sure to run `pod lib lint SwiftPhoenixClient.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "SwiftPhoenixClient"
  s.version          = "5.1.0"
  s.summary          = "Connect your Phoenix and iOS applications through WebSockets!"
  s.swift_version    = "5.0"
  s.description  = <<-EOS
  SwiftPhoenixClient is a Swift port of phoenix.js, abstracting away the details
  of the Phoenix Channels library and providing a near identical experience
  to connect to your Phoenix WebSockets on iOS.

  RxSwift extensions exist as well when subscribing to channel events.

  A default Transport layer is implmenented for iOS 13 or later. If targeting
  an earlier iOS version, please see the StarscreamSwiftPhoenixClient extention.
  EOS
  s.homepage         = "https://github.com/davidstump/SwiftPhoenixClient"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "David Stump" => "david@davidstump.net" }
  s.source           = { :git => "https://github.com/davidstump/SwiftPhoenixClient.git", :tag => s.version.to_s }
  s.ios.deployment_target     = '10.0'
  s.osx.deployment_target     = '10.12'
  s.tvos.deployment_target    = '10.0'
  s.watchos.deployment_target = '3.0'

  s.swift_version = '5.0'
  s.source_files  = "Sources/SwiftPhoenixClient/"
end
