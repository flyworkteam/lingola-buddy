import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Riverpod/Controllers/SessionController/session_controller.dart';

final sessionInitialStateProvider = Provider<SessionState>(
  (ref) => const SessionState(),
);
