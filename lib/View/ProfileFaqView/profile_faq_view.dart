import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';

/// SSS — Figma: gri panel içinde beyaz akordeon kartlar.
class ProfileFaqView extends StatefulWidget {
  const ProfileFaqView({super.key});

  static const Color _panelBackground = Color(0xFFF6F6F6);

  @override
  State<ProfileFaqView> createState() => _ProfileFaqViewState();
}

class _ProfileFaqViewState extends State<ProfileFaqView> {
  int? _expandedIndex;

  List<_FaqItem> get _items => [
    _FaqItem(
      question: AppTranslations.section('profile_faq', 'q1'),
      answer: AppTranslations.section('profile_faq', 'a1'),
    ),
    _FaqItem(
      question: AppTranslations.section('profile_faq', 'q2'),
      answer: AppTranslations.section('profile_faq', 'a2'),
    ),
    _FaqItem(
      question: AppTranslations.section('profile_faq', 'q3'),
      answer: AppTranslations.section('profile_faq', 'a3'),
    ),
  ];

  void _onTileTap(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _FaqHeader(),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: ProfileFaqView._panelBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          for (var i = 0; i < _items.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            _FaqTile(
                              item: _items[i],
                              expanded: _expandedIndex == i,
                              onTap: () => _onTileTap(i),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqHeader extends StatelessWidget {
  const _FaqHeader();

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
                AppTranslations.section('profile_faq', 'title'),
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

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.item,
    required this.expanded,
    required this.onTap,
  });

  final _FaqItem item;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.question,
                      style: AppTextStyles.profileFaqQuestion(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: SvgPicture.asset(
                      'assets/icons/arrow_down.svg',
                      width: 24,
                      height: 24,
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 10, right: 4),
                  child: Text(
                    item.answer,
                    style: AppTextStyles.profileFaqAnswer(),
                  ),
                ),
                crossFadeState: expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
                sizeCurve: Curves.easeInOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
