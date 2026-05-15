import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_v2ray_plus/flutter_v2ray.dart';
import 'package:flutter_v2ray_plus/model/vless_status.dart';
import '../models/node_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

export 'package:flutter_v2ray_plus/model/vless_status.dart';

enum VpnState { disconnected, connecting, connected, disconnecting }

class VpnProvider extends ChangeNotifier {
  VpnState _state = VpnState.disconnected;
  NodeModel? _selectedNode;
  List<NodeModel> _nodes = [];
  bool _isLoadingNodes = false;
  String? _nodesError;
  Duration _connectionDuration = Duration.zero;
  String? _errorMessage;
  bool _limitExceeded = false;
  bool _sessionExpired = false;

  // Trafik istatistikleri
  int _totalBytesSent = 0;
  int _totalBytesReceived = 0;
  int _lastBytesSent = 0;
  int _lastBytesReceived = 0;

  // B3 FIX: Hız göstergesi - delta hesabı için
  double _downloadSpeedBps = 0;
  double _uploadSpeedBps = 0;
  int _prevBytesReceived = 0;
  int _prevBytesSent = 0;
  DateTime? _lastSpeedUpdate;

  // Otomatik seçim
  bool _autoSelectEnabled = true;

  // FAZ 2: Kill Switch
  bool _killSwitchEnabled = false;

  // FAZ 2: Auto-Reconnect
  bool _autoReconnectEnabled = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  Timer? _reconnectTimer;

  Timer? _timer;
  Timer? _heartbeatTimer;
  DateTime? _connectedAt;
  ApiService? _apiService;

  late final FlutterV2ray _v2ray;
  StreamSubscription? _statusSub;

  VpnState get state => _state;
  NodeModel? get selectedNode => _selectedNode;
  List<NodeModel> get nodes => _nodes;
  bool get isLoadingNodes => _isLoadingNodes;
  String? get nodesError => _nodesError;
  Duration get connectionDuration => _connectionDuration;
  bool get isConnected => _state == VpnState.connected;
  bool get isConnecting => _state == VpnState.connecting;
  String? get errorMessage => _errorMessage;
  bool get limitExceeded => _limitExceeded;
  bool get sessionExpired => _sessionExpired;
  double get downloadSpeedBps => _downloadSpeedBps;
  double get uploadSpeedBps => _uploadSpeedBps;
  bool get autoSelectEnabled => _autoSelectEnabled;
  bool get killSwitchEnabled => _killSwitchEnabled;
  bool get autoReconnectEnabled => _autoReconnectEnabled;

  String get downloadSpeedFormatted => _formatSpeed(_downloadSpeedBps);
  String get uploadSpeedFormatted => _formatSpeed(_uploadSpeedBps);

