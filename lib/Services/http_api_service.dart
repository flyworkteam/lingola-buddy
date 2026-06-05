import 'package:dio/dio.dart';
import 'package:lingola_buddy/Core/Config/api_config.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Utils/client_timezone.dart';
import 'package:lingola_buddy/Services/session_local_storage.dart';
import 'package:path/path.dart' as p;

class HttpApiService {
  HttpApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 12),
                sendTimeout: const Duration(seconds: 12),
              ),
            );

  final Dio _dio;

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    return _request(() async {
      final headers = await _headers(authenticated: authenticated);
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(headers: headers),
      );
      return _parseEnvelope(response.data);
    });
  }

  Future<Map<String, dynamic>> get(
    String path, {
    bool authenticated = true,
  }) async {
    return _request(() async {
      final headers = await _headers(authenticated: authenticated);
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        options: Options(headers: headers),
      );
      return _parseEnvelope(response.data);
    });
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    return _request(() async {
      final headers = await _headers(authenticated: authenticated);
      final response = await _dio.put<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(headers: headers),
      );
      return _parseEnvelope(response.data);
    });
  }

  Future<Map<String, dynamic>> uploadMultipart(
    String path, {
    required String filePath,
    required String fieldName,
    bool authenticated = true,
  }) async {
    return _request(() async {
      final headers = await _headers(authenticated: authenticated);
      headers.remove('Content-Type');

      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(
          filePath,
          filename: p.basename(filePath),
        ),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: formData,
        options: Options(
          headers: headers,
          contentType: 'multipart/form-data',
        ),
      );
      return _parseEnvelope(response.data);
    });
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    return _request(() async {
      final headers = await _headers(authenticated: authenticated);
      final response = await _dio.delete<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(headers: headers),
      );
      return _parseEnvelope(response.data);
    });
  }

  Future<T> _request<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException(_dioErrorMessage(e));
    }
  }

  String _dioErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final err = data['error'];
      if (err is String && err.isNotEmpty) return err;
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Request timed out';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Could not reach server';
    }
    return e.message ?? 'Request failed';
  }

  Future<Map<String, String>> _headers({required bool authenticated}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-Timezone-Offset': '${clientTimezoneOffsetMinutes()}',
      'X-UI-Language': AppTranslations.locale,
    };
    if (authenticated) {
      final token = await SessionLocalStorage.getAuthToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Map<String, dynamic> _parseEnvelope(Map<String, dynamic>? data) {
    if (data == null) {
      throw ApiException('Empty response');
    }
    final success = data['success'] == true;
    if (!success) {
      final err = data['error'];
      throw ApiException(err is String ? err : 'Request failed');
    }
    return data;
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
