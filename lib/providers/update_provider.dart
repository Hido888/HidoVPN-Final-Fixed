import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_version_model.dart';
import '../services/api_service.dart';

class UpdateProvider extends ChangeNotifier {
  bool _hasUpdate = false;
  bool _isForceUpdate = false;
  AppVersionModel? _latestVersion;
  bool _dismissed = false;

  bool get hasUpdate => _hasUpdate && !_dismissed;
  bool get isForceUpdate => _isForceUpdate;
  AppVersionModel? get latestVersion => _latestVersion;

  Future<void> checkForUpdate(ApiService api) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersionCode = int.tryParse(info.buildNumber) ?? 4;

      final result = await api.checkAppVersion(currentVersionCode.toString());

      _hasUpdate = result['has_update'] ?? false;
      _isForceUpdate = result['is_force_update'] ?? false;

      if (_hasUpdate) {
        // BUG #4 FIX: API flat yapı döndürüyor (latest_version nested değil)
        // Önce nested 'latest_version' objesini dene, yoksa flat alanları kullan
        if (result['latest_version'] != null && result['latest_version'] is Map) {
          _latestVersion = AppVersionModel.fromJson(
              result['latest_version'] as Map<String, dynamic>);
        } else if (result['latest_version_name'] != null ||
            result['latest_version_code'] != null) {
          // Flat format: {has_update, latest_version_name, latest_version_code, download_url, ...}
          _latestVersion = AppVersionModel.fromJson({
            'id': result['id'] ?? 0,
            'version_name': result['latest_version_name'] ?? result['version_name'] ?? '',
            'version_code': result['latest_version_code'] ?? result['version_code'] ?? 0,
            'release_notes': result['release_notes'] ?? result['changelog'] ?? '',
            'is_force_update': _isForceUpdate,
            'download_url': result['download_url'] ?? result['apk_url'] ?? '',
            'apk_size_mb': result['apk_size_mb'] ?? 0,
          });
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Update check error: $e');
    }
  }

  void dismissUpdate() {
    if (!_isForceUpdate) {
      _dismissed = true;
      notifyListeners();
    }
  }
}
