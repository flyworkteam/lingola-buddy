class TutorModel {
  const TutorModel({
    required this.id,
    required this.name,
    this.bio,
    this.avatarAssetPath,
    this.tagline,
  });

  final String id;
  final String name;
  final String? bio;
  final String? avatarAssetPath;
  final String? tagline;
}
