import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/main.dart';

void main() {
  testWidgets('Uygulama açılıyor', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppTranslations.load();
    await tester.pumpWidget(
      const ProviderScope(child: LingolaBuddyApp()),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
