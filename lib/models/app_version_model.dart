class AppVersionModel {
  final int id;
  final String versionName;
  final int versionCode;
  final String releaseNotes;
  final bool isForceUpdate;
  final String downloadUrl;
  final double apkSizeMb;

  AppVersionModel({
    required this.id,
    required this.versionName,
    required this.versionCode,
    required this.releaseNotes,
    required this.isForceUpdate,
    required this.downloadUrl,
    required this.apkSizeMb,
  });

  factory AppVersionModel.fromJson(Map<String, dynamic> json) {
    return AppVersionModel(
      id: json['id'] ?? 0,
      versionName: json['version_name'] ?? '',
      versionCode: json['version_code'] ?? 0,
      releaseNotes: json['release_notes'] ?? '',
      isForceUpdate: json['is_force_update'] ?? false,
      downloadUrl: json['download_url'] ?? '',
      apkSizeMb: (json['apk_size_mb'] ?? 0).toDouble(),
    );
  }
}
