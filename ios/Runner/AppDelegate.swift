import UIKit
import Flutter
import GoogleMaps

@main // Note: Use @main on newer Flutter/Xcode versions, or keep @UIApplicationMain if on an older version
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyBySvNF6Pqt0SkNZxU1D5PCW103TcdWg1g")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}