// Firebase yapılandırması — ios/Runner/GoogleService-Info.plist ve
// android/app/google-services.json dosyalarından üretildi.
//
// Yeniden oluşturmak için: flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions web için yapılandırılmadı. '
        'flutterfire configure ile web uygulaması ekleyin.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions macOS için yapılandırılmadı.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions Windows için yapılandırılmadı.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions Linux için yapılandırılmadı.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions bu platform için tanımlı değil.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDk6gpu2PaarLJTHfCv0UKM1AJtDsycEQU',
    appId: '1:768085789416:android:e15e7961a47436671ad75d',
    messagingSenderId: '768085789416',
    projectId: 'lingolabuddy',
    storageBucket: 'lingolabuddy.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyArceFYE9IqtrJlW4HZFZLNAxiRMxompJY',
    appId: '1:768085789416:ios:3a6b127b6c5e88ad1ad75d',
    messagingSenderId: '768085789416',
    projectId: 'lingolabuddy',
    storageBucket: 'lingolabuddy.firebasestorage.app',
    iosBundleId: 'com.flywork.lingolabuddy',
    iosClientId:
        '768085789416-ie4ct7mde6mcvifrhc80eui7rkeuro19.apps.googleusercontent.com',
  );
}
