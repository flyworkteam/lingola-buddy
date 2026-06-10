import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [AuthFlowHelper.completeSignIn] sonrası ana sayfada bir kez paywall göster.
final postLoginPaywallPendingProvider = StateProvider<bool>((ref) => false);
