import AVFoundation
import FlutterMacOS

final class MicrophonePermissionPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.flywork.lingolabuddy/microphone",
      binaryMessenger: registrar.messenger
    )
    let instance = MicrophonePermissionPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  private static func configurePlaybackSession() {
    // macOS: playback için varsayılan çıkış yeterli; kayıt oturumundan sonra serbest bırak.
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "request":
      AVCaptureDevice.requestAccess(for: .audio) { granted in
        DispatchQueue.main.async {
          result(granted)
        }
      }
    case "isGranted":
      result(AVCaptureDevice.authorizationStatus(for: .audio) == .authorized)
    case "prepare":
      result(nil)
    case "preparePlayback":
      Self.configurePlaybackSession()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
