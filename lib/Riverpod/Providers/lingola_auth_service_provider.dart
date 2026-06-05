import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Services/lingola_auth_service.dart';

final lingolaAuthServiceProvider = Provider<LingolaAuthService>((ref) {
  return LingolaAuthService();
});
