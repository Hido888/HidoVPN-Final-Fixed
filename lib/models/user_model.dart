class UserModel {
  final int id;
  final String username;
  final String? fullName;
  final DateTime? subscriptionEnd;
  final int remainingDays;
  // GB bazlı alanlar (backend'den doğrudan gelir)
  final double dataLimitGb;   // -1 = sınırsız
  final double dataUsedGb;
  final int maxDevices;
  final int activeDevices;
  final bool isActive;
  final bool isBanned;
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.username,
    this.fullName,
    this.subscriptionEnd,
    this.remainingDays = 0,
    this.dataLimitGb = -1,
    this.dataUsedGb = 0.0,
    this.maxDevices = 5,
    this.activeDevices = 0,
    this.isActive = true,
    this.isBanned = false,
    this.isAdmin = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // data_limit_gb veya data_limit_bytes'dan GB hesapla
    double limitGb = -1;
    if (json['data_limit_gb'] != null) {
      limitGb = (json['data_limit_gb'] as num).toDouble();
    } else if (json['data_limit_bytes'] != null && json['data_limit_bytes'] != 0) {
      limitGb = (json['data_limit_bytes'] as num).toDouble() / (1024 * 1024 * 1024);
    }

    double usedGb = 0.0;
    if (json['data_used_gb'] != null) {
      usedGb = (json['data_used_gb'] as num).toDouble();
    } else if (json['data_used_bytes'] != null) {
      usedGb = (json['data_used_bytes'] as num).toDouble() / (1024 * 1024 * 1024);
    }

    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      fullName: json['full_name'],
      subscriptionEnd: json['subscription_end'] != null
          ? DateTime.tryParse(json['subscription_end'])
          : null,
      remainingDays: json['remaining_days'] ?? 0,
      dataLimitGb: limitGb,
      dataUsedGb: usedGb,
      maxDevices: json['max_devices'] ?? 5,
      activeDevices: json['active_devices'] ?? 0,
      isActive: json['is_active'] ?? true,
      isBanned: json['is_banned'] ?? false,
      isAdmin: json['is_admin'] ?? false,
    );
  }

  int get daysLeft {
    if (subscriptionEnd != null) {
      final diff = subscriptionEnd!.difference(DateTime.now());
      return diff.inDays < 0 ? 0 : diff.inDays;
    }
    return remainingDays;
  }

  bool get isUnlimited => dataLimitGb < 0;

  double get dataUsagePercent {
    if (isUnlimited || dataLimitGb == 0) return 0.0;
    return (dataUsedGb / dataLimitGb).clamp(0.0, 1.0);
  }

  bool get isSubscriptionExpired {
    if (subscriptionEnd == null) return remainingDays <= 0;
    return DateTime.now().isAfter(subscriptionEnd!);
  }

  bool get isDataLimitExceeded {
    if (isUnlimited) return false;
    return dataUsedGb >= dataLimitGb;
  }

  String get displayName =>
      fullName?.isNotEmpty == true ? fullName! : username;

  String get dataLimitText {
    if (isUnlimited) return '∞';
    return '${dataLimitGb.toStringAsFixed(1)} GB';
  }

  String get dataUsedText => '${dataUsedGb.toStringAsFixed(2)} GB';
}
