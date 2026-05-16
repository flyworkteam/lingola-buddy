import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lingola_buddy/Core/Theme/app_colors.dart';

/// Tekrar kullanılan metin stilleri. Ekran bazlı özel stiller buradan türetilir.
abstract final class AppTextStyles {
  AppTextStyles._();

  /// Splash / marka başlığı — Manrope ExtraBold 40 / satır 48 (Figma)
  static TextStyle splashAppTitle({Color? color}) {
    return GoogleFonts.manrope(
      fontSize: 40,
      height: 48 / 40,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
      color: color ?? AppColors.brandPrimary,
    );
  }

  /// Onboarding başlık — Manrope Bold 28 / satır 30, letter -1%
  static TextStyle onboardingHeadline({Color? color}) {
    return GoogleFonts.manrope(
      fontSize: 28,
      height: 30 / 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.28,
      color: color ?? const Color(0xFF000000),
    );
  }

  /// Onboarding alt metin — Manrope Medium 16 / satır 24, letter -1%
  static TextStyle onboardingBody() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.16,
      color: AppColors.onboardingBodyMuted,
    );
  }

  /// Onboarding birincil düğme metni — ~20px / satır 32 (Figma CTA)
  static TextStyle onboardingCta({Color? color}) {
    return GoogleFonts.manrope(
      fontSize: 20,
      height: 32 / 20,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.2,
      color: color ?? Colors.white,
    );
  }

  /// Sihirbaz dil ekranı başlık — Manrope Bold 24 / 32, -1%
  static TextStyle onboardingWizardTitle({Color? color}) {
    return GoogleFonts.manrope(
      fontSize: 24,
      height: 32 / 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.24,
      color: color ?? const Color(0xFF000000),
    );
  }

  /// Sihirbaz alt başlık — Manrope Regular 16 / 24, secondary
  static TextStyle onboardingWizardSubtitle() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.16,
      color: AppColors.secondaryText,
    );
  }

  /// Üst adım metni (örn. 1 / 3) — Manrope Medium 16 / 28
  static TextStyle onboardingWizardStepLabel() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 28 / 16,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.16,
      color: AppColors.secondaryText,
    );
  }

  /// Dil satırı etiket — Manrope SemiBold 16 / 18
  static TextStyle onboardingLanguageRow({required Color color}) {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 18 / 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.16,
      color: color,
    );
  }

  /// Plan oluşturma ana başlık — Manrope SemiBold 32 / 36, -1%
  static TextStyle generatingPlanHeadline() {
    return GoogleFonts.manrope(
      fontSize: 32,
      height: 36 / 32,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.32,
      color: const Color(0xFF000000),
    );
  }

  /// Plan hazır alt metin — Manrope Regular 16 / 24
  static TextStyle generatingPlanReadySubtitle() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.16,
      color: const Color(0xFF000000),
    );
  }

  /// Plan checklist satırı — Medium 16 / 24, bekleyen daha soluk
  static TextStyle generatingPlanCheckRow({required bool completed}) {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.16,
      color: AppColors.secondaryText.withValues(alpha: completed ? 1.0 : 0.55),
    );
  }

  /// Görüşme önizleme — isim (beyaz, SemiBold 24 / 28)
  static TextStyle callPreviewNameOnDark() {
    return GoogleFonts.manrope(
      fontSize: 24,
      height: 28 / 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.24,
      color: Colors.white,
    );
  }

  /// Görüşme önizleme — alt satır (beyaz, Medium 16 / 28)
  static TextStyle callPreviewSubtitleOnDark() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 28 / 16,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.16,
      color: Colors.white,
    );
  }

  /// Görüşme önizleme — yeşil CTA (Bold 20 / 32)
  static TextStyle callPreviewStartCta() {
    return GoogleFonts.manrope(
      fontSize: 20,
      height: 32 / 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: Colors.white,
    );
  }

  /// Görüşme önizleme — "Başka zaman" (Bold 16 / 22)
  static TextStyle callPreviewDeferLink() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 22 / 16,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.16,
      color: Colors.white,
    );
  }

  /// Aktif görüşme — katılımcı adı (Manrope SemiBold 24 / 28, #171717)
  static TextStyle activeCallParticipantName() {
    return GoogleFonts.manrope(
      fontSize: 24,
      height: 28 / 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.24,
      color: AppColors.activeCallForeground,
    );
  }

  /// Aktif görüşme — süre (Manrope Medium 16 / 28, #171717)
  static TextStyle activeCallTimer() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 28 / 16,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.16,
      color: AppColors.activeCallForeground,
    );
  }

  /// Arama özeti — üst geri bildirim başlığı (Bold 16 / 20)
  static TextStyle callSummaryFeedbackTitle() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 20 / 16,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.16,
      color: Colors.black,
    );
  }

  /// Arama özeti — durum satırı (Medium 14 / 18, siyah %65)
  static TextStyle callSummaryStatusLine() {
    return GoogleFonts.manrope(
      fontSize: 14,
      height: 18 / 14,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.14,
      color: Colors.black.withValues(alpha: 0.65),
    );
  }

  /// Arama özeti — kota rozeti metni (Bold 14 / 18, mor)
  static TextStyle callSummaryQuotaBadge() {
    return GoogleFonts.manrope(
      fontSize: 14,
      height: 18 / 14,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.14,
      color: AppColors.brandPrimary,
    );
  }

  /// Arama özeti — görüntü üstü isim (SemiBold 16 / 22, beyaz)
  static TextStyle callSummarySnapshotName() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 22 / 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.16,
      color: Colors.white,
    );
  }

  /// Arama özeti — görüntü üstü ayırıcı (Regular 16 / 22, beyaz)
  static TextStyle callSummarySnapshotSep() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 22 / 16,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.16,
      color: Colors.white,
    );
  }

  /// Arama özeti — istatistik etiketi (Süre, Kelimeler… — SemiBold 14 / 22, siyah %65)
  static TextStyle callSummaryStatLabel() {
    return GoogleFonts.manrope(
      fontSize: 14,
      height: 22 / 14,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.14,
      color: Colors.black.withValues(alpha: 0.65),
    );
  }

  /// Arama özeti — istatistik değeri (Bold 20 / 24, -1%)
  static TextStyle callSummaryStatValue({Color? color}) {
    return GoogleFonts.manrope(
      fontSize: 20,
      height: 24 / 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: color ?? Colors.black,
    );
  }

  /// Arama özeti — oturum skoru sol başlık (SemiBold 14 / 22, siyah)
  static TextStyle callSummaryScoreTitle() {
    return GoogleFonts.manrope(
      fontSize: 14,
      height: 22 / 14,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.14,
      color: Colors.black,
    );
  }

  /// Arama özeti — oturum skoru sağ yüzde (SemiBold 14 / 22, siyah %65)
  static TextStyle callSummaryScorePercent() {
    return GoogleFonts.manrope(
      fontSize: 14,
      height: 22 / 14,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.14,
      color: Colors.black.withValues(alpha: 0.65),
    );
  }

  /// Arama özeti — skor altı sol «Başlangıç» (SemiBold 14 / 22, siyah %65)
  static TextStyle callSummaryScoreFootMuted() {
    return GoogleFonts.manrope(
      fontSize: 14,
      height: 22 / 14,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.14,
      color: Colors.black.withValues(alpha: 0.65),
    );
  }

  /// Arama özeti — skor altı sağ mor link (SemiBold 14 / 22)
  static TextStyle callSummaryScoreFootAccent() {
    return GoogleFonts.manrope(
      fontSize: 14,
      height: 22 / 14,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.14,
      color: AppColors.brandPrimary,
    );
  }

  /// Arama özeti — sonraki konu başlığı
  static TextStyle callSummaryNextTitle() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 22 / 16,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.16,
      color: Colors.black,
    );
  }

  /// Arama özeti — sonraki konu alt metni
  static TextStyle callSummaryNextSubtitle() {
    return GoogleFonts.manrope(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.14,
      color: AppColors.secondaryText,
    );
  }

  /// Paywall — ana başlık Bold 24 / 28, -1%, mor (#7429FF)
  static TextStyle paywallHeadline() {
    return GoogleFonts.manrope(
      fontSize: 24,
      height: 28 / 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.24,
      color: AppColors.brandPrimary,
    );
  }

  /// Paywall — alt başlık SemiBold 20 / 24, -1%, siyah
  static TextStyle paywallSubheadline() {
    return GoogleFonts.manrope(
      fontSize: 20,
      height: 24 / 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: const Color(0xFF000000),
    );
  }

  /// Paywall — özellik listesi Medium 16 / 24, secondary-text
  static TextStyle paywallFeatureLine() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.16,
      color: AppColors.secondaryText,
    );
  }

  /// Paywall — plan rozeti ExtraBold 20 / 24, mor
  static TextStyle paywallPlanHighlight() {
    return GoogleFonts.manrope(
      fontSize: 20,
      height: 24 / 20,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
      color: AppColors.brandPrimary,
    );
  }

  /// Paywall — plan fiyat satırı SemiBold 14 / 24, siyah
  static TextStyle paywallPlanPriceLine() {
    return GoogleFonts.manrope(
      fontSize: 14,
      height: 24 / 14,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.14,
      color: const Color(0xFF000000),
    );
  }

  /// Paywall — deneme etiketi / ödeme sol etiket SemiBold 16 / 24
  static TextStyle paywallRowEmphasis({required Color color}) {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.16,
      color: color,
    );
  }

  /// Paywall — özet kutusu vurgu (mor)
  static TextStyle paywallSheetAccentLine() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.16,
      color: AppColors.brandPrimary,
    );
  }

  /// Paywall — özet kutusu ikincil (gri tutar)
  static TextStyle paywallSheetMutedAmount() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.16,
      color: AppColors.secondaryText,
    );
  }

  /// Paywall — ödeme tarihi / tutar satırı SemiBold 16 / 24, siyah
  static TextStyle paywallPaymentBold() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.16,
      color: const Color(0xFF000000),
    );
  }

  /// Paywall — «Cancel anytime» mor link SemiBold 14 / 24
  static TextStyle paywallInlineLink() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 24 / 14,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.14,
      color: AppColors.brandPrimary,
    );
  }

  /// Paywall — «Continue without purchasing» Medium 16 / 24, secondary
  static TextStyle paywallDeferSecondary() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.16,
      color: AppColors.secondaryText,
    );
  }

  /// Anasayfa üst selamlama — Manrope Medium 16 / 20, secondary-text
  static TextStyle homeGreeting() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 20 / 16,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.4,
      color: AppColors.secondaryText,
    );
  }

  /// Anasayfa kullanıcı başlığı — Manrope Bold 24 / 30, siyah
  static TextStyle homeWelcomeTitle() {
    return GoogleFonts.manrope(
      fontSize: 24,
      height: 30 / 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      color: const Color(0xFF000000),
    );
  }

  /// Anasayfa seri kartı başlık — Manrope Bold 16 / 20, beyaz
  static TextStyle homeStreakTitle() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 20 / 16,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: Colors.white,
    );
  }

  /// Anasayfa seri kartı açıklama — Manrope Medium 14 / 22, beyaz %50
  static TextStyle homeStreakDescription() {
    return GoogleFonts.manrope(
      fontSize: 14,
      height: 22 / 14,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.14,
      color: Colors.white.withValues(alpha: 0.5),
    );
  }

  /// Anasayfa gün etiketi — Manrope SemiBold 12 / 16
  static TextStyle homeDayLabel({required Color color}) {
    return GoogleFonts.manrope(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.12,
      color: color,
    );
  }

  /// Anasayfa rozet metni — Manrope Bold 14 / 20, mor
  static TextStyle homeResumeBadge() {
    return GoogleFonts.manrope(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.14,
      color: AppColors.brandPrimary,
    );
  }

  /// Anasayfa ders sayacı — Manrope Bold 12 / 18, mor
  static TextStyle homeLessonProgress() {
    return GoogleFonts.manrope(
      fontSize: 12,
      height: 18 / 12,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.12,
      color: AppColors.brandPrimary,
    );
  }

  /// Anasayfa senaryo başlığı — Manrope Bold 24 / 30, siyah
  static TextStyle homeScenarioTitle() {
    return GoogleFonts.manrope(
      fontSize: 22,
      height: 30 / 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      color: const Color(0xFF000000),
    );
  }

  /// Anasayfa senaryo alt metni — Manrope SemiBold 16 / 20, secondary-text
  static TextStyle homeScenarioSubtitle() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 20 / 16,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: AppColors.secondaryText,
    );
  }

  /// Anasayfa bölüm başlığı — Manrope Bold 16 / 20, secondary-text
  static TextStyle homeSectionTitle() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 20 / 16,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.16,
      color: AppColors.secondaryText,
    );
  }

  /// Anasayfa bölüm aksiyonu — Manrope Bold 14 / 20, mor
  static TextStyle homeSectionAction() {
    return GoogleFonts.manrope(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.14,
      color: AppColors.brandPrimary,
    );
  }

  /// Karakter adı — Manrope Bold 20 / 24
  static TextStyle homeCharacterName() {
    return GoogleFonts.manrope(
      fontSize: 20,
      height: 24 / 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: Colors.black,
    );
  }

  /// Karakter meta satırı — Manrope Bold 12 / 18, secondary-text
  static TextStyle homeCharacterMeta() {
    return GoogleFonts.manrope(
      fontSize: 12,
      height: 18 / 12,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.12,
      color: AppColors.secondaryText,
    );
  }

  /// Karakter CTA — Manrope Bold 16 / 20, mor
  static TextStyle homeCharacterCta() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 20 / 16,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.16,
      color: AppColors.brandPrimary,
    );
  }

  /// Günlük konuşma başlığı — Manrope Bold 18 / 32
  static TextStyle homeConversationTitle() {
    return GoogleFonts.manrope(
      fontSize: 18,
      height: 32 / 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.18,
      color: Colors.black,
    );
  }

  /// Günlük konuşma alt metni — Manrope Bold 14 / 18, secondary-text
  static TextStyle homeConversationSubtitle() {
    return GoogleFonts.manrope(
      fontSize: 14,
      height: 18 / 14,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.14,
      color: AppColors.secondaryText,
    );
  }

  /// Günlük konuşma bilgi satırı — Manrope Bold 14 / 18
  static TextStyle homeConversationInfo({required Color color}) {
    return GoogleFonts.manrope(
      fontSize: 14,
      height: 18 / 14,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.14,
      color: color,
    );
  }

  /// Progress değer — Manrope Bold 26 / 36
  static TextStyle homeProgressValue({required Color color}) {
    return GoogleFonts.manrope(
      fontSize: 26,
      height: 36 / 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.26,
      color: color,
    );
  }

  /// Progress etiket — Manrope Bold 14 / 22, secondary-text
  static TextStyle homeProgressLabel() {
    return GoogleFonts.manrope(
      fontSize: 14,
      height: 22 / 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.28,
      color: AppColors.secondaryText,
    );
  }

  /// Alt navigasyon etiketi — Manrope SemiBold 14 / 20, -1%
  static TextStyle bottomNavLabel({required Color color}) {
    return GoogleFonts.manrope(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.14,
      color: color,
    );
  }

  /// Kayıt — başlık SemiBold 28 / 36, -1%, siyah
  static TextStyle signUpHeadline() {
    return GoogleFonts.manrope(
      fontSize: 28,
      height: 36 / 28,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.28,
      color: const Color(0xFF000000),
    );
  }

  /// Kayıt — sosyal düğme etiketi Medium 16 / 20, -1%, siyah
  static TextStyle signUpSocialLabel() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 20 / 16,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.16,
      color: const Color(0xFF000000),
    );
  }

  /// Kayıt — Apple düğmesi üzerinde beyaz etiket
  static TextStyle signUpSocialLabelOnDark() {
    return signUpSocialLabel().copyWith(color: Colors.white);
  }

  /// Kayıt — misafir bağlantısı SemiBold 16 / 20, -1%, siyah
  static TextStyle signUpGuestLink() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 20 / 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.16,
      color: const Color(0xFF000000),
    );
  }

  /// Kayıt — yasal dipnot gövdesi Medium 12 / 14, -1%, siyah
  static TextStyle signUpLegalBody() {
    return GoogleFonts.manrope(
      fontSize: 12,
      height: 14 / 12,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.12,
      color: const Color(0xFF000000),
    );
  }

  /// Kayıt — yasal dipnot vurgulu / altı çizili link Bold 12 / 14
  static TextStyle signUpLegalLink() {
    return GoogleFonts.manrope(
      fontSize: 12,
      height: 14 / 12,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.12,
      color: const Color(0xFF000000),
      decoration: TextDecoration.underline,
      decorationColor: Color(0xFF000000),
    );
  }

  /// Eğitmen seç — alt açıklama (Figma: Manrope Medium 16 / 20, -1%, secondary-text)
  static TextStyle tudorSelectSubtitle() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 20 / 16,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.16,
      color: AppColors.secondaryText,
    );
  }

  /// Eğitmen arama alanı / placeholder (Figma: Medium 16 / 20, -2.5%, secondary-text)
  static TextStyle tudorSearchField() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 20 / 16,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.4,
      color: AppColors.secondaryText,
    );
  }

  /// Karakter profili — AppBar başlık (Figma: Bold 20 / 28, #171717)
  static TextStyle tutorProfileScreenTitle() {
    return GoogleFonts.manrope(
      fontSize: 20,
      height: 28 / 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: const Color(0xFF171717),
    );
  }

  /// Karakter profili — isim (Figma: Bold 26 / 28, siyah)
  static TextStyle tutorProfileName() {
    return GoogleFonts.manrope(
      fontSize: 26,
      height: 28 / 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.26,
      color: const Color(0xFF000000),
    );
  }

  /// Karakter profili — biyografi (Figma: Medium 16 / 22, -1%, secondary-text)
  static TextStyle tutorProfileBio() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 22 / 16,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.16,
      color: AppColors.secondaryText,
    );
  }

  /// Karakter profili — sesli/görüntülü düğme etiketi (Figma: Bold 18 / 18, -2.5%)
  static TextStyle tutorProfileCallButtonLabel({required Color color}) {
    return GoogleFonts.manrope(
      fontSize: 18,
      height: 1.0,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.45,
      color: color,
    );
  }

  /// Karakter profili — metin mesajı (Figma: SemiBold 16 / 18, -2.5%, secondary-text)
  static TextStyle tutorProfileTextMessage() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 18 / 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
      color: AppColors.secondaryText,
    );
  }

  /// Bildirim kartı — başlık
  static TextStyle notificationCardTitle() {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 22 / 16,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.16,
      color: Colors.black,
    );
  }

  /// Bildirim kartı — açıklama
  static TextStyle notificationCardBody() {
    return GoogleFonts.manrope(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.14,
      color: AppColors.secondaryText,
    );
  }
}
