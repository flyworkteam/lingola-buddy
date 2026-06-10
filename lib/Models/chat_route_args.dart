class ChatRouteArgs {
  const ChatRouteArgs({
    required this.tutorId,
    this.showHistoryShimmer = false,
    this.lessonId,
  });

  final String tutorId;

  /// Geçmiş sohbet varsa yükleme sırasında shimmer göster (Talk geçmişi vb.).
  final bool showHistoryShimmer;

  /// Aktif ders veya günlük konuşma (`a1_01`, `dc_a1_01` vb.).
  final String? lessonId;

  static ChatRouteArgs parse(Object? raw) {
    if (raw is ChatRouteArgs) return raw;
    if (raw is String) {
      return ChatRouteArgs(tutorId: raw);
    }
    return const ChatRouteArgs(tutorId: 'sophie');
  }
}
