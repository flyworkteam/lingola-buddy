import AVFoundation
import Flutter

final class MicrophonePermissionPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.flywork.lingolabuddy/microphone",
      binaryMessenger: registrar.messenger()
    )
    let instance = MicrophonePermissionPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "request":
      Self.requestPermission(result: result)
    case "isGranted":
      result(Self.isGranted())
    case "prepare":
      Self.configureRecordingSession()
      result(nil)
    case "preparePlayback":
      Self.configurePlaybackSession()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func isGranted() -> Bool {
    AVAudioSession.sharedInstance().recordPermission == .granted
  }

  private static func configureRecordingSession() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(
      .playAndRecord,
      mode: .spokenAudio,
      options: [.defaultToSpeaker, .allowBluetooth]
    )
    try? session.setActive(true)
  }

  private static func configurePlaybackSession() {
    let session = AVAudioSession.sharedInstance()
    try? session.setActive(false, options: .notifyOthersOnDeactivation)
    try? session.setCategory(
      .playback,
      mode: .spokenAudio,
      options: [.mixWithOthers]
    )
    try? session.setActive(true)
  }

  private static func requestPermission(result: @escaping FlutterResult) {
    configureRecordingSession()
    if #available(iOS 17.0, *) {
      AVAudioApplication.requestRecordPermission { granted in
        DispatchQueue.main.async {
          result(granted)
        }
      }
    } else {
      AVAudioSession.sharedInstance().requestRecordPermission { granted in
        DispatchQueue.main.async {
          result(granted)
        }
      }
    }
  }
}
