import 'package:flutter/material.dart';

class ProfileFaqView extends StatelessWidget {
  const ProfileFaqView({super.key});

  static const _items = <MapEntry<String, String>>[
    MapEntry('Lingola Buddy nedir?', 'Yapay zekâ destekli konuşma pratiği uygulamasıdır.'),
    MapEntry('Nasıl çalışır?', 'Tutorlarla görüşme/sohbet simülasyonları üzerinden pratik yaparsınız.'),
    MapEntry('Hangi diller desteklenir?', 'Dil kodları daha sonra localization ile yönetilecek.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sıkça sorulan sorular')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return ExpansionTile(
            title: Text(item.key),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                  child: Text(item.value),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
