import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Models/tutor_model.dart';

/// Statik içerik; ileride repository + cache ile değiştirilebilir.
/// [TutorModel.id] değerleri `tr.json` içindeki `tudor` isim anahtarlarıyla eşleşir.
final tutorsCatalogProvider = Provider<List<TutorModel>>((ref) {
  return const [
    TutorModel(
      id: 'james',
      name: 'James',
      tagline: 'Telaffuz & ritim',
      bio:
          'Doğal telaffuz ve akıcı cümle kurma üzerine odaklanan, sabırlı bir pratik partneri.',
      avatarAssetPath: 'assets/images/avatar_1.png',
    ),
    TutorModel(
      id: 'sophie',
      name: 'Sophie',
      tagline: 'Kültürel yolculuk',
      bio:
          'Her mevsim dünyanın farklı bir köşesinden İngilizce öğreten Sophie, her dersi kültürel bir yolculuğa dönüştürür.',
      avatarAssetPath: 'assets/images/avatar_1.png',
    ),
    TutorModel(
      id: 'emma',
      name: 'Emma',
      tagline: 'İş İngilizcesi',
      bio: 'Toplantı ve sunumlarda güvenle konuşman için iş dünyası odaklı seanslar.',
      avatarAssetPath: 'assets/images/avatar_1.png',
    ),
    TutorModel(
      id: 'clara',
      name: 'Clara',
      tagline: 'Günlük diyalog',
      bio: 'Kafede, alışverişte ve seyahatte kullanacağın pratik ifadelerle konuşmayı kolaylaştırır.',
      avatarAssetPath: 'assets/images/avatar_1.png',
    ),
    TutorModel(
      id: 'jhon',
      name: 'Jhon',
      tagline: 'Telaffuz',
      bio: 'Zor sesleri adım adım çalışarak net ve anlaşılır konuşmana yardımcı olur.',
      avatarAssetPath: 'assets/images/avatar_1.png',
    ),
    TutorModel(
      id: 'seraphine',
      name: 'Seraphine',
      tagline: 'Akıcılık',
      bio: 'Duraksamadan konuşma ve düşünceyi ifade etme becerini geliştirmene odaklanır.',
      avatarAssetPath: 'assets/images/avatar_1.png',
    ),
    TutorModel(
      id: 'lin',
      name: 'Lin',
      tagline: 'Kelime haznesi',
      bio: 'Bağlam içinde yeni kelimeler öğrenerek kelime dağarcığını genişletmene yardım eder.',
      avatarAssetPath: 'assets/images/avatar_1.png',
    ),
    TutorModel(
      id: 'frank',
      name: 'Frank',
      tagline: 'Dinleme',
      bio: 'Farklı aksanlardan metinlerle dinleme pratiği ve not alma stratejileri sunar.',
      avatarAssetPath: 'assets/images/avatar_1.png',
    ),
    TutorModel(
      id: 'annie',
      name: 'Annie',
      tagline: 'Konuşma güveni',
      bio: 'Hata yapmaktan çekinmeden konuşma özgüvenini artırmak için destekleyici bir ortam sağlar.',
      avatarAssetPath: 'assets/images/avatar_1.png',
    ),
    TutorModel(
      id: 'lee',
      name: 'Lee',
      tagline: 'Dil bilgisi',
      bio: 'Kuralları konuşma içinde pekiştirerek doğal ve doğru cümle kurmana yardımcı olur.',
      avatarAssetPath: 'assets/images/avatar_1.png',
    ),
    TutorModel(
      id: 'nina',
      name: 'Nina',
      tagline: 'Hızlı pratik',
      bio: 'Kısa seanslarla yoğun tempoda tekrar ve geri bildirimle ilerlemen için idealdir.',
      avatarAssetPath: 'assets/images/avatar_1.png',
    ),
  ];
});
