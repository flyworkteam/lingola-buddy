import 'package:flutter/material.dart';

/// Tasarım (Figma) ile uyumlu sabit renkler. Material [ColorScheme] için
/// [AppTheme] içinde seed kullanılır; burada marka ve ekran özel tonları tutulur.
abstract final class AppColors {
  AppColors._();

  /// Birincil marka moru — başlık, vurgu, dolgu (Figma: #7429FF)
  static const Color brandPrimary = Color(0xFF7429FF);

  /// İkincil metin (Figma secondary-text)
  static const Color secondaryText = Color(0xFF727590);

  /// Tam genişlik primary CTA — tek katman, alttan üste (#7429FF tabanlı)
  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment(0, 1),
    end: Alignment(0, -1),
    colors: [
      Color(0xFF5A17D4),
      brandPrimary,
      Color(0xFF9568FF),
    ],
    stops: [0.0, 0.42, 1.0],
  );

  /// Onboarding / paywall CTA — alttan üste mor geçiş
  static const LinearGradient primaryCtaGradient = LinearGradient(
    begin: Alignment(0, 1),
    end: Alignment(0, -1),
    colors: [
      Color(0xFF5A17D4),
      brandPrimary,
      Color(0xFF8F56FF),
    ],
    stops: [0.0, 0.58, 1.0],
  );

  /// Splash: sol üst nane tonu
  static const Color splashGradientMint = Color(0xFFE8F5EF);

  /// Splash: sağ alt lavanta tonu
  static const Color splashGradientLavender = Color(0xFFE8E4FA);

  /// Splash arka plan — bulanık elips (Figma: #D8FFBD, layer blur ~200)
  static const Color splashAuraMint = Color(0xFFD8FFBD);

  /// Splash arka plan — bulanık elips (Figma: #D4BDFF, layer blur ~200)
  static const Color splashAuraLavender = Color(0xFFD4BDFF);

  /// Onboarding: üst (beyaza yakın)
  static const Color onboardingBackgroundTop = Color(0xFFFFFFFF);

  /// Onboarding: alt lavanta (hafif mor geçiş)
  static const Color onboardingBackgroundBottom = Color(0xFFF4F0FF);

  /// Onboarding: pasif ilerleme çubuğu
  static const Color onboardingProgressInactive = Color(0xFFD2D2D2);

  /// Gövde metni — siyah %65 opaklık (Figma)
  static const Color onboardingBodyMuted = Color(0xA6000000);

  /// Görüşme önizleme — Figma Accents/Green (vurgu / ikincil kullanım)
  static const Color callPreviewCtaGreen = Color(0xFF34C759);

  /// Aktif görüşme — başlık / süre metni (Figma #171717)
  static const Color activeCallForeground = Color(0xFF171717);

  /// Aktif görüşme — görüşmeyi bitir (Figma #F44336)
  static const Color activeCallEndHangup = Color(0xFFF44336);

  /// Görüşme önizleme CTA — yeşil dolgu üstüne parlama (Figma: beyaz / siyah yarı saydam)
  static const LinearGradient callPreviewCtaSheenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x52FFFFFF),
      Color(0x00000000),
      Color(0x52000000),
    ],
    stops: [0.0, 0.48, 1.0],
  );
}
