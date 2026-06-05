class ChatRouteArgs {
  const ChatRouteArgs({
    required this.tutorId,
    this.showHistoryShimmer = false,
  });

  final String tutorId;

  /// Geçmiş sohbet varsa yükleme sırasında shimmer göster (Talk geçmişi vb.).
  final bool showHistoryShimmer;

  static ChatRouteArgs parse(Object? raw) {
    if (raw is ChatRouteArgs) return raw;
    if (raw is String) {
      return ChatRouteArgs(tutorId: raw);
    }
    return const ChatRouteArgs(tutorId: 'sophie');
  }
}
