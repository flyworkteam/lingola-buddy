import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:lingola_buddy/Core/Config/app_ui_languages.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Widgets/tutor_avatar_image.dart';
import 'package:lingola_buddy/Models/tutor_model.dart';

/// Eğitmen kartı — ana sayfa yatay listesi ve eğitmen grid’inde ortak.
class CharacterCard extends StatelessWidget {
  const CharacterCard({
    super.key,
    required this.tutor,
    required this.displayName,
    required this.buttonLabel,
    required this.onPressed,
    this.width = designWidth,
    this.height = designHeight,
    this.backgroundColor = const Color(0xFFF6F6F6),
    this.elevated = false,
    this.compactFooter = false,
  });

  /// Ana sayfa yatay kartı ile aynı oran (grid [childAspectRatio] için).
  static const double designWidth = 190;
  static const double designHeight = 310;
  static const double designAspectRatio = designWidth / designHeight;

  static const double _footerBlockHeight = 104;

  final TutorModel tutor;
  final String displayName;
  final String buttonLabel;
  final VoidCallback onPressed;

  /// `null` ise üst widget genişliğine yayılır (ör. grid hücresi).
  final double? width;
  final double? height;
  final Color backgroundColor;
  final bool elevated;
  final bool compactFooter;

  bool get _isWhiteCard => backgroundColor == Colors.white;

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: backgroundColor,
      elevation: elevated ? 2 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final cacheW = TutorAvatarImage.decodePixels(
            context,
            width ?? designWidth,
          );
          TutorAvatarImage.precache(context, tutor, cacheWidth: cacheW);
          onPressed();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColoredBox(
                  color: Colors.white,
                  child: TutorAvatarImage(
                    tutor: tutor,
                    width: double.infinity,
                    height: double.infinity,
                    cacheWidth: TutorAvatarImage.decodePixels(
                      context,
                      width ?? designWidth,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: _footerBlockHeight,
              child: _isWhiteCard
                  ? _CharacterCardFooter(
                      displayName: displayName,
                      nativeLang: tutor.nativeLang,
                      buttonLabel: buttonLabel,
                      compact: compactFooter,
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _CharacterCardFooter(
                        displayName: displayName,
                        nativeLang: tutor.nativeLang,
                        buttonLabel: buttonLabel,
                        compact: compactFooter,
                      ),
                    ),
            ),
          ],
          ),
        ),
      ),
    );

    if (width != null) {
      return SizedBox(
        width: width,
        height: height ?? designHeight,
        child: card,
      );
    }
    return card;
  }
}

class _CharacterCardFooter extends StatelessWidget {
  const _CharacterCardFooter({
    required this.displayName,
    required this.nativeLang,
    required this.buttonLabel,
    this.compact = false,
  });

  final String displayName;
  final String nativeLang;
  final String buttonLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.homeCharacterName(),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppTranslations.section('tudor', 'native'),
                style: AppTextStyles.homeCharacterMeta(),
              ),
              const SizedBox(width: 4),
              SvgPicture.asset(
                AppUiLanguages.flagAssetFor(nativeLang),
                width: 15,
                height: 15,
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                buttonLabel,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: AppTextStyles.homeCharacterCta().copyWith(
                  fontSize: compact ? 14 : 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
