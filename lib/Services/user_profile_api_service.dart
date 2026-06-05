import 'package:lingola_buddy/Models/user_model.dart';
import 'package:lingola_buddy/Services/http_api_service.dart';
import 'package:lingola_buddy/Services/lingola_auth_service.dart';

class UserProfileApiService {
  UserProfileApiService({HttpApiService? http}) {
    final client = http ?? HttpApiService();
    _http = client;
    _auth = LingolaAuthService(http: client);
  }

  late final HttpApiService _http;
  late final LingolaAuthService _auth;

  Future<UserModel> uploadProfilePhoto(String localFilePath) async {
    final envelope = await _http.uploadMultipart(
      '/auth/profile/photo',
      filePath: localFilePath,
      fieldName: 'photo',
    );
    return _userFromEnvelope(envelope);
  }

  Future<UserModel> removeProfilePhoto() async {
    final envelope = await _http.delete('/auth/profile/photo');
    return _userFromEnvelope(envelope);
  }

  Future<UserModel> updateUsername(String username) async {
    final envelope = await _http.put(
      '/auth/profile',
      body: {'username': username},
    );
    return _userFromEnvelope(envelope);
  }

  Future<UserModel> updateLearningProfile({
    required String cefrLevel,
    required String learnLanguageCode,
    required String nativeLanguageCode,
    required String dailyGoal,
  }) async {
    final envelope = await _http.put(
      '/auth/profile',
      body: {
        'proficiency': cefrLevel,
        'learnLanguageCode': learnLanguageCode,
        'nativeLang': nativeLanguageCode,
        'dailyGoal': dailyGoal,
      },
    );
    return _userFromEnvelope(envelope);
  }

  UserModel _userFromEnvelope(Map<String, dynamic> envelope) {
    final data = envelope['data'] as Map<String, dynamic>;
    final userJson = data['user'] as Map<String, dynamic>;
    return _auth.mapApiUser(userJson);
  }
}
