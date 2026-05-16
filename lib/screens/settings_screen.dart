import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hidovpn/flutter_gen/gen_l10n/app_localizations.dart';
import '../models/session_model.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/vpn_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<SessionModel> _sessions = [];
  bool _sessionsLoading = true;
  int? _deletingId;
  bool _refreshing = false;
  String _appVersion = '...';

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = 'v${packageInfo.version} (${packageInfo.buildNumber})';
      });
    }
  }

  Future<void> _loadSessions({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() => _refreshing = true);
    } else {
      setState(() => _sessionsLoading = true);
    }

    try {
      final auth = context.read<AuthProvider>();
      final sessions = await auth.api.getSessions();
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _sessionsLoading = false;
          _refreshing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _sessions = [];
          _sessionsLoading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _deleteSession(SessionModel session) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.removeDevice,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          l.removeDeviceConfirm(session.deviceName),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l.ok),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deletingId = session.id);
    try {
      final auth = context.read<AuthProvider>();
      await auth.api.deleteSession(session.id);
      await _loadSessions(isRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.deviceRemoved(session.deviceName)),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final cardBorderColor =
        isDark ? AppColors.cardBorder : AppColors.lightCardBorder;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.settings,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary))
                : const Icon(Icons.refresh_rounded),
            onPressed: () {
              context.read<AuthProvider>().refreshProfile();
              _loadSessions(isRefresh: true);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          context.read<AuthProvider>().refreshProfile();
          await _loadSessions(isRefresh: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAccountCard(context, cardColor, cardBorderColor,
                  textPrimary, textSecondary),
              const SizedBox(height: 16),
              _buildStatsRow(context, cardColor, cardBorderColor, textSecondary),
              const SizedBox(height: 20),
              _buildDevicesSection(context, cardColor, cardBorderColor,
                  textPrimary, textSecondary),
              const SizedBox(height: 20),
              // FAZ 2: VPN Güvenlik Ayarları
              _buildVpnSecuritySection(context, cardColor, cardBorderColor,
                  textPrimary, textSecondary),
              const SizedBox(height: 20),
              _buildAppearanceSection(context, cardColor, cardBorderColor,
                  textPrimary, textSecondary),
              const SizedBox(height: 20),
              _buildAppInfoCard(context, cardColor, cardBorderColor, textSecondary),
              const SizedBox(height: 20),
              _buildLogoutButton(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, Color cardColor,
      Color cardBorderColor, Color textPrimary, Color textSecondary) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    (user?.username ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.username ?? 'Yükleniyor...',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: user != null && !user.isSubscriptionExpired
                            ? AppColors.primary.withOpacity(0.15)
                            : Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user != null && !user.isSubscriptionExpired
                            ? l.activeSubscription
                            : l.subscriptionExpired,
                        style: TextStyle(
                          color: user != null && !user.isSubscriptionExpired
                              ? AppColors.primary
                              : Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildStatsRow(BuildContext context, Color cardColor,
      Color cardBorderColor, Color textSecondary) {
    final l = AppLocalizations.of(context)!;
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        return Row(
          children: [
            _statTile(
              cardColor: cardColor,
              cardBorderColor: cardBorderColor,
              textSecondary: textSecondary,
              icon: Icons.calendar_today_rounded,
              iconColor: AppColors.primary,
              value: '${user?.daysLeft ?? 0}',
              label: l.daysLeft,
            ),
            const SizedBox(width: 10),
            _statTile(
              cardColor: cardColor,
              cardBorderColor: cardBorderColor,
              textSecondary: textSecondary,
              icon: Icons.devices_rounded,
              iconColor: Colors.blue,
              value: '${user?.activeDevices ?? 0}/${user?.maxDevices ?? 0}',
              label: l.activeDevices,
            ),
            const SizedBox(width: 10),
            _statTile(
              cardColor: cardColor,
              cardBorderColor: cardBorderColor,
              textSecondary: textSecondary,
              icon: Icons.event_rounded,
              iconColor: Colors.orange,
              value: user?.subscriptionEnd != null
                  ? '${user!.subscriptionEnd!.day.toString().padLeft(2, '0')}.${user.subscriptionEnd!.month.toString().padLeft(2, '0')}'
                  : '--',
              label: l.subscriptionEnd,
            ),
          ],
        );
      },
    );
  }

  Widget _statTile({
    required Color cardColor,
    required Color cardBorderColor,
    required Color textSecondary,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesSection(BuildContext context, Color cardColor,
      Color cardBorderColor, Color textPrimary, Color textSecondary) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.connectedDevices,
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorderColor),
          ),
          child: _sessionsLoading
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              : _sessions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          l.noActiveDevices,
                          style: TextStyle(color: textSecondary),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _sessions.length,
                      separatorBuilder: (_, __) => Divider(
                        color: cardBorderColor,
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final session = _sessions[index];
                        final isDeleting = _deletingId == session.id;
                        return ListTile(
                          leading: Text(
                            session.platformIcon,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            session.deviceName,
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Son görülme: ${session.formattedLastActivity}',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          trailing: isDeleting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.red,
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: Colors.red, size: 20),
                                  onPressed: () => _deleteSession(session),
                                ),
                        );
                      },
                    ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms);
  }

  /// FAZ 2: Kill Switch ve Auto-Reconnect ayarları
  Widget _buildVpnSecuritySection(BuildContext context, Color cardColor,
      Color cardBorderColor, Color textPrimary, Color textSecondary) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.vpnSecurity,
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Consumer<VpnProvider>(
          builder: (context, vpn, _) {
            return Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorderColor),
              ),
              child: Column(
                children: [
                  // Kill Switch - Gerçek bilgi notu
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      l.killSwitch,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.killSwitchDesc,
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Text(
                            'Yakında — Sistem seviyesi güncelleme gerektirir',
                            style: const TextStyle(color: Colors.orange, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.lock_clock_outlined, color: Colors.orange, size: 20),
                    isThreeLine: true,
                  ),
                  Divider(color: cardBorderColor, height: 1, indent: 16, endIndent: 16),
                  // Auto-Reconnect
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: vpn.autoReconnectEnabled
                            ? AppColors.accent.withOpacity(0.15)
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.autorenew_rounded,
                        color: vpn.autoReconnectEnabled
                            ? AppColors.accent
                            : AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      l.autoReconnect,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      l.autoReconnectDesc,
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                    trailing: Switch(
                      value: vpn.autoReconnectEnabled,
                      onChanged: (_) => vpn.toggleAutoReconnect(),
                      activeColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 150.ms);
  }

  Widget _buildAppearanceSection(BuildContext context, Color cardColor,
      Color cardBorderColor, Color textPrimary, Color textSecondary) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.appearance,
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorderColor),
              ),
              child: Column(
                children: [
                  // Tema
                  ListTile(
                    leading: const Icon(Icons.palette_rounded,
                        color: AppColors.primary),
                    title: Text(l.theme,
                        style: TextStyle(
                            color: textPrimary, fontWeight: FontWeight.w500)),
                    trailing: DropdownButton<ThemeMode>(
                      value: settings.themeMode,
                      dropdownColor: AppColors.card,
                      underline: const SizedBox(),
                      style: TextStyle(color: textPrimary),
                      items: [
                        DropdownMenuItem(
                            value: ThemeMode.system, child: Text(l.systemTheme)),
                        DropdownMenuItem(
                            value: ThemeMode.dark, child: Text(l.darkTheme)),
                        DropdownMenuItem(
                            value: ThemeMode.light, child: Text(l.lightTheme)),
                      ],
                      onChanged: (mode) {
                        if (mode != null) settings.setThemeMode(mode);
                      },
                    ),
                  ),
                  Divider(color: cardBorderColor, height: 1, indent: 16, endIndent: 16),
                  // Dil
                  ListTile(
                    leading: const Icon(Icons.language_rounded,
                        color: AppColors.accent),
                    title: Text(l.language,
                        style: TextStyle(
                            color: textPrimary, fontWeight: FontWeight.w500)),
                    trailing: DropdownButton<String>(
                      value: settings.locale.languageCode,
                      dropdownColor: AppColors.card,
                      underline: const SizedBox(),
                      style: TextStyle(color: textPrimary),
                      items: const [
                        DropdownMenuItem(value: 'tr', child: Text('🇹🇷 Türkçe')),
                        DropdownMenuItem(value: 'en', child: Text('🇬🇧 English')),
                        DropdownMenuItem(value: 'ru', child: Text('🇷🇺 Русский')),
                        DropdownMenuItem(value: 'tk', child: Text('🇹🇲 Türkmençe')),
                      ],
                      onChanged: (lang) {
                        if (lang != null) settings.setLocale(Locale(lang));
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }

  Widget _buildAppInfoCard(BuildContext context, Color cardColor,
      Color cardBorderColor, Color textSecondary) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.appInfo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _infoRow(Icons.info_outline_rounded, l.version, _appVersion, textSecondary),
          const SizedBox(height: 6),
          _infoRow(Icons.security_rounded, l.protocolLabel, 'VLESS / VMess / Trojan', textSecondary),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms);
  }

  Widget _infoRow(IconData icon, String label, String value, Color textSecondary) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final l = AppLocalizations.of(context)!;
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(l.logout,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              content: Text(
                l.logoutConfirm,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l.cancel,
                      style: const TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(l.logout),
                ),
              ],
            ),
          );

          // FAZ 1 FIX: Logout callback AuthProvider'da kayıtlı, otomatik VPN kapatır
          if (confirmed == true && context.mounted) {
            await context.read<AuthProvider>().logout();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.15),
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red, width: 1),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        icon: const Icon(Icons.logout_rounded),
        label: Text(
          l.logout,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 400.ms);
  }
}
