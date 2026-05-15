/// Sunucu node modeli.
/// Desteklenen protokoller: VLESS, VMess, Shadowsocks, Trojan.
/// Hysteria2: URL tanıma yapılır ancak flutter_v2ray_plus paketi
/// Hysteria2'yi desteklemediğinden bu protokol filtrelenir ve kullanıcıya
/// bilgi notu gösterilir.
class NodeModel {
  final String name;
  final String url;
  int? pingMs;
  bool isPinging;

  NodeModel({
    required this.name,
    required this.url,
    this.pingMs,
    this.isPinging = false,
  });

  factory NodeModel.fromUrl(String rawUrl) {
    String name = 'Node';
    final uri = Uri.tryParse(rawUrl);
    if (uri != null) {
      final fragment = uri.fragment;
      if (fragment.isNotEmpty) {
        name = Uri.decodeComponent(fragment);
      } else if (uri.host.isNotEmpty) {
        name = uri.host;
      }
    }
    return NodeModel(name: name, url: rawUrl);
  }

  String get pingText {
    if (isPinging) return '...';
    if (pingMs == null) return '-';
    if (pingMs! < 0) return 'Timeout';
    return '${pingMs}ms';
  }

  PingQuality get pingQuality {
    if (pingMs == null || pingMs! < 0) return PingQuality.unknown;
    if (pingMs! < 150) return PingQuality.good;
    if (pingMs! < 500) return PingQuality.medium;
    return PingQuality.bad;
  }

  /// Protokol adını döndürür.
  /// Hysteria2 URL'leri tanınır ama desteklenmez olarak işaretlenir.
  String get protocol {
    if (url.startsWith('vless://')) return 'VLESS';
    if (url.startsWith('vmess://')) return 'VMess';
    if (url.startsWith('ss://')) return 'SS';
    if (url.startsWith('trojan://')) return 'Trojan';
    // Hysteria2 URL şemaları: hy2:// veya hysteria2://
    if (url.startsWith('hy2://') || url.startsWith('hysteria2://')) {
      return 'Hysteria2';
    }
    // Hysteria v1
    if (url.startsWith('hysteria://')) return 'Hysteria';
    return 'Unknown';
  }

  /// flutter_v2ray_plus tarafından desteklenen protokol mü?
  /// Hysteria/Hysteria2 şu an desteklenmiyor — paket Xray core kullanıyor,
  /// Hysteria için ayrı bir native implementasyon gerekiyor.
  bool get isSupported {
    switch (protocol) {
      case 'VLESS':
      case 'VMess':
      case 'SS':
      case 'Trojan':
        return true;
      default:
        return false;
    }
  }

  /// Protokol rengi (UI badge için)
  static const Map<String, int> protocolColors = {
    'VLESS': 0xFF4FC3F7,   // Açık mavi
    'VMess': 0xFF81C784,   // Yeşil
    'SS': 0xFFFFB74D,      // Turuncu
    'Trojan': 0xFFBA68C8,  // Mor
    'Hysteria2': 0xFFFF7043, // Kırmızı-turuncu (desteklenmiyor)
    'Hysteria': 0xFFFF7043,
    'Unknown': 0xFF9E9E9E,
  };
}

enum PingQuality { good, medium, bad, unknown }
