class SessionModel {
  final int id;
  final String deviceId;
  final String deviceName;
  final String devicePlatform;
  final bool isConnected;
  final String connectedAt;
  final String lastActivity;

  SessionModel({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.devicePlatform,
    required this.isConnected,
    required this.connectedAt,
    required this.lastActivity,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] ?? 0,
      deviceId: json['device_id'] ?? '',
      deviceName: json['device_name'] ?? 'Bilinmeyen Cihaz',
      devicePlatform: json['device_platform'] ?? 'android',
      isConnected: json['is_connected'] ?? false,
      connectedAt: json['connected_at'] ?? '',
      lastActivity: json['last_activity'] ?? '',
    );
  }

  String get platformIcon {
    switch (devicePlatform.toLowerCase()) {
      case 'android':
        return '🤖';
      case 'ios':
        return '🍎';
      case 'windows':
        return '🖥️';
      case 'macos':
        return '💻';
      default:
        return '📱';
    }
  }

  String get formattedLastActivity {
    try {
      final dt = DateTime.parse(lastActivity).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return lastActivity;
    }
  }
}