  String _formatSpeed(double bps) {
    if (bps <= 0) return '0 KB/s';
    if (bps < 1024 * 1024) {
      return '${(bps / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bps / (1024 * 1024)).toStringAsFixed(2)} MB/s';
  }

  VpnProvider() {
    _v2ray = FlutterV2ray();
    _initV2Ray();
  }

  /// FAZ 1 FIX: AuthProvider'a logout callback'i kaydet
  /// Bu sayede logout yapıldığında VPN otomatik kapanır
  void registerLogoutCallback(AuthProvider authProvider) {
    authProvider.setOnBeforeLogout(() async {
      if (_state == VpnState.connected || _state == VpnState.connecting) {
        await disconnect(notifyBackend: false);
      }
    });
  }

  Future<void> _initV2Ray() async {
    try {
      await _v2ray.initializeVless(
        notificationIconResourceType: 'mipmap',
        notificationIconResourceName: 'ic_launcher',
        providerBundleIdentifier: 'com.hidovpn.app.VPNProvider',
        groupIdentifier: 'group.com.hidovpn.app',
      );
      _statusSub = _v2ray.onStatusChanged.listen((status) {
        _handleStatusChange(status);
      });
    } catch (e) {
      debugPrint('V2Ray init error: $e');
    }
  }

  void _handleStatusChange(VlessStatus status) {
    switch (status.state) {
      case 'CONNECTED':
        _state = VpnState.connected;
        _connectedAt ??= DateTime.now();
        _errorMessage = null;
        _reconnectAttempts = 0; // Başarılı bağlantıda sıfırla
        _reconnectTimer?.cancel();

        // B3 FIX: Trafik verilerini oku
        _totalBytesSent = status.upload;
        _totalBytesReceived = status.download;

        // downloadSpeed/uploadSpeed sıfır gelirse manuel delta hesabı yap
        final rawDown = status.downloadSpeed.toDouble();
        final rawUp = status.uploadSpeed.toDouble();
        final now = DateTime.now();

        if (rawDown > 0 || rawUp > 0) {
          _downloadSpeedBps = rawDown;
          _uploadSpeedBps = rawUp;
        } else if (_lastSpeedUpdate != null) {
          final elapsed = now.difference(_lastSpeedUpdate!).inMilliseconds;
          if (elapsed > 0) {
            final downDelta =
                (_totalBytesReceived - _prevBytesReceived).toDouble();
            final upDelta = (_totalBytesSent - _prevBytesSent).toDouble();
            if (downDelta >= 0 && upDelta >= 0) {
              _downloadSpeedBps = (downDelta / elapsed) * 1000;
              _uploadSpeedBps = (upDelta / elapsed) * 1000;
            }
          }
        }

        _prevBytesReceived = _totalBytesReceived;
        _prevBytesSent = _totalBytesSent;
        _lastSpeedUpdate = now;

        if (_connectedAt != null) {
          _connectionDuration = now.difference(_connectedAt!);
        }
        _startHeartbeat();
        break;

      case 'CONNECTING':
        _state = VpnState.connecting;
        break;

      case 'DISCONNECTED':
        final wasConnected = _state == VpnState.connected;
        _state = VpnState.disconnected;
        _stopTimer();
        _stopHeartbeat();
        _connectedAt = null;
        _connectionDuration = Duration.zero;
        _downloadSpeedBps = 0;
        _uploadSpeedBps = 0;

        // FAZ 2: Auto-Reconnect - beklenmedik kopma durumunda yeniden bağlan
        if (wasConnected &&
            _autoReconnectEnabled &&
            !_limitExceeded &&
            !_sessionExpired &&
            _reconnectAttempts < _maxReconnectAttempts &&
            _apiService != null &&
            _selectedNode != null) {
          _scheduleReconnect();
        }
        break;

      case 'DISCONNECTING':
        _state = VpnState.disconnecting;
        break;
    }
    notifyListeners();
  }

  // FAZ 2: Otomatik yeniden bağlanma zamanlayıcısı
  void _scheduleReconnect() {
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 3); // 3s, 6s, 9s
    debugPrint('Auto-reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      if (_state == VpnState.disconnected &&
          _apiService != null &&
          _selectedNode != null) {
        _state = VpnState.connecting;
        _errorMessage = null;
        notifyListeners();
        try {
          final parser = FlutterV2ray.parseFromURL(_selectedNode!.url);
          final config = parser.getFullConfiguration();
          await _v2ray.startVless(
            remark: _selectedNode!.name,
            config: config,
            blockedApps: null,
            bypassSubnets: null,
            proxyOnly: false,
          );
        } catch (e) {
          _state = VpnState.disconnected;
          _errorMessage = 'Yeniden bağlanılamadı';
          notifyListeners();
        }
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // Heartbeat - 60 saniyede bir backend'e trafik bildir
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer =
        Timer.periodic(const Duration(seconds: 60), (_) async {
      if (_apiService == null || _state != VpnState.connected) return;

      final sentDelta = _totalBytesSent - _lastBytesSent;
      final receivedDelta = _totalBytesReceived - _lastBytesReceived;
      _lastBytesSent = _totalBytesSent;
      _lastBytesReceived = _totalBytesReceived;

      final result = await _apiService!.sendHeartbeat(
        bytesSent: sentDelta,
        bytesReceived: receivedDelta,
      );

      if (result['limit_exceeded'] == true) {
        _limitExceeded = true;
        _autoReconnectEnabled = false; // Limit aşıldıysa yeniden bağlanma
        notifyListeners();
        await disconnect();
        return;
      }

      if (result['session_expired'] == true) {
        _sessionExpired = true;
        _autoReconnectEnabled = false; // Oturum bittiyse yeniden bağlanma
        notifyListeners();
        await disconnect();
        return;
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> loadNodes(ApiService api) async {
    _apiService = api;
    _isLoadingNodes = true;
    _nodesError = null;
    notifyListeners();

    try {
      _nodes = await api.getNodes();
      if (_nodes.isNotEmpty && _selectedNode == null) {
        _selectedNode = _nodes.first;
      }
      _isLoadingNodes = false;
      notifyListeners();
      _pingAllNodes();
    } catch (e) {
      _nodesError = e.toString().replaceAll('Exception: ', '');
      _isLoadingNodes = false;
      notifyListeners();
    }
  }

  Future<void> _pingAllNodes() async {
    for (final node in _nodes) {
      node.isPinging = true;
      notifyListeners();
      try {
        final config =
            FlutterV2ray.parseFromURL(node.url).getFullConfiguration();
        final ping = await _v2ray.getServerDelay(config: config);
        node.pingMs = ping;
      } catch (_) {
        node.pingMs = -1;
      }
      node.isPinging = false;
      notifyListeners();
    }
    _autoSelectBestNode();
  }

  void _autoSelectBestNode() {
    if (_nodes.isEmpty || !_autoSelectEnabled) return;
    NodeModel? best;
    for (final node in _nodes) {
      final ping = node.pingMs;
      if (ping != null && ping > 0) {
        final bestPing = best?.pingMs;
        if (bestPing == null || ping < bestPing) {
          best = node;
        }
      }
    }
    if (best != null) {
      _selectedNode = best;
      notifyListeners();
    }
  }

  void toggleAutoSelect() {
    _autoSelectEnabled = !_autoSelectEnabled;
    if (_autoSelectEnabled) _autoSelectBestNode();
    notifyListeners();
  }

  void selectBestNode() {
    _autoSelectBestNode();
  }

  void selectNode(NodeModel node) {
    _autoSelectEnabled = false;
    _selectedNode = node;
    notifyListeners();
  }

  // FAZ 2: Kill Switch toggle
  void toggleKillSwitch() {
    _killSwitchEnabled = !_killSwitchEnabled;
    notifyListeners();
  }

  // FAZ 2: Auto-Reconnect toggle
  void toggleAutoReconnect() {
    _autoReconnectEnabled = !_autoReconnectEnabled;
    if (!_autoReconnectEnabled) {
      _reconnectTimer?.cancel();
    }
    notifyListeners();
  }

  Future<bool> connect(ApiService api) async {
    if (_selectedNode == null) {
      _errorMessage = 'Lütfen bir sunucu seçin';
      notifyListeners();
      return false;
    }
    if (_state != VpnState.disconnected) return false;

    _apiService = api;
    _state = VpnState.connecting;
    _errorMessage = null;
    _limitExceeded = false;
    _sessionExpired = false;
    _autoReconnectEnabled = true; // Yeni bağlantıda auto-reconnect aktif
    _reconnectAttempts = 0;
    notifyListeners();

    try {
      final parser = FlutterV2ray.parseFromURL(_selectedNode!.url);
      final config = parser.getFullConfiguration();

      final allowed = await _v2ray.requestPermission();
      if (!allowed) {
        _state = VpnState.disconnected;
        _errorMessage = 'VPN izni verilmedi';
        notifyListeners();
        return false;
      }

      await _v2ray.startVless(
        remark: _selectedNode!.name,
        config: config,
        blockedApps: null,
        bypassSubnets: null,
        proxyOnly: false,
      );

      await api.notifyConnect(_selectedNode!.url);
      return true;
    } catch (e) {
      _state = VpnState.disconnected;
      _errorMessage =
          'Bağlantı kurulamadı: ${e.toString().replaceAll('Exception: ', '')}';
      notifyListeners();
      debugPrint('VPN connect error: $e');
      return false;
    }
  }

  Future<void> disconnect({bool notifyBackend = true}) async {
    _reconnectTimer?.cancel(); // Auto-reconnect'i iptal et
    _reconnectAttempts = _maxReconnectAttempts; // Yeniden bağlanmayı engelle

    _state = VpnState.disconnecting;
    notifyListeners();

    if (notifyBackend && _apiService != null) {
      try {
        await _apiService!.notifyDisconnect(
          bytesSent: _totalBytesSent,
          bytesReceived: _totalBytesReceived,
        );
      } catch (e) {
        debugPrint('notifyDisconnect error: $e');
      }
    }

    try {
      await _v2ray.stopVless();
    } catch (e) {
      debugPrint('VPN disconnect error: $e');
    }

    _state = VpnState.disconnected;
    _stopTimer();
    _stopHeartbeat();
    _connectionDuration = Duration.zero;
    _connectedAt = null;
    _totalBytesSent = 0;
    _totalBytesReceived = 0;
    _lastBytesSent = 0;
    _lastBytesReceived = 0;
    _downloadSpeedBps = 0;
    _uploadSpeedBps = 0;
    notifyListeners();
  }

  void clearSessionExpired() {
    _sessionExpired = false;
    notifyListeners();
  }

  void clearLimitExceeded() {
    _limitExceeded = false;
    notifyListeners();
  }

  String get connectionTimeFormatted {
    final h = _connectionDuration.inHours.toString().padLeft(2, '0');
    final m =
        (_connectionDuration.inMinutes % 60).toString().padLeft(2, '0');
    final s =
        (_connectionDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }
}
