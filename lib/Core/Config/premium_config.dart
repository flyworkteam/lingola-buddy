/// Ücretsiz görüşme kotası ve premium kuralları (RevenueCat istemci tarafı).
///
/// - Entitlement doğrulaması yalnızca RevenueCat SDK ile yapılır; webhook / API yok.
/// - Kota yalnızca **görüntülü görüşme** için geçerlidir; metin sohbeti kotasızdır.
abstract final class PremiumConfig {
  PremiumConfig._();

  /// Ücretsiz kullanıcıların tamamlayabileceği görüntülü görüşme sayısı.
  static const int freeCallsTotal = 3;

  /// Kotaya sayılması için minimum görüntülü görüşme süresi (saniye).
  static const int minDurationToCountSeconds = 30;

  /// Metin sohbeti premium / kota kontrolünden muaftır.
  static const bool textChatRequiresPremium = false;
}
