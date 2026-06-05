import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/PremiumController/premium_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/curriculum_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/daily_conversation_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/streak_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/talk_history_provider.dart';

/// Çıkış / yeni giriş: önceki hesabın önbelleğini temizler.
void resetUserScopedAppState(WidgetRef ref) {
  ref.invalidate(userCurriculumProvider);
  ref.invalidate(userDailyConversationProvider);
  ref.invalidate(userStreakProvider);
  ref.invalidate(talkHistoryProvider);
  ref.invalidate(premiumControllerProvider);
  ref.read(callSessionControllerProvider.notifier).clearActiveSession();
}
