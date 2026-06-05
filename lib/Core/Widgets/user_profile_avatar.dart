import 'dart:io';

import 'package:flutter/material.dart';

/// Kullanıcı profil fotoğrafı — CDN URL, yerel dosya veya varsayılan ikon.
class UserProfileAvatar extends StatelessWidget {
  const UserProfileAvatar({
    super.key,
    this.imageUrl,
    this.size = 76,
    this.cover = false,
  });

  final String? imageUrl;
  final double size;

  /// `true` ise üst widget alanını doldurur (özet ekranı vb.).
  final bool cover;

  static bool _isNetworkUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final value = imageUrl?.trim();
    final image = _resolveImage(value);

    if (cover) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox.expand(child: image),
      );
    }

    return ClipOval(child: image);
  }

  Widget _resolveImage(String? value) {
    if (value != null && value.isNotEmpty) {
      if (_isNetworkUrl(value)) {
        return Image.network(
          value,
          width: cover ? double.infinity : size,
          height: cover ? double.infinity : size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              width: cover ? double.infinity : size,
              height: cover ? double.infinity : size,
              child: const Center(
                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
              ),
            );
          },
        );
      }
      if (File(value).existsSync()) {
        return Image.file(
          File(value),
          width: cover ? double.infinity : size,
          height: cover ? double.infinity : size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        );
      }
    }
    return _fallback();
  }

  Widget _fallback() {
    if (cover) {
      return ColoredBox(
        color: const Color(0xFFF6F6F6),
        child: Center(
          child: Icon(
            Icons.person_rounded,
            size: 48,
            color: const Color(0xFF96989C),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFF6F6F6),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.5,
        color: const Color(0xFF96989C),
      ),
    );
  }
}
