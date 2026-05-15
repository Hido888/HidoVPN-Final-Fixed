import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

/// Token'ları güvenli şekilde saklamak için flutter_secure_storage kullanılır.
/// SharedPreferences düz metin olarak saklar; secure_storage şifreli keystore/keychain kullanır.
class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Logout öncesi VPN'i kapatmak için callback (bağımlılık döngüsü olmadan)
  Future<void> Function()? _onBeforeLogout;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _token != null && _user != null;
  bool get isInitialized => _isInitialized;

  /// VPN Provider tarafından kaydedilir. Logout öncesi VPN'i kapatır.
  void setOnBeforeLogout(Future<void> Function()? callback) {
    _onBeforeLogout = callback;
  }

  Future<void> initialize() async {
    // device_id yönetimi SharedPreferences'ta kalabilir (hassas değil)
    final prefs = await SharedPreferences.getInstance();
    String? savedDeviceId = prefs.getString('device_id');
    if (savedDeviceId == null) {
      savedDeviceId = 'android_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('device_id', savedDeviceId);
    }
    ApiService.setDeviceId(savedDeviceId);

    // Token'ları güvenli depodan oku
    final savedToken = await _storage.read(key: 'auth_token');
    final savedRefresh = await _storage.read(key: 'refresh_token');

    if (savedToken != null) {
      _token = savedToken;
      _api.setToken(savedToken);
      if (savedRefresh != null) {
        _api.setRefreshToken(savedRefresh);
      }
      try {
        _user = await _api.getProfile();
      } catch (_) {
        // Token geçersiz veya süresi dolmuş — temizle
        _token = null;
        _api.clearToken();
        await _storage.delete(key: 'auth_token');
        await _storage.delete(key: 'refresh_token');
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.login(username, password);
      _token = data['access_token'];
      final refreshToken = data['refresh_token'];

      _api.setToken(_token!);
      if (refreshToken != null) {
        _api.setRefreshToken(refreshToken);
      }

      _user = await _api.getProfile();

      // Güvenli depoya yaz
      await _storage.write(key: 'auth_token', value: _token!);
      if (refreshToken != null) {
        await _storage.write(key: 'refresh_token', value: refreshToken);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _localizeError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshProfile() async {
    try {
      _user = await _api.getProfile();
      notifyListeners();
    } catch (_) {}
  }

  /// Logout: VPN'i kapat, token'ları güvenli depodan sil
  Future<void> logout() async {
    if (_onBeforeLogout != null) {
      try {
        await _onBeforeLogout!();
      } catch (e) {
        debugPrint('VPN disconnect on logout error: $e');
      }
    }

    try {
      await _api.logout();
    } catch (_) {}

    _token = null;
    _user = null;

    // Güvenli depodan sil
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'refresh_token');

    notifyListeners();
  }

  /// İngilizce API hatalarını Türkçe'ye çevir
  String _localizeError(String raw) {
    final msg = raw.replaceAll('Exception: ', '').toLowerCase();
    if (msg.contains('invalid') || msg.contains('wrong') || msg.contains('incorrect')) {
      return 'Kullanıcı adı veya şifre hatalı';
    }
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return 'Bağlantı zaman aşımına uğradı. Tekrar deneyin.';
    }
    if (msg.contains('connection refused') || msg.contains('refused')) {
      return 'Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin.';
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Ağ hatası. İnternet bağlantınızı kontrol edin.';
    }
    if (msg.contains('banned') || msg.contains('suspended')) {
      return 'Hesabınız askıya alınmış. Destek ile iletişime geçin.';
    }
    if (msg.contains('not found') || msg.contains('404')) {
      return 'Kullanıcı bulunamadı';
    }
    if (msg.contains('500') || msg.contains('server error')) {
      return 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
    }
    return raw.replaceAll('Exception: ', '');
  }

  ApiService get api => _api;
}
