import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hidovpn/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vpn_provider.dart';
import '../providers/settings_provider.dart';
import '../models/node_model.dart';
import '../theme/app_theme.dart';
import '../widgets/speed_test_sheet.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  // ─── Gerçek ağ durumu ────────────────────────────────────────────
  List<ConnectivityResult> _connectivity = [ConnectivityResult.none];
  late StreamSubscription<List<ConnectivityResult>> _connectivitySub;

  // Speed Test durumu artık SpeedTestSheet içinde yönetiliyor

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // İlk ağ durumunu al
    Connectivity().checkConnectivity().then((result) {
      if (mounted) setState(() => _connectivity = result);
    });
    // Ağ değişikliklerini dinle
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      if (mounted) setState(() => _connectivity = result);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final vpn = context.read<VpnProvider>();
      if (vpn.nodes.isEmpty) {
        vpn.loadNodes(auth.api);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _connectivitySub.cancel();
    super.dispose();
  }

  void _openSpeedTest() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SpeedTestSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Consumer<VpnProvider>(
      builder: (context, vpn, _) {
        // Limit aşıldı uyarısı
        if (vpn.limitExceeded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              vpn.clearLimitExceeded();
              _showThemedDialog(
                context,
                title: l.limitExceeded,
                titleColor: AppColors.warning,
                content:
                    'Veri kullanım limitinize ulaştınız. VPN bağlantısı kesildi.',
              );
            }
          });
        }
        // Oturum sona erdi uyarısı
        if (vpn.sessionExpired) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              vpn.clearSessionExpired();
              _showThemedDialog(
                context,
                title: l.sessionExpired,
                titleColor: AppColors.error,
                content:
                    'Hesabınıza başka bir cihazdan giriş yapıldı. VPN bağlantısı kesildi.',
              );
            }
          });
        }
        return _buildScaffold(context, l);
      },
    );
  }

  void _showThemedDialog(BuildContext context,
      {required String title,
      required Color titleColor,
      required String content}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.card : AppColors.lightCard;
    final textColor =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgColor,
        title: Text(title, style: TextStyle(color: titleColor)),
        content: Text(content, style: TextStyle(color: textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam', style: TextStyle(color: titleColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, AppLocalizations l) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final cardBorderColor =
        isDark ? AppColors.cardBorder : AppColors.lightCardBorder;
    final bgColor =
        isDark ? AppColors.background : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final auth = context.read<AuthProvider>();
            await auth.refreshProfile();
            await context.read<VpnProvider>().loadNodes(auth.api);
          },
          color: AppColors.primary,
          backgroundColor: cardColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                // M3: Gerçek ağ durumu bandı
                _buildNetworkBanner(isDark),
                const SizedBox(height: 10),
                // M1: Üst menü (Profil + Dil + Ayarlar)
                _buildHeader(l, isDark),
                const SizedBox(height: 28),
                _buildConnectButton(l, isDark),
                const SizedBox(height: 16),
                _buildSpeedWidget(l, isDark, cardColor, cardBorderColor),
                const SizedBox(height: 20),
                _buildStatsRow(l, isDark, cardColor, cardBorderColor),
                const SizedBox(height: 24),
                _buildServerSection(l, isDark, cardColor, cardBorderColor),
                const SizedBox(height: 16),
                // Speed Test bölümü
                _buildSpeedTestSection(l, isDark, cardColor, cardBorderColor),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── M3: Gerçek Ağ Durumu Bandı ─────────────────────────────────
  Widget _buildNetworkBanner(bool isDark) {
    return Consumer<VpnProvider>(
      builder: (context, vpn, _) {
        final isVpnConnected = vpn.isConnected;

        // Gerçek ağ tipi
        final hasWifi = _connectivity.contains(ConnectivityResult.wifi);
        final hasMobile = _connectivity.contains(ConnectivityResult.mobile);
        final hasEthernet =
            _connectivity.contains(ConnectivityResult.ethernet);
        final hasNet = hasWifi || hasMobile || hasEthernet;

        final String networkType;
        final IconData networkIcon;
        if (hasWifi || hasEthernet) {
          networkType = 'WiFi';
          networkIcon = Icons.wifi_rounded;
        } else if (hasMobile) {
          networkType = 'Mobil Veri';
          networkIcon = Icons.signal_cellular_alt_rounded;
        } else {
          networkType = 'İnternet Yok';
          networkIcon = Icons.signal_wifi_off_rounded;
        }

        // VPN + ağ durumu birleşik mesaj
        final Color bannerColor;
        final String bannerText;
        final IconData bannerIcon;

        if (!hasNet) {
          bannerColor = AppColors.error;
          bannerText = 'İnternet bağlantısı yok';
          bannerIcon = Icons.wifi_off_rounded;
        } else if (isVpnConnected) {
          bannerColor = AppColors.accent;
          bannerText = 'VPN Aktif — $networkType — Güvenli';
          bannerIcon = Icons.shield_rounded;
        } else {
          bannerColor = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
          bannerText = '$networkType — VPN Kapalı';
          bannerIcon = networkIcon;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bannerColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: bannerColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(bannerIcon, color: bannerColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bannerText,
                  style: TextStyle(
                    color: bannerColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Sunucu bağlantı durumu (M2)
              if (isVpnConnected && vpn.selectedNode != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.accent.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sunucuya Bağlı',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              if (!isVpnConnected)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.disconnected.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Bağlı Değil',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms);
      },
    );
  }

  // ─── M1: Header (Profil + Dil + Ayarlar) ─────────────────────────
  Widget _buildHeader(AppLocalizations l, bool isDark) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.welcome,
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
                Text(
                  user?.displayName ?? 'Kullanıcı',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _buildLanguageButton(context),
                const SizedBox(width: 8),
                _buildIconButton(
                  icon: Icons.person_rounded,
                  color: AppColors.accent,
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProfileScreen()),
                  ),
                ),
                const SizedBox(width: 8),
                _buildIconButton(
                  icon: Icons.settings_rounded,
                  color: AppColors.primary,
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final borderColor =
        isDark ? AppColors.cardBorder : AppColors.lightCardBorder;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // M4: Dil değiştirme butonu
  Widget _buildLanguageButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final langCode = settings.locale.languageCode;
    final String flag;
    switch (langCode) {
      case 'en':
        flag = '🇬🇧';
        break;
      case 'ru':
        flag = '🇷🇺';
        break;
      case 'tk':
        flag = '🇹🇲';
        break;
      default:
        flag = '🇹🇷';
    }
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final borderColor =
        isDark ? AppColors.cardBorder : AppColors.lightCardBorder;
    return GestureDetector(
      onTap: () {
        final langs = ['tr', 'en', 'ru', 'tk'];
        final idx = langs.indexOf(langCode);
        final next = langs[(idx + 1) % langs.length];
        settings.setLocale(Locale(next));
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(flag, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  // ─── Bağlan Butonu ────────────────────────────────────────────────
  Widget _buildConnectButton(AppLocalizations l, bool isDark) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Consumer<VpnProvider>(
      builder: (context, vpn, _) {
        final isConnected = vpn.isConnected;
        final isConnecting = vpn.isConnecting;
        final selectedNode = vpn.selectedNode;

        final Color buttonColor = isConnected
            ? AppColors.accent
            : isConnecting
                ? AppColors.warning
                : AppColors.primary;

        final String statusText = isConnected
            ? l.connected
            : isConnecting
                ? l.connecting
                : l.disconnected;

        return Column(
          children: [
            // Büyük bağlan butonu
            GestureDetector(
              onTap: () async {
                if (isConnecting) return;
                final auth = context.read<AuthProvider>();
                if (isConnected) {
                  await vpn.disconnect();
                } else {
                  if (selectedNode == null && vpn.nodes.isNotEmpty) {
                    vpn.selectNode(vpn.nodes.first);
                  }
                  if (vpn.selectedNode != null) {
                    await vpn.connect(auth.api);
                  }
                }
              },
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = isConnected
                      ? 1.0 + (_pulseController.value * 0.04)
                      : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            buttonColor.withOpacity(0.3),
                            buttonColor.withOpacity(0.05),
                          ],
                        ),
                        border: Border.all(
                          color: buttonColor.withOpacity(0.6),
                          width: 2,
                        ),
                        boxShadow: isConnected
                            ? [
                                BoxShadow(
                                  color: buttonColor.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isConnected
                                ? Icons.shield_rounded
                                : Icons.shield_outlined,
                            color: buttonColor,
                            size: 56,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: buttonColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Seçili sunucu bilgisi (M2: Sunucuya Bağlı / Bağlı Değil)
            if (selectedNode != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppColors.accent.withOpacity(0.08)
                      : (isDark
                          ? AppColors.card
                          : AppColors.lightCard),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isConnected
                        ? AppColors.accent.withOpacity(0.3)
                        : (isDark
                            ? AppColors.cardBorder
                            : AppColors.lightCardBorder),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isConnected
                            ? AppColors.accent
                            : AppColors.disconnected,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected
                          ? '${l.serverConnected}: ${selectedNode.name}'
                          : 'Seçili: ${selectedNode.name}',
                      style: TextStyle(
                        color: isConnected
                            ? AppColors.accent
                            : textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                l.serverNotSelected,
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
          ],
        );
      },
    );
  }

  // ─── Hız Göstergesi (VPN bağlıyken) ─────────────────────────────
  Widget _buildSpeedWidget(AppLocalizations l, bool isDark, Color cardColor,
      Color cardBorderColor) {
    return Consumer<VpnProvider>(
      builder: (context, vpn, _) {
        if (!vpn.isConnected) return const SizedBox.shrink();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SpeedItem(
                icon: Icons.arrow_downward_rounded,
                color: AppColors.accent,
                label: l.downloadSpeed,
                value: vpn.downloadSpeedFormatted,
                isDark: isDark,
              ),
              Container(width: 1, height: 40, color: cardBorderColor),
              _SpeedItem(
                icon: Icons.arrow_upward_rounded,
                color: AppColors.primary,
                label: l.uploadSpeed,
                value: vpn.uploadSpeedFormatted,
                isDark: isDark,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3);
      },
    );
  }

  Widget _buildStatsRow(AppLocalizations l, bool isDark, Color cardColor,
      Color cardBorderColor) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_today_rounded,
                label: l.daysLeft,
                value: user != null ? '${user.daysLeft}' : '-',
                subtitle: '',
                color: user != null && user.daysLeft <= 3
                    ? AppColors.error
                    : AppColors.primary,
                cardColor: cardColor,
                cardBorderColor: cardBorderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DataCard(
                user: user,
                cardColor: cardColor,
                cardBorderColor: cardBorderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                unlimitedLabel: l.unlimited,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.devices_rounded,
                label: l.activeDevices,
                value: user != null ? '${user.activeDevices}' : '-',
                subtitle: '',
                color: AppColors.accent,
                cardColor: cardColor,
                cardBorderColor: cardBorderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildServerSection(AppLocalizations l, bool isDark, Color cardColor,
      Color cardBorderColor) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Consumer<VpnProvider>(
      builder: (context, vpn, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.servers,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${vpn.nodes.length} sunucu',
                  style:
                      TextStyle(color: textSecondary, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (vpn.isLoadingNodes)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (vpn.nodes.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorderColor),
                ),
                child: Center(
                  child: Text(
                    l.serverNotFound,
                    style: TextStyle(color: textSecondary),
                  ),
                ),
              )
            else
              ...vpn.nodes.take(3).map((node) => _ServerTile(
                    node: node,
                    isSelected: vpn.selectedNode?.url == node.url,
                    isConnected: vpn.isConnected &&
                        vpn.selectedNode?.url == node.url,
                    isDark: isDark,
                    cardColor: cardColor,
                    cardBorderColor: cardBorderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      vpn.selectNode(node);
                    },
                  )),
          ],
        );
      },
    );
  }

  // ─── Speed Test Bölümü ────────────────────────────────────────────
  Widget _buildSpeedTestSection(AppLocalizations l, bool isDark,
      Color cardColor, Color cardBorderColor) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return GestureDetector(
      onTap: _openSpeedTest,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.speed_rounded,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.speedTest,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.speedTestStart,
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: textSecondary, size: 16),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─── Speed Test Sonuç Widget ─────────────────────────────────────────
class _SpeedTestResult extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color textPrimary;
  final Color textSecondary;

  const _SpeedTestResult({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Text(
          label,
          style: TextStyle(color: textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

// ─── Speed Item (VPN hız göstergesi) ────────────────────────────────
class _SpeedItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isDark;

  const _SpeedItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

// ─── Stat Card ───────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final Color cardColor;
  final Color cardBorderColor;
  final Color textPrimary;
  final Color textSecondary;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.cardColor,
    required this.cardBorderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─── Data Card ───────────────────────────────────────────────────────
class _DataCard extends StatelessWidget {
  final dynamic user;
  final Color cardColor;
  final Color cardBorderColor;
  final Color textPrimary;
  final Color textSecondary;
  final String unlimitedLabel;

  const _DataCard({
    required this.user,
    required this.cardColor,
    required this.cardBorderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.unlimitedLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.data_usage_rounded,
              color: AppColors.warning, size: 18),
          const SizedBox(height: 8),
          Text(
            user != null
                ? (user.isUnlimited ? unlimitedLabel : user.dataUsedText)
                : '-',
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Veri',
            style: TextStyle(color: textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─── Server Tile ─────────────────────────────────────────────────────
class _ServerTile extends StatelessWidget {
  final NodeModel node;
  final bool isSelected;
  final bool isConnected;
  final bool isDark;
  final Color cardColor;
  final Color cardBorderColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const _ServerTile({
    required this.node,
    required this.isSelected,
    required this.isConnected,
    required this.isDark,
    required this.cardColor,
    required this.cardBorderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  Color get _pingColor {
    switch (node.pingQuality) {
      case PingQuality.good:
        return AppColors.pingGood;
      case PingQuality.medium:
        return AppColors.pingMedium;
      case PingQuality.bad:
        return AppColors.pingBad;
      case PingQuality.unknown:
        return AppColors.disconnected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.4)
                : cardBorderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Numara
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${node.name.hashCode.abs() % 99 + 1}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // İsim + protokol + durum
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.name,
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Protokol badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          node.protocol.toUpperCase(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Bağlı / Offline durumu
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isConnected
                              ? AppColors.accent.withOpacity(0.15)
                              : AppColors.disconnected
                                  .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isConnected
                                    ? AppColors.accent
                                    : AppColors.disconnected,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isConnected ? 'Bağlı' : 'Offline',
                              style: TextStyle(
                                color: isConnected
                                    ? AppColors.accent
                                    : textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Ping renk noktası
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _pingColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            // Seçili işareti
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20)
            else
              Icon(Icons.radio_button_unchecked_rounded,
                  color: textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
