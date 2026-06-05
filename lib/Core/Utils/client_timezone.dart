/// Sunucuya gönderilen saat dilimi ofseti (dakika).
/// JavaScript `Date.getTimezoneOffset()` ile uyumlu.
int clientTimezoneOffsetMinutes() {
  return -DateTime.now().timeZoneOffset.inMinutes;
}
