import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Services/lingola_auth_service.dart';
import 'package:lingola_buddy/Services/session_local_storage.dart';

/// Sesli/görüntülü arama WebSocket'i için JWT.
Future<String> ensureRealtimeAuthToken(WidgetRef ref) async {
  final stored = await SessionLocalStorage.getAuthToken();
  if (stored != null && stored.isNotEmpty) return stored;

  // signInAsGuest → _parseAuthData oturumu zaten SessionLocalStorage'a yazar.
  final guest = await LingolaAuthService().signInAsGuest();
  return guest.token;
}
