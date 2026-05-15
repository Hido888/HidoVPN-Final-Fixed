// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get login => 'Giriş Yap';

  @override
  String get username => 'Kullanıcı Adı';

  @override
  String get password => 'Şifre';

  @override
  String get loginError => 'Giriş başarısız. Bilgilerinizi kontrol edin.';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get connect => 'Bağlan';

  @override
  String get connected => 'Bağlandı';

  @override
  String get connecting => 'Bağlanıyor...';

  @override
  String get disconnected => 'Bağlantı Kesildi';

  @override
  String get servers => 'Sunucular';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Ayarlar';

  @override
  String get theme => 'Tema';

  @override
  String get darkTheme => 'Koyu';

  @override
  String get lightTheme => 'Açık';

  @override
  String get systemTheme => 'Sistem';

  @override
  String get language => 'Dil';

  @override
  String get subscription => 'Abonelik';

  @override
  String get daysLeft => 'Kalan Gün';

  @override
  String get dataUsage => 'Veri Kullanımı';

  @override
  String get downloadSpeed => 'İndirme';

  @override
  String get uploadSpeed => 'Yükleme';

  @override
  String get activeDevices => 'Aktif Cihazlar';

  @override
  String get fastestServer => 'En Hızlı Sunucu';

  @override
  String get autoSelect => 'Otomatik Seç';

  @override
  String get limitExceeded => 'Veri limiti aşıldı';

  @override
  String get sessionExpired =>
      'Oturum süresi doldu. Lütfen tekrar giriş yapın.';

  @override
  String get unlimited => 'Sınırsız';

  @override
  String get speedTest => 'Hız Testi';
  @override
  String get speedTestStart => 'Hız Testini Başlat';
  @override
  String get speedTestRunning => 'Test çalışıyor...';
  @override
  String get speedTestResult => 'Hız Testi Sonucu';
  @override
  String get speedTestDownload => 'İndirme';
  @override
  String get speedTestUpload => 'Yükleme';
  @override
  String get speedTestPing => 'Gecikme';
  @override
  String get speedTestMs => 'ms';
  @override
  String get speedTestMbps => 'Mbps';
  @override
  String get retry => 'Tekrar Dene';
}
