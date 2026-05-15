// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get login => 'Login';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get loginError => 'Login failed. Please check your credentials.';

  @override
  String get logout => 'Logout';

  @override
  String get connect => 'Connect';

  @override
  String get connected => 'Connected';

  @override
  String get connecting => 'Connecting...';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get servers => 'Servers';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get darkTheme => 'Dark';

  @override
  String get lightTheme => 'Light';

  @override
  String get systemTheme => 'System';

  @override
  String get language => 'Language';

  @override
  String get subscription => 'Subscription';

  @override
  String get daysLeft => 'Days Left';

  @override
  String get dataUsage => 'Data Usage';

  @override
  String get downloadSpeed => 'Download';

  @override
  String get uploadSpeed => 'Upload';

  @override
  String get activeDevices => 'Active Devices';

  @override
  String get fastestServer => 'Fastest Server';

  @override
  String get autoSelect => 'Auto Select';

  @override
  String get limitExceeded => 'Data limit exceeded';

  @override
  String get sessionExpired => 'Session expired. Please login again.';

  @override
  String get unlimited => 'Unlimited';

  @override
  String get speedTest => 'Speed Test';
  @override
  String get speedTestStart => 'Start Speed Test';
  @override
  String get speedTestRunning => 'Test running...';
  @override
  String get speedTestResult => 'Speed Test Result';
  @override
  String get speedTestDownload => 'Download';
  @override
  String get speedTestUpload => 'Upload';
  @override
  String get speedTestPing => 'Ping';
  @override
  String get speedTestMs => 'ms';
  @override
  String get speedTestMbps => 'Mbps';
  @override
  String get retry => 'Retry';
}