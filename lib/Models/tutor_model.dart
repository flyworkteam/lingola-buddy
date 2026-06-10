import 'package:lingola_buddy/Core/Localization/app_translations.dart';

class TutorModel {
  const TutorModel({
    required this.id,
    required this.name,
    required this.description,
    required this.gender,
    required this.photoUrl,
    required this.rivUrl,
    required this.voiceId,
    required this.nativeLang,
    this.tagline,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String description;
  final String gender;
  final String photoUrl;
  final String rivUrl;
  final String voiceId;
  final String nativeLang;
  final String? tagline;
  final int sortOrder;

  /// Eski kod uyumu
  String? get bio => description;

  /// API locale metni; yoksa assets/tudor.{id} veya baş harfi büyük id.
  String get localizedDisplayName {
    if (name.trim().isNotEmpty) return name;
    return AppTranslations.trySection('tudor', id) ?? folderNameFromId(id);
  }

  String get localizedDescription {
    if (description.trim().isNotEmpty) return description;
    return AppTranslations.trySection('tudor', 'bio_fallback') ??
        'This tutor bio will be available soon.';
  }

  String get localizedTagline {
    final fromApi = tagline?.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    return '';
  }

  factory TutorModel.fromJson(Map<String, dynamic> json) {
    return TutorModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      gender: json['gender'] as String? ?? 'female',
      photoUrl: json['photoUrl'] as String? ?? '',
      rivUrl: json['rivUrl'] as String? ?? '',
      voiceId: json['voiceId'] as String? ?? '',
      nativeLang: json['nativeLang'] as String? ?? 'en',
      tagline: json['tagline'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  static const String _cdnBase = 'https://lingolabuddy.b-cdn.net/Buddies';

  static String cdnPhotoUrl(String folderName) =>
      '$_cdnBase/$folderName/$folderName.png';

  static String cdnRivUrl(String folderName) =>
      '$_cdnBase/$folderName/$folderName.riv';

  static String cdnPhotoUrlV2(String id) =>
      '$_cdnBase/${folderNameFromId(id)}/c_$id.png';

  static String cdnRivUrlV2(String id) =>
      '$_cdnBase/${folderNameFromId(id)}/c_$id.riv';

  /// API boş dönerse CDN yedeği; göreli URL'ye https ekler.
  String get resolvedRivUrl {
    final raw = rivUrl.trim();
    if (raw.isEmpty) return cdnRivUrlV2(id);
    final lower = raw.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) return raw;
    return 'https://$raw';
  }

  static String folderNameFromId(String id) {
    if (id.isEmpty) return id;
    return id[0].toUpperCase() + id.substring(1);
  }

}
