import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lingola_buddy/Core/Config/legal_urls.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Widgets/app_snackbar.dart';

abstract final class LegalLinkLauncher {
  LegalLinkLauncher._();

  static Future<void> openPrivacyPolicy(BuildContext context) =>
      _open(context, LegalUrls.privacyPolicy);

  static Future<void> openTermsOfService(BuildContext context) =>
      _open(context, LegalUrls.termsOfService);

  static Future<void> openContactUs(BuildContext context) =>
      _open(context, LegalUrls.contactUs);

  static Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      AppSnackBar.error(
        AppTranslations.section('common', 'link_open_failed'),
        context: context.mounted ? context : null,
      );
    }
  }
}
