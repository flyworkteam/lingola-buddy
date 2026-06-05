import 'package:permission_handler/permission_handler.dart';

/// Sistem bildirim izni — Android 13+ ve iOS.
abstract final class NotificationPermissionService {
  NotificationPermissionService._();

  static Future<bool> isGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  static Future<bool> isPermanentlyDenied() async {
    final status = await Permission.notification.status;
    return status.isPermanentlyDenied;
  }

  /// İzin iste; verildiyse `true`.
  static Future<bool> request() async {
    var status = await Permission.notification.status;
    if (status.isGranted) return true;
    if (status.isDenied) {
      status = await Permission.notification.request();
    }
    return status.isGranted;
  }

  /// Kayıtlı tercih + sistem izni birlikte.
  static Future<bool> resolveEnabledPreference(bool storedPreference) async {
    if (!storedPreference) return false;
    return isGranted();
  }
}
