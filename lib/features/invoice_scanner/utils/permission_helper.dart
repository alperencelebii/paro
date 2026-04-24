import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

/// Helper class for handling permissions
class PermissionHelper {
  // Track ongoing permission requests to prevent concurrent requests
  static bool _isRequestingCamera = false;
  static bool _isRequestingStorage = false;

  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    // Prevent concurrent requests
    if (_isRequestingCamera) {
      // Wait a bit and check if permission is already granted
      await Future.delayed(const Duration(milliseconds: 500));
      if (await isCameraPermissionGranted()) {
        return true;
      }
      // If still requesting, wait for it to complete
      while (_isRequestingCamera) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      // Check again after waiting
      return await isCameraPermissionGranted();
    }

    try {
      _isRequestingCamera = true;
      final status = await Permission.camera.request();
      return status.isGranted;
    } finally {
      _isRequestingCamera = false;
    }
  }

  /// Request storage permission (for gallery access)
  /// On Android 13+ (API 33+), uses photos permission
  /// On older Android, uses storage permission
  /// On iOS, uses photos permission
  static Future<bool> requestStoragePermission() async {
    // Prevent concurrent requests
    if (_isRequestingStorage) {
      // Wait a bit and check if permission is already granted
      await Future.delayed(const Duration(milliseconds: 500));
      if (await isStoragePermissionGranted()) {
        return true;
      }
      // If still requesting, wait for it to complete
      while (_isRequestingStorage) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      // Check again after waiting
      return await isStoragePermissionGranted();
    }

    // Check if already granted
    if (await isStoragePermissionGranted()) {
      return true;
    }

    try {
      _isRequestingStorage = true;

      // On Android 13+ (API 33+), use photos permission
      // On iOS, use photos permission
      // On older Android, try storage permission
      if (Platform.isAndroid) {
        // Try photos permission first (Android 13+)
        final photosStatus = await Permission.photos.request();
        if (photosStatus.isGranted) return true;

        // If photos permission is permanently denied, try storage (older Android)
        if (photosStatus.isPermanentlyDenied) {
          // Try storage permission for older Android versions
          final storageStatus = await Permission.storage.request();
          if (storageStatus.isGranted) return true;
        }
      } else if (Platform.isIOS) {
        // iOS uses photos permission
        final photosStatus = await Permission.photos.request();
        if (photosStatus.isGranted) return true;
      }

      return false;
    } finally {
      _isRequestingStorage = false;
    }
  }

  /// Check if camera permission is granted
  static Future<bool> isCameraPermissionGranted() async {
    return await Permission.camera.isGranted;
  }

  /// Check if storage permission is granted
  /// Checks multiple permission types for compatibility
  static Future<bool> isStoragePermissionGranted() async {
    // Check photos permission (Android 13+ and iOS)
    if (await Permission.photos.isGranted) return true;

    // Check storage permission (older Android)
    if (Platform.isAndroid && await Permission.storage.isGranted) return true;

    return false;
  }

  /// Check if storage permission is permanently denied
  static Future<bool> isStoragePermissionPermanentlyDenied() async {
    final photosStatus = await Permission.photos.status;
    if (photosStatus.isPermanentlyDenied) return true;

    if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isPermanentlyDenied) return true;
    }

    return false;
  }

  /// Open app settings for permission
  static Future<bool> openAppSettings() async {
    // Use the top-level openAppSettings function from permission_handler
    return await openAppSettings();
  }

  /// Request all required permissions for scanner
  static Future<Map<String, bool>> requestAllPermissions() async {
    final cameraGranted = await requestCameraPermission();
    final storageGranted = await requestStoragePermission();

    return {'camera': cameraGranted, 'storage': storageGranted};
  }
}
