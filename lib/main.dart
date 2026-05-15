import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hidovpn/flutter_gen/gen_l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/vpn_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_nav_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // SettingsProvider'ı uygulama başlamadan önce yükle
  final settingsProvider = SettingsProvider();
  await settingsProvider.initialize();

  // AuthProvider arka planda başlasın
  final authProvider = AuthProvider();
  authProvider.initialize();

  runApp(VpnApp(
    settingsProvider: settingsProvider,
    authProvider: authProvider,
  ));
}

class VpnApp extends StatelessWidget {
  final SettingsProvider settingsProvider;
  final AuthProvider authProvider;

  const VpnApp({
    super.key,
    required this.settingsProvider,
    required this.authProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<VpnProvider>(
          create: (ctx) {
            final vpn = VpnProvider();
            // FAZ 1 FIX: VPN logout callback'i AuthProvider'a kaydet
            // Logout yapıldığında VPN otomatik olarak kapanır
            WidgetsBinding.instance.addPostFrameCallback((_) {
              vpn.registerLogoutCallback(authProvider);
            });
            return vpn;
          },
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'HidoVPN',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            locale: settings.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('tr'),
              Locale('en'),
              Locale('ru'),
              Locale('tk'),
            ],
            home: const _AppRouter(),
          );
        },
      ),
    );
  }
}

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isInitialized) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_rounded, color: AppColors.primary, size: 64),
                  SizedBox(height: 24),
                  CircularProgressIndicator(color: AppColors.primary),
                ],
              ),
            ),
          );
        }
        if (auth.isLoggedIn) {
          return const MainNavScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
