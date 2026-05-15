import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/node_model.dart';
import '../models/session_model.dart';

class ApiService {
  // Fallback URL listesi - biri engellenirse diğerine geçer
  static const List<String> _fallbackUrls = [
    'https://api.hidovpn.xyz',       // Cloudflare proxy (birincil)
    'http://94.183.159.227:8000',    // Direkt IP (yedek)
  ];

  static int _currentUrlIndex = 0;
  static const Duration timeout = Duration(seconds: 15);

  String? _token;
  String? _refreshToken;

  String get baseUrl => _fallbackUrls[_currentUrlIndex];

  void setToken(String token) => _token = token;
  void setRefreshToken(String token) => _refreshToken = token;
  void clearToken() {
    _token = null;
    _refreshToken = null;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // Cihaz ID'si - SharedPreferences'tan yüklenir (auth_provider'da set edilir)
  static String _deviceId = '';
  static String get deviceId => _deviceId.isNotEmpty ? _deviceId : 'android_${DateTime.now().millisecondsSinceEpoch}';
  static void setDeviceId(String id) => _deviceId = id;

  // Fallback: bir URL başarısız olunca diğerine geç
  Future<http.Response> _getWithFallback(String path) async {
    for (int i = 0; i < _fallbackUrls.length; i++) {
      final idx = (_currentUrlIndex + i) % _fallbackUrls.length;
      try {
        final response = await http
            .get(Uri.parse('${_fallbackUrls[idx]}$path'), headers: _headers)
            .timeout(timeout);
        if (response.statusCode != 503 && response.statusCode != 502) {
          _currentUrlIndex = idx;
          return response;
        }
      } catch (_) {
        continue;
      }
    }
    throw Exception('Tüm sunucular erişilemez durumda');
  }

  Future<http.Response> _postWithFallback(String path, Map<String, dynamic> body) async {
    for (int i = 0; i < _fallbackUrls.length; i++) {
      final idx = (_currentUrlIndex + i) % _fallbackUrls.length;
      try {
        final response = await http
            .post(
              Uri.parse('${_fallbackUrls[idx]}$path'),
              headers: _headers,
              body: jsonEncode(body),
            )
            .timeout(timeout);
        if (response.statusCode != 503 && response.statusCode != 502) {
          _currentUrlIndex = idx;
          return response;
        }
      } catch (_) {
        continue;
      }
    }
    throw Exception('Tüm sunucular erişilemez durumda');
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _postWithFallback('/api/v1/auth/login', {
      'username': username,
      'password': password,
      'device_id': deviceId,
      'device_name': 'Android Device',
      'device_platform': 'android',
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Giriş başarısız');
    }
  }

  Future<UserModel> getProfile() async {
    final response = await _getWithFallback('/api/v1/user/profile');

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) return getProfile();
      throw Exception('Oturum süresi doldu');
    } else {
      throw Exception('Profil alınamadı: ${response.statusCode}');
    }
  }

  // B4 FIX: Desteklenen protokoller - hysteria2 ve bilinmeyen protokoller filtrelenir
  static const List<String> _supportedProtocols = [
    'vless://',
    'vmess://',
    'trojan://',
    'ss://',
  ];

  bool _isSupportedProtocol(String url) {
    return _supportedProtocols.any((p) => url.startsWith(p));
  }

  Future<List<NodeModel>> getNodes() async {
    final response = await _getWithFallback('/api/v1/user/nodes');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> nodes = data['nodes'] ?? [];
      return nodes
          .map((n) => NodeModel.fromUrl(n is String ? n : n['url'] ?? ''))
          // B4 FIX: Desteklenmeyen protokolleri (hysteria2 vb.) filtrele
          .where((n) => n.url.isNotEmpty && _isSupportedProtocol(n.url))
          .toList();
    } else if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) return getNodes();
      throw Exception('Oturum süresi doldu');
    } else if (response.statusCode == 403) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erişim reddedildi');
    } else {
      throw Exception('Node listesi alınamadı: ${response.statusCode}');
    }
  }

  Future<bool> _tryRefreshToken() async {
    if (_refreshToken == null) return false;
    try {
      final response = await _postWithFallback('/api/v1/auth/refresh', {
        'refresh_token': _refreshToken,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access_token'];
        if (data['refresh_token'] != null) _refreshToken = data['refresh_token'];
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> logout() async {
    try {
      await _postWithFallback('/api/v1/auth/logout', {});
    } catch (_) {}
    clearToken();
  }

  // VPN bağlantısı başladığında backend'e bildir
  Future<void> notifyConnect(String nodeUrl) async {
    try {
      await _postWithFallback('/api/v1/user/connect', {
        'device_id': deviceId,
        'node_url': nodeUrl,
      });
    } catch (_) {}
  }

  // VPN bağlantısı kesildiğinde backend'e bildir
  Future<void> notifyDisconnect({int bytesSent = 0, int bytesReceived = 0}) async {
    try {
      await _postWithFallback('/api/v1/user/disconnect', {
        'device_id': deviceId,
        'bytes_sent': bytesSent,
        'bytes_received': bytesReceived,
      });
    } catch (_) {}
  }

  // Heartbeat - 60 saniyede bir çağrılır, trafik ve aktiviteyi günceller
  Future<Map<String, dynamic>> sendHeartbeat({
    int bytesSent = 0,
    int bytesReceived = 0,
  }) async {
    try {
      final response = await _postWithFallback('/api/v1/user/heartbeat', {
        'device_id': deviceId,
        'bytes_sent': bytesSent,
        'bytes_received': bytesReceived,
      });

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        // Token süresi dolmuş - kullanıcıyı çıkış yaptır
        return {'success': false, 'session_expired': true};
      }
    } catch (_) {}
    return {'success': false};
  }

  // Uygulama versiyonunu kontrol et - güncelleme var mı?
  Future<Map<String, dynamic>> checkAppVersion(String currentVersion) async {
    try {
      final response = await _getWithFallback('/api/v1/app/version');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {};
  }

  // Aktif oturumları listele
  Future<List<SessionModel>> getSessions() async {
    try {
      final response = await _getWithFallback('/api/v1/user/sessions');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> sessions = data['sessions'] ?? data ?? [];
        return sessions
            .map((s) => SessionModel.fromJson(s as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) return getSessions();
      }
    } catch (_) {}
    return [];
  }

  // Belirli bir oturumu sil
  Future<bool> deleteSession(int sessionId) async {
    try {
      final response = await _postWithFallback(
          '/api/v1/user/sessions/$sessionId/delete', {});
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  // Oturum durumunu kontrol et - başka cihazdan giriş yapıldı mı?
  Future<bool> checkSession() async {
    try {
      final response = await _getWithFallback('/api/v1/user/profile');
      if (response.statusCode == 401) return false; // Oturum sonlandırıldı
      if (response.statusCode == 200) return true;
    } catch (_) {}
    return true; // Ağ hatası - bağlantıyı kesmeden devam et
  }
}
