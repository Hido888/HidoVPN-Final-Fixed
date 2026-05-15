// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get login => 'Войти';

  @override
  String get username => 'Имя пользователя';

  @override
  String get password => 'Пароль';

  @override
  String get loginError => 'Ошибка входа. Проверьте данные.';

  @override
  String get logout => 'Выйти';

  @override
  String get connect => 'Подключить';

  @override
  String get connected => 'Подключено';

  @override
  String get connecting => 'Подключение...';

  @override
  String get disconnected => 'Отключено';

  @override
  String get servers => 'Серверы';

  @override
  String get profile => 'Профиль';

  @override
  String get settings => 'Настройки';

  @override
  String get theme => 'Тема';

  @override
  String get darkTheme => 'Тёмная';

  @override
  String get lightTheme => 'Светлая';

  @override
  String get systemTheme => 'Системная';

  @override
  String get language => 'Язык';

  @override
  String get subscription => 'Подписка';

  @override
  String get daysLeft => 'Дней осталось';

  @override
  String get dataUsage => 'Использование данных';

  @override
  String get downloadSpeed => 'Загрузка';

  @override
  String get uploadSpeed => 'Выгрузка';

  @override
  String get activeDevices => 'Активные устройства';

  @override
  String get fastestServer => 'Быстрый сервер';

  @override
  String get autoSelect => 'Авто выбор';

  @override
  String get limitExceeded => 'Лимит данных превышен';

  @override
  String get sessionExpired => 'Сессия истекла. Войдите снова.';

  @override
  String get unlimited => 'Безлимитный';

  @override
  String get speedTest => 'Тест скорости';
  @override
  String get speedTestStart => 'Начать тест скорости';
  @override
  String get speedTestRunning => 'Тест выполняется...';
  @override
  String get speedTestResult => 'Результат теста скорости';
  @override
  String get speedTestDownload => 'Загрузка';
  @override
  String get speedTestUpload => 'Выгрузка';
  @override
  String get speedTestPing => 'Задержка';
  @override
  String get speedTestMs => 'мс';
  @override
  String get speedTestMbps => 'Мбит/с';
  @override
  String get retry => 'Повторить';
}