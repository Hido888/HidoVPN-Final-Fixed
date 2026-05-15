import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hidovpn/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final cardBorderColor =
        isDark ? AppColors.cardBorder : AppColors.lightCardBorder;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final bgColor =
        isDark ? AppColors.background : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(l.profile),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) => IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => auth.refreshProfile(),
            ),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          if (user == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // P1: Büyük avatar + kullanıcı adı + durum rozeti
                _buildHeroAvatar(user, textPrimary, textSecondary),
                const SizedBox(height: 24),

                // P4: Abonelik bilgi kartı (tarih + kalan gün zaman çizelgesi)
                _buildSubscriptionCard(
                    context, user, l, cardColor, cardBorderColor, textSecondary),
                const SizedBox(height: 16),

                // P2: Veri kullanımı yüzde çubuğu
                _buildDataCard(
                    context, user, l, cardColor, cardBorderColor, textSecondary),
                const SizedBox(height: 16),

                // P3: Cihaz bilgileri
                _buildInfoCard(context, user, l, cardColor, cardBorderColor,
                    textSecondary, textPrimary),
                const SizedBox(height: 16),

                // Tema + Dil ayarları
                _buildSettingsCard(context, l, cardColor, cardBorderColor,
                    textSecondary, textPrimary),
                const SizedBox(height: 32),

                // Çıkış butonu
                _buildLogoutButton(context, auth, l),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── P1: Hero Avatar ─────────────────────────────────────────────
  Widget _buildHeroAvatar(user, Color textPrimary, Color textSecondary) {
    final isActive = user.isActive && !user.isSubscriptionExpired;
    final statusColor = isActive ? AppColors.accent : AppColors.error;
    final statusLabel = isActive ? 'Aktif' : 'Pasif';

    return Column(
      children: [
        // P1: Büyük avatar (100px) + durum halkası
        Stack(
          alignment: Alignment.center,
          children: [
            // Dış parlama halkası
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: statusColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
            // Avatar
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user.displayName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // P1: Durum rozeti (sağ alt)
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black26, width: 1.5),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).scale(
            begin: const Offset(0.7, 0.7)),
        const SizedBox(height: 14),
        Text(
          user.displayName,
          style: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 4),
        Text(
          '@${user.username}',
          style: TextStyle(color: textSecondary, fontSize: 14),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 8),
        // P1: Admin rozeti (varsa)
        if (user.isAdmin)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '⭐ Admin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  // ─── P4: Abonelik Kartı (tarih + zaman çizelgesi) ────────────────
  Widget _buildSubscriptionCard(BuildContext context, user, AppLocalizations l,
      Color cardColor, Color cardBorderColor, Color textSecondary) {
    final isExpired = user.isSubscriptionExpired;
    final daysLeft = user.daysLeft;
    final color = isExpired
        ? AppColors.error
        : daysLeft <= 3
            ? AppColors.warning
            : AppColors.accent;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;

    // P4: Abonelik ilerleme yüzdesi (toplam 30 günlük döngü varsayımı)
    final totalDays = 30;
    final progressPercent =
        (daysLeft / totalDays).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: color, size: 22),
              const SizedBox(width: 10),
              Text(
                l.subscription,
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isExpired ? 'Süresi Doldu' : 'Aktif',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$daysLeft',
                    style: TextStyle(
                      color: color,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  Text(
                    l.daysLeft,
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                ],
              ),
              // P4: Abonelik bitiş tarihi
              if (user.subscriptionEnd != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Başlangıç',
                      style: TextStyle(color: textSecondary, fontSize: 11),
                    ),
                    Text(
                      _formatDate(user.subscriptionEnd!
                          .subtract(Duration(days: totalDays))),
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bitiş',
                      style: TextStyle(color: textSecondary, fontSize: 11),
                    ),
                    Text(
                      _formatDate(user.subscriptionEnd!),
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          // P4: Zaman çizelgesi çubuğu
          LinearPercentIndicator(
            lineHeight: 6,
            percent: progressPercent,
            backgroundColor: cardBorderColor,
            progressColor: color,
            barRadius: const Radius.circular(3),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progressPercent * 100).toStringAsFixed(0)}% kaldı',
                style: TextStyle(color: textSecondary, fontSize: 11),
              ),
              Text(
                '$totalDays günlük döngü',
                style: TextStyle(color: textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2);
  }

  // ─── P2: Veri Kullanımı ───────────────────────────────────────────
  Widget _buildDataCard(BuildContext context, user, AppLocalizations l,
      Color cardColor, Color cardBorderColor, Color textSecondary) {
    final hasLimit = !user.isUnlimited;
    final percent = user.dataUsagePercent as double;
    final color = percent > 0.9
        ? AppColors.error
        : percent > 0.7
            ? AppColors.warning
            : AppColors.accent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.data_usage_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                l.dataUsage,
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasLimit) ...[
            // P2: Kullanılan / Toplam
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user.dataUsedGb.toStringAsFixed(2)} GB',
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'kullanıldı',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${user.dataLimitGb.toStringAsFixed(0)} GB',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'toplam',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // P2: Yüzde çubuğu
            LinearPercentIndicator(
              lineHeight: 10,
              percent: percent,
              backgroundColor: cardBorderColor,
              progressColor: color,
              barRadius: const Radius.circular(5),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(percent * 100).toStringAsFixed(1)}% kullanıldı',
                  style: TextStyle(color: color, fontSize: 12),
                ),
                Text(
                  '${(user.dataLimitGb - user.dataUsedGb).toStringAsFixed(2)} GB kaldı',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Text(
                  '∞',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.unlimited,
                      style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Sınırsız veri',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.2);
  }

  // ─── P3: Cihaz Bilgileri ──────────────────────────────────────────
  Widget _buildInfoCard(BuildContext context, user, AppLocalizations l,
      Color cardColor, Color cardBorderColor, Color textSecondary,
      Color textPrimary) {
    final activeDevices = user.activeDevices as int;
    final maxDevices = user.maxDevices as int;
    final devicePercent =
        maxDevices > 0 ? (activeDevices / maxDevices).clamp(0.0, 1.0) : 0.0;
    final deviceColor = activeDevices >= maxDevices
        ? AppColors.error
        : AppColors.accent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor),
      ),
      child: Column(
        children: [
          // P3: Cihaz kullanım çubuğu
          Row(
            children: [
              const Icon(Icons.devices_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                l.activeDevices,
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
              const Spacer(),
              Text(
                '$activeDevices / $maxDevices',
                style: TextStyle(
                  color: deviceColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearPercentIndicator(
            lineHeight: 6,
            percent: devicePercent.toDouble(),
            backgroundColor: cardBorderColor,
            progressColor: deviceColor,
            barRadius: const Radius.circular(3),
            padding: EdgeInsets.zero,
          ),
          Divider(color: cardBorderColor, height: 24),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: l.username,
            value: user.username,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          Divider(color: cardBorderColor, height: 24),
          _InfoRow(
            icon: Icons.circle,
            label: 'Durum', // TODO: Lokalize edilebilir
            value: user.isActive ? 'Aktif' : 'Pasif',
            valueColor:
                user.isActive ? AppColors.accent : AppColors.error,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.2);
  }

  // ─── Tema + Dil Ayarları ──────────────────────────────────────────
  Widget _buildSettingsCard(BuildContext context, AppLocalizations l,
      Color cardColor, Color cardBorderColor, Color textSecondary,
      Color textPrimary) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.palette_outlined,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    l.theme,
                    style: TextStyle(color: textSecondary, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ThemeButton(
                    label: '🌙',
                    title: l.darkTheme,
                    isSelected: settings.themeMode == ThemeMode.dark,
                    onTap: () => settings.setThemeMode(ThemeMode.dark),
                  ),
                  const SizedBox(width: 8),
                  _ThemeButton(
                    label: '☀️',
                    title: l.lightTheme,
                    isSelected: settings.themeMode == ThemeMode.light,
                    onTap: () => settings.setThemeMode(ThemeMode.light),
                  ),
                  const SizedBox(width: 8),
                  _ThemeButton(
                    label: '📱',
                    title: l.systemTheme,
                    isSelected: settings.themeMode == ThemeMode.system,
                    onTap: () => settings.setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
              Divider(color: cardBorderColor, height: 28),
              Row(
                children: [
                  const Icon(Icons.language_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    l.language,
                    style: TextStyle(color: textSecondary, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _LangButton(
                    flag: '🇹🇷',
                    label: 'Türkçe',
                    isSelected: settings.locale.languageCode == 'tr',
                    onTap: () => settings.setLocale(const Locale('tr')),
                  ),
                  const SizedBox(width: 8),
                  _LangButton(
                    flag: '🇬🇧',
                    label: 'English',
                    isSelected: settings.locale.languageCode == 'en',
                    onTap: () => settings.setLocale(const Locale('en')),
                  ),
                  const SizedBox(width: 8),
                  _LangButton(
                    flag: '🇷🇺',
                    label: 'Русский',
                    isSelected: settings.locale.languageCode == 'ru',
                    onTap: () => settings.setLocale(const Locale('ru')),
                  ),
                  const SizedBox(width: 8),
                  _LangButton(
                    flag: '🇹🇲',
                    label: 'Türkmençe',
                    isSelected: settings.locale.languageCode == 'tk',
                    onTap: () => settings.setLocale(const Locale('tk')),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 450.ms, duration: 400.ms).slideY(begin: 0.2);
      },
    );
  }

  // ─── Çıkış Butonu ────────────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context, AuthProvider auth,
      AppLocalizations l) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context, auth, l),
        icon: const Icon(Icons.logout_rounded, color: AppColors.error),
        label: Text(
          l.logout,
          style: const TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  void _confirmLogout(
      BuildContext context, AuthProvider auth, AppLocalizations l) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l.logout,
          style: TextStyle(
              color: textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          l.logoutConfirm,
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l.cancel,
              style: TextStyle(color: textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.logout();
            },
            child: Text(
              l.logout,
              style: const TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

// ─── Theme Button ────────────────────────────────────────────────
class _ThemeButton extends StatelessWidget {
  final String label;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeButton({
    required this.label,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Language Button ─────────────────────────────────────────────
class _LangButton extends StatelessWidget {
  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangButton({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Info Row ────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Color textPrimary;
  final Color textSecondary;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: textSecondary, size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: textSecondary, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
