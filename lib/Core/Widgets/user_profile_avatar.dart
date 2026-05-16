import 'dart:io';

import 'package:flutter/material.dart';

/// Kullanıcı profil fotoğrafı — yerel dosya veya varsayılan asset.
class UserProfileAvatar extends StatelessWidget {
  const UserProfileAvatar({
    super.key,
    this.localPath,
    this.size = 76,
    this.defaultAsset = 'assets/images/avatar_1.png',
  });

  final String? localPath;
  final double size;
  final String defaultAsset;

  @override
  Widget build(BuildContext context) {
    final path = localPath;
    Widget image;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      image = Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    } else {
      image = Image.asset(
        defaultAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return ClipOval(child: image);
  }

  Widget _fallback() {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFF6F6F6),
      child: Icon(Icons.person, size: size * 0.5, color: const Color(0xFF96989C)),
    );
  }
}
