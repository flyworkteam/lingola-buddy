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

  static String folderNameFromId(String id) {
    if (id.isEmpty) return id;
    return id[0].toUpperCase() + id.substring(1);
  }

  static const Set<String> _v2AssetTutorIds = {
    'aria',
    'brian',
    'elara',
    'lyra',
    'max',
    'mira',
  };

  /// API kapalıyken yerel yedek liste (CDN URL’leri ile).
  static List<TutorModel> fallbackCatalog() {
    const seeds = [
      (
        id: 'annie',
        tagline: 'Konuşma güveni',
        description:
            'Hata yapmaktan çekinmeden konuşma özgüvenini artırmak için destekleyici bir ortam sağlar.',
        gender: 'female',
        voiceId: 'fQmr8dTaOQq116mo2X7F',
        order: 1,
      ),
      (
        id: 'clara',
        tagline: 'Günlük diyalog',
        description:
            'Kafede, alışverişte ve seyahatte kullanacağın pratik ifadelerle konuşmayı kolaylaştırır.',
        gender: 'female',
        voiceId: 'bF7C2fCv7Zf30iT84wZ1',
        order: 2,
      ),
      (
        id: 'frank',
        tagline: 'Dinleme',
        description:
            'Farklı aksanlardan metinlerle dinleme pratiği ve not alma stratejileri sunar.',
        gender: 'male',
        voiceId: 'GSt1jGGmtMKKZ1jv5H4x',
        order: 3,
      ),
      (
        id: 'james',
        tagline: 'Telaffuz & ritim',
        description:
            'Doğal telaffuz ve akıcı cümle kurma üzerine odaklanan, sabırlı bir pratik partneri.',
        gender: 'male',
        voiceId: 'Q5n6GDIjpN0pLOlycRFT',
        order: 4,
      ),
      (
        id: 'jhon',
        tagline: 'Telaffuz',
        description:
            'Zor sesleri adım adım çalışarak net ve anlaşılır konuşmana yardımcı olur.',
        gender: 'male',
        voiceId: '7mBFv1btncDZu2Bfgv0r',
        order: 5,
      ),
      (
        id: 'lee',
        tagline: 'Dil bilgisi',
        description:
            'Kuralları konuşma içinde pekiştirerek doğal ve doğru cümle kurmana yardımcı olur.',
        gender: 'male',
        voiceId: 'Q5n6GDIjpN0pLOlycRFT',
        order: 6,
      ),
      (
        id: 'lin',
        tagline: 'Kelime haznesi',
        description:
            'Bağlam içinde yeni kelimeler öğrenerek kelime dağarcığını genişletmene yardım eder.',
        gender: 'female',
        voiceId: 'u0TsaWvt0v8migutHM3M',
        order: 7,
      ),
      (
        id: 'nina',
        tagline: 'Hızlı pratik',
        description:
            'Kısa seanslarla yoğun tempoda tekrar ve geri bildirimle ilerlemen için idealdir.',
        gender: 'female',
        voiceId: 'lfQ3pGxnwOiKjnQKdwts',
        order: 8,
      ),
      (
        id: 'seraphine',
        tagline: 'Akıcılık',
        description:
            'Duraksamadan konuşma ve düşünceyi ifade etme becerini geliştirmene odaklanır.',
        gender: 'female',
        voiceId: 'NsFK0aDGLbVusA7tQfOB',
        order: 9,
      ),
      (
        id: 'sophie',
        tagline: 'Kültürel yolculuk',
        description:
            'Her mevsim dünyanın farklı bir köşesinden İngilizce öğreten Sophie, her dersi kültürel bir yolculuğa dönüştürür.',
        gender: 'female',
        voiceId: 'LLz3hpCJoVCSPagm5OP1',
        order: 10,
      ),
      (
        id: 'aria',
        tagline: 'Günlük sohbet',
        description:
            'Günlük sohbetlerde kendini rahat ifade etmen için sıcak ve destekleyici bir pratik ortamı sunar.',
        gender: 'female',
        voiceId: 'jqcCZkN6Knx8BJ5TBdYR',
        order: 11,
      ),
      (
        id: 'brian',
        tagline: 'Dinleme',
        description:
            'Farklı aksan ve hızlarda dinleme pratiğiyle anlama becerini adım adım geliştirir.',
        gender: 'male',
        voiceId: 'mtrellq69YZsNwzUSyXh',
        order: 12,
      ),
      (
        id: 'elara',
        tagline: 'Kelime haznesi',
        description:
            'Bağlam içinde yeni kelimeler öğreterek kelime dağarcığını doğal şekilde genişletmene yardım eder.',
        gender: 'female',
        voiceId: 'FFmp1h1BMl0iVHA0JxrI',
        order: 13,
      ),
      (
        id: 'lyra',
        tagline: 'Akıcılık',
        description:
            'Duraksamadan konuşma ve düşünceni akıcı şekilde ifade etme becerine odaklanır.',
        gender: 'female',
        voiceId: 'UTPot3MZG8clNCH22nuw',
        order: 14,
      ),
      (
        id: 'max',
        tagline: 'Telaffuz & ritim',
        description:
            'Doğal telaffuz ve cümle ritmi üzerine odaklanan sabırlı bir pratik partneridir.',
        gender: 'male',
        voiceId: 'g4ucswVjPpazgbDDe327',
        order: 15,
      ),
      (
        id: 'mira',
        tagline: 'Hızlı pratik',
        description:
            'Kısa ve yoğun seanslarla hızlı tekrar ve geri bildirimle ilerlemeni destekler.',
        gender: 'female',
        voiceId: '9w21nMuk8CWXIME31V1S',
        order: 16,
      ),
    ];

    return [
      for (final s in seeds)
        TutorModel(
          id: s.id,
          name: folderNameFromId(s.id),
          description: s.description,
          gender: s.gender,
          photoUrl: _v2AssetTutorIds.contains(s.id)
              ? cdnPhotoUrlV2(s.id)
              : cdnPhotoUrl(folderNameFromId(s.id)),
          rivUrl: _v2AssetTutorIds.contains(s.id)
              ? cdnRivUrlV2(s.id)
              : cdnRivUrl(folderNameFromId(s.id)),
          voiceId: s.voiceId,
          nativeLang: 'en',
          tagline: s.tagline,
          sortOrder: s.order,
        ),
    ];
  }
}
