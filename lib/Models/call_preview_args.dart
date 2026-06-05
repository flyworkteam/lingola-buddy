/// Call preview ekranı bağlamı — onboarding (misafir) veya oturum açık (gerçek ders/eğitmen).
class CallPreviewArgs {
  const CallPreviewArgs.guest({this.tutorId})
      : isGuestPreview = true,
        lessonId = null;

  const CallPreviewArgs.session({
    required String tutorId,
    required String lessonId,
  })  : isGuestPreview = false,
        tutorId = tutorId,
        lessonId = lessonId;

  /// Giriş öncesi: rastgele veya verilen eğitmen, ders yok.
  final bool isGuestPreview;

  /// Misafir modda null ise ekranda katalogdan rastgele seçilir.
  final String? tutorId;
  final String? lessonId;
}
