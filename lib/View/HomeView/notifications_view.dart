import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Models/notification_inbox_item.dart';
import 'package:lingola_buddy/Services/notification_inbox_store.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  static const Color _listPanelBackground = Color(0xFFF6F6F6);

  List<NotificationInboxItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await NotificationInboxStore.loadDelivered();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _clearAll() async {
    await NotificationInboxStore.clearAll();
    if (!mounted) return;
    setState(() => _items = []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 48,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(24, 48),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: SvgPicture.asset(
                        'assets/icons/arrow_left.svg',
                        width: 24,
                        height: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppTranslations.section('notifications', 'title'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.homeWelcomeTitle().copyWith(
                            fontSize: 20,
                            height: 28 / 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                            color: const Color(0xFF171717),
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _items.isEmpty ? null : _clearAll,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFE53935),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        AppTranslations.section('notifications', 'clear_all'),
                        style: AppTextStyles.homeSectionAction().copyWith(
                          color: const Color(0xFFE53935),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppTranslations.section(
                                  'notifications',
                                  'no_notifications',
                                ),
                                style: AppTextStyles.notificationCardTitle(),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppTranslations.section(
                                  'notifications',
                                  'no_notifications_desc',
                                ),
                                style: AppTextStyles.notificationCardBody(),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _listPanelBackground,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (var i = 0; i < _items.length; i++) ...[
                                    if (i > 0) const SizedBox(height: 16),
                                    _NotificationCard(item: _items[i]),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final NotificationInboxItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    item.emoji,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title,
                    style: AppTextStyles.notificationCardTitle(),
                  ),
                ),
              ],
            ),
            Text(
              item.description,
              style: AppTextStyles.notificationCardBody().copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
