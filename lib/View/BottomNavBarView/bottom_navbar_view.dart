import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Riverpod/Controllers/BottomNavController/bottom_nav_controller.dart';
import 'package:lingola_buddy/View/BottomNavBarView/tab_navigator_shell.dart';
import 'package:lingola_buddy/View/ChatView/chat_view.dart';
import 'package:lingola_buddy/View/HomeView/home_view.dart';
import 'package:lingola_buddy/View/ProfileLanguageView/profile_language_view.dart';
import 'package:lingola_buddy/View/ProfileView/profile_view.dart';
import 'package:lingola_buddy/View/ProfileSettingsView/profile_settings_view.dart';
import 'package:lingola_buddy/View/ProfileFaqView/profile_faq_view.dart';
import 'package:lingola_buddy/View/ProfilePrivacyView/profile_privacy_view.dart';
import 'package:lingola_buddy/View/ProfileProgressView/profile_progress_view.dart';
import 'package:lingola_buddy/View/ProfileShareView/profile_share_view.dart';
import 'package:lingola_buddy/View/ProfileTermsView/profile_terms_view.dart';
import 'package:lingola_buddy/View/TalkHistoryView/talk_history_view.dart';
import 'package:lingola_buddy/View/TutorListView/tutor_list_view.dart';
import 'package:lingola_buddy/View/TutorProfileView/tutor_profile_view.dart';
import 'package:lingola_buddy/View/VideoCallView/video_call_view.dart';
import 'package:lingola_buddy/View/VoiceCallView/voice_call_view.dart';

class BottomNavBarView extends ConsumerStatefulWidget {
  const BottomNavBarView({super.key});

  @override
  ConsumerState<BottomNavBarView> createState() => _BottomNavBarViewState();
}

class _BottomNavBarViewState extends ConsumerState<BottomNavBarView> {
  final _homeKey = GlobalKey<NavigatorState>();
  final _tutorKey = GlobalKey<NavigatorState>();
  final _talkKey = GlobalKey<NavigatorState>();
  final _profileKey = GlobalKey<NavigatorState>();

  List<GlobalKey<NavigatorState>> get _keys => [
    _homeKey,
    _tutorKey,
    _talkKey,
    _profileKey,
  ];

  Future<void> _onBackInvoked() async {
    final idx = ref.read(bottomNavControllerProvider).index;
    final nav = _keys[idx].currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return;
    }
    if (idx != 0) {
      ref.read(bottomNavControllerProvider.notifier).setIndex(0);
    }
  }

  Route<dynamic>? _homeRoutes(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute<void>(
          builder: (_) => const HomeView(),
          settings: settings,
        );
      default:
        return null;
    }
  }

  Route<dynamic>? _tutorRoutes(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute<void>(
          builder: (_) => const TutorListView(),
          settings: settings,
        );
      case '/tutor':
        final id = settings.arguments is String
            ? settings.arguments as String
            : '';
        return MaterialPageRoute<void>(
          builder: (_) => TutorProfileView(tutorId: id),
          settings: settings,
        );
      case '/voice':
        final id = settings.arguments is String
            ? settings.arguments as String
            : '';
        return MaterialPageRoute<void>(
          builder: (_) => VoiceCallView(tutorId: id),
          settings: settings,
        );
      case '/video':
        final id = settings.arguments is String
            ? settings.arguments as String
            : '';
        return MaterialPageRoute<void>(
          builder: (_) => VideoCallView(tutorId: id),
          settings: settings,
        );
      case '/chat':
        final id = settings.arguments is String
            ? settings.arguments as String
            : '';
        return MaterialPageRoute<void>(
          builder: (_) => ChatView(tutorId: id),
          settings: settings,
        );
      default:
        return null;
    }
  }

  Route<dynamic>? _talkRoutes(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute<void>(
          builder: (_) => const TalkHistoryView(),
          settings: settings,
        );
      case '/chat':
        final id = settings.arguments is String
            ? settings.arguments as String
            : '';
        return MaterialPageRoute<void>(
          builder: (_) => ChatView(tutorId: id),
          settings: settings,
        );
      default:
        return null;
    }
  }

  Route<dynamic>? _profileRoutes(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileView(),
          settings: settings,
        );
      case '/settings':
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileSettingsView(),
          settings: settings,
        );
      case '/language':
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileLanguageView(),
          settings: settings,
        );
      case '/share':
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileShareView(),
          settings: settings,
        );
      case '/faq':
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileFaqView(),
          settings: settings,
        );
      case '/progress':
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileProgressView(),
          settings: settings,
        );
      case '/privacy':
        return MaterialPageRoute<void>(
          builder: (_) => const ProfilePrivacyView(),
          settings: settings,
        );
      case '/terms':
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileTermsView(),
          settings: settings,
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(bottomNavControllerProvider).index;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) await _onBackInvoked();
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: tabIndex,
          children: [
            TabNavigatorShell(
              navigatorKey: _homeKey,
              onGenerateRoute: _homeRoutes,
            ),
            TabNavigatorShell(
              navigatorKey: _tutorKey,
              onGenerateRoute: _tutorRoutes,
            ),
            TabNavigatorShell(
              navigatorKey: _talkKey,
              onGenerateRoute: _talkRoutes,
            ),
            TabNavigatorShell(
              navigatorKey: _profileKey,
              onGenerateRoute: _profileRoutes,
            ),
          ],
        ),
        bottomNavigationBar: _BottomNavBar(
          selectedIndex: tabIndex,
          onTabSelected: ref
              .read(bottomNavControllerProvider.notifier)
              .setIndex,
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  static const _items = [
    _BottomNavItemData(labelKey: 'home', iconPath: 'assets/icons/home.svg'),
    _BottomNavItemData(
      labelKey: 'tutor',
      iconPath: 'assets/icons/education.svg',
    ),
    _BottomNavItemData(labelKey: 'talk', iconPath: 'assets/icons/message.svg'),
    _BottomNavItemData(
      labelKey: 'profile',
      iconPath: 'assets/icons/profile.svg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            border: const Border(
              top: BorderSide(color: Color(0xFFDFDFDF), width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var index = 0; index < _items.length; index++)
                      _BottomNavItem(
                        data: _items[index],
                        selected: selectedIndex == index,
                        onTap: () => onTabSelected(index),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _BottomNavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brandPrimary : AppColors.secondaryText;
    final label = AppTranslations.section('navigation', data.labelKey);

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  data.iconPath,
                  width: 28,
                  height: 28,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
                const SizedBox(height: 4),
                Text(label, style: AppTextStyles.bottomNavLabel(color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItemData {
  const _BottomNavItemData({required this.labelKey, required this.iconPath});

  final String labelKey;
  final String iconPath;
}
