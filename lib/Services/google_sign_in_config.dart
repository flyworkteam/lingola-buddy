import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:lingola_buddy/firebase_options.dart';

/// Firebase / Google Cloud web client (google-services.json → oauth_client type 3)
const String kGoogleWebClientId =
    '768085789416-a4jnr9ms6c857j9joqferofdiceas29h.apps.googleusercontent.com';

GoogleSignIn createConfiguredGoogleSignIn() {
  return GoogleSignIn(
    scopes: const ['email', 'profile'],
    // iOS: GIDClientID — Info.plist ile birlikte
    clientId: Platform.isIOS ? DefaultFirebaseOptions.ios.iosClientId : null,
    // Firebase Auth idToken için web client (Android zorunlu, iOS önerilir)
    serverClientId: kGoogleWebClientId,
  );
}
