import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Widgets/character_card.dart';
import 'package:lingola_buddy/Models/tutor_model.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutors_catalog_provider.dart';

class TutorListView extends ConsumerStatefulWidget {
  const TutorListView({super.key});

  @override
  ConsumerState<TutorListView> createState() => _TutorListViewState();
}

class _TutorListViewState extends ConsumerState<TutorListView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _displayName(TutorModel t) => t.localizedDisplayName;

  List<TutorModel> _filtered(List<TutorModel> all, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where(
          (t) =>
              _displayName(t).toLowerCase().contains(q) ||
              t.id.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final tutors = ref.watch(tutorsCatalogProvider);
    final filtered = _filtered(tutors, _searchController.text);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppTranslations.section('tudor', 'title'),
                style: AppTextStyles.homeWelcomeTitle(),
              ),
              const SizedBox(height: 8),
              Text(
                AppTranslations.section('tudor', 'description'),
                style: AppTextStyles.tudorSelectSubtitle(),
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/search.svg',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: AppTextStyles.tudorSearchField().copyWith(
                            color: Colors.black,
                          ),
                          cursorColor: AppColors.brandPrimary,
                          decoration: InputDecoration(
                            hintText: AppTranslations.section(
                              'tudor',
                              'search_tudor',
                            ),
                            hintStyle: AppTextStyles.tudorSearchField(),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppTranslations.section(
                                'tudor',
                                'no_tudors_found',
                              ),
                              style: AppTextStyles.homeCharacterName(),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppTranslations.section(
                                'tudor',
                                'no_tudors_found_desc',
                              ),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.tudorSelectSubtitle(),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        physics: ClampingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: CharacterCard.designAspectRatio,
                            ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final t = filtered[index];
                          return CharacterCard(
                            tutor: t,
                            displayName: _displayName(t),
                            buttonLabel: AppTranslations.section(
                              'tudor',
                              'start_talking',
                            ),
                            width: null,
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/tutor',
                              arguments: t.id,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
