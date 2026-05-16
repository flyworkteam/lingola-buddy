import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lingola_buddy/Core/Config/legal_urls.dart';

abstract final class LegalLinkLauncher {
  LegalLinkLauncher._();

  static Future<void> openPrivacyPolicy(BuildContext context) =>
      _open(context, LegalUrls.privacyPolicy);

  static Future<void> openTermsOfService(BuildContext context) =>
      _open(context, LegalUrls.termsOfService);

  static Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bağlantı açılamadı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
