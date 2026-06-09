import AVFoundation
import Flutter
import UIKit

enum VoiceAudioSessionPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "lingolabuddy/voice_audio_session",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      let session = AVAudioSession.sharedInstance()
      do {
        switch call.method {
        case "configureForVoiceCall":
          let preferSpeaker =
            (call.arguments as? [String: Any])?["preferSpeaker"] as? Bool ?? false
          var options: AVAudioSession.CategoryOptions = [
            .allowBluetooth,
            .allowBluetoothA2DP,
          ]
          if preferSpeaker {
            options.insert(.defaultToSpeaker)
          }
          try session.setCategory(.playAndRecord, mode: .voiceChat, options: options)
          if session.mode != .voiceChat {
            try? session.setMode(.voiceChat)
          }
          try session.setActive(true, options: [])
          try session.overrideOutputAudioPort(preferSpeaker ? .speaker : .none)
          result(session.mode.rawValue)

        case "setSpeakerOn":
          let on = (call.arguments as? [String: Any])?["on"] as? Bool ?? false
          try session.overrideOutputAudioPort(on ? .speaker : .none)
          result(on)

        case "resetAudioSession":
          try session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers]
          )
          try session.setActive(true)
          DispatchQueue.main.async {
            UIDevice.current.isProximityMonitoringEnabled = false
          }
          result(nil)

        case "setProximityMonitoring":
          let on = (call.arguments as? [String: Any])?["on"] as? Bool ?? false
          DispatchQueue.main.async {
            UIDevice.current.isProximityMonitoringEnabled = on
          }
          result(on)

        default:
          result(FlutterMethodNotImplemented)
        }
      } catch {
        result(
          FlutterError(
            code: "AUDIO_SESSION_ERROR",
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    }
  }
}
