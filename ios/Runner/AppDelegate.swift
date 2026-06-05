import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Pluginler yalnızca didInitializeImplicitFlutterEngine içinde kayıt edilir (çift kayıt crash yapar).
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MicrophonePermissionPlugin")!
    MicrophonePermissionPlugin.register(with: registrar)
    VoiceAudioSessionPlugin.register(
      with: engineBridge.pluginRegistry.registrar(forPlugin: "VoiceAudioSessionPlugin")!
    )
  }
}
