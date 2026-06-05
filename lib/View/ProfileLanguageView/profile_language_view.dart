import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Config/app_ui_languages.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Widgets/app_primary_button.dart';
import 'package:lingola_buddy/Core/Widgets/future_extensions_dialog.dart';
import 'package:lingola_buddy/Core/Widgets/profile_language_option_tile.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutors_catalog_provider.dart';
import 'package:lingola_buddy/Services/local_notification_scheduler.dart';
import 'package:lingola_buddy/Services/session_local_storage.dart';

/// Uygulama dili — Figma: gri panel, beyaz liste, 12px köşeli dil satırları, kaydet CTA.
class ProfileLanguageView extends ConsumerStatefulWidget {
  const ProfileLanguageView({super.key});

  static const Color _panelBackground = Color(0xFFF6F6F6);

  @override
  ConsumerState<ProfileLanguageView> createState() =>
      _ProfileLanguageViewState();
}

class _ProfileLanguageViewState extends ConsumerState<ProfileLanguageView> {
  String? _pendingCode;

  Future<void> _save() async {
    final code = _pendingCode;
    if (code == null) return;

    await FutureExtensionsDialog.guard(
      context,
      () async {
        await SessionLocalStorage.setUiLanguageCode(code, manual: true);
        await AppTranslations.setLocale(code);
        ref.read(userProfileControllerProvider.notifier).setUiLanguageCode(code);
        ref.invalidate(tutorsCatalogAsyncProvider);
        if (ref.read(userProfileControllerProvider).notificationsEnabled) {
          await LocalNotificationScheduler.instance.syncEnabled(enabled: true);
        }
      }(),
    );
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final savedCode = ref.watch(userProfileControllerProvider).uiLanguageCode;
    _pendingCode ??= savedCode;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _LanguageHeader(),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: ProfileLanguageView._panelBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              for (
                                var i = 0;
                                i < AppUiLanguages.entries.length;
                                i++
                              ) ...[
                                if (i > 0) const SizedBox(height: 8),
                                _LanguageOptionRow(
                                  row: AppUiLanguages.entries[i],
                                  selected:
                                      _pendingCode ==
                                      AppUiLanguages.entries[i].code,
                                  onTap: () => setState(
                                    () => _pendingCode =
                                        AppUiLanguages.entries[i].code,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: AppPrimaryButton(
                label: AppTranslations.section(
                  'profile_language',
                  'save_changes',
                ),
                foregroundColor: Colors.white,
                labelStyle: AppTextStyles.homeCharacterCta().copyWith(
                  color: Colors.white,
                ),
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageHeader extends StatelessWidget {
  const _LanguageHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            IconButton(
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
              icon: SvgPicture.asset(
                'assets/icons/arrow_left.svg',
                width: 24,
                height: 24,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                AppTranslations.section('profile_language', 'title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.homeWelcomeTitle().copyWith(
                  fontSize: 20,
                  height: 28 / 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: const Color(0xFF171717),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOptionRow extends StatelessWidget {
  const _LanguageOptionRow({
    required this.row,
    required this.selected,
    required this.onTap,
  });

  final AppUiLanguage row;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = AppTranslations.section('languages', row.code);

    return ProfileLanguageOptionTile(
      leading: ClipOval(
        child: SizedBox(
          width: 36,
          height: 36,
          child: SvgPicture.asset(
            row.flagAsset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
      ),
      label: label,
      selected: selected,
      onTap: onTap,
    );
  }
}
