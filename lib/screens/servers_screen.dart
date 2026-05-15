import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hidovpn/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vpn_provider.dart';
import '../models/node_model.dart';
import '../theme/app_theme.dart';

class ServersScreen extends StatefulWidget {
  const ServersScreen({super.key});

  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  // A1: Ping ms değeri gösterimi - varsayılan KAPALI
  bool _showPingMs = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.servers),
        actions: [
          // A1: Ping ms göster/gizle toggle
          Consumer<VpnProvider>(
            builder: (context, vpn, _) => Tooltip(
              message: _showPingMs ? 'Ping değerini gizle' : 'Ping ms göster',
              child: IconButton(
                icon: Icon(
                  _showPingMs
                      ? Icons.speed_rounded
                      : Icons.speed_outlined,
                  color: _showPingMs ? AppColors.accent : AppColors.textMuted,
                  size: 22,
                ),
                onPressed: () => setState(() => _showPingMs = !_showPingMs),
              ),
            ),
          ),
          // Otomatik Seç butonu
          Consumer<VpnProvider>(
            builder: (context, vpn, _) => TextButton.icon(
              onPressed: vpn.isLoadingNodes
                  ? null
                  : () {
                      vpn.selectBestNode();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '⚡ ${l.fastestServer}: ${vpn.selectedNode?.name ?? ""}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: AppColors.primary,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.bolt_rounded,
                  color: AppColors.accent, size: 18),
              label: Text(
                l.autoSelect,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Consumer<VpnProvider>(
            builder: (context, vpn, _) => IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: vpn.isLoadingNodes
                  ? null
                  : () {
                      final auth = context.read<AuthProvider>();
                      vpn.loadNodes(auth.api);
                    },
            ),
          ),
        ],
      ),
      body: Consumer<VpnProvider>(
        builder: (context, vpn, _) {
          if (vpn.isLoadingNodes) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (vpn.nodesError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    vpn.nodesError!,
                    style: TextStyle(color: textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      final auth = context.read<AuthProvider>();
                      vpn.loadNodes(auth.api);
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          if (vpn.nodes.isEmpty) {
            return Center(
              child: Text(
                'Sunucu bulunamadı',
                style: TextStyle(color: textSecondary),
              ),
            );
          }

          return Column(
            children: [
              // Otomatik seçim banner
              if (vpn.autoSelectEnabled)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded,
                          color: AppColors.accent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⚡ ${l.autoSelect} aktif — ${l.fastestServer} seçildi',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

              // A1: Ping gösterge bilgi satırı
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.circle,
                        color: AppColors.pingGood, size: 10),
                    const SizedBox(width: 4),
                    Text('İyi',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(width: 10),
                    const Icon(Icons.circle,
                        color: AppColors.pingMedium, size: 10),
                    const SizedBox(width: 4),
                    Text('Orta',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(width: 10),
                    const Icon(Icons.circle,
                        color: AppColors.pingBad, size: 10),
                    const SizedBox(width: 4),
                    Text('Kötü',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                    const Spacer(),
                    if (_showPingMs)
                      Text(
                        'ms değerleri gösteriliyor',
                        style: TextStyle(
                            color: AppColors.accent, fontSize: 11),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: vpn.nodes.length,
                  itemBuilder: (context, index) {
                    final node = vpn.nodes[index];
                    final isSelected =
                        vpn.selectedNode?.url == node.url;
                    final isConnected = vpn.isConnected && isSelected;
                    return _ServerTile(
                      node: node,
                      isSelected: isSelected,
                      isConnected: isConnected,
                      index: index,
                      isDark: isDark,
                      showPingMs: _showPingMs,
                      onTap: () => vpn.selectNode(node),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ServerTile extends StatelessWidget {
  final NodeModel node;
  final bool isSelected;
  final bool isConnected;
  final int index;
  final bool isDark;
  final bool showPingMs;
  final VoidCallback onTap;

  const _ServerTile({
    required this.node,
    required this.isSelected,
    required this.isConnected,
    required this.index,
    required this.isDark,
    required this.showPingMs,
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
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final cardBorderColor =
        isDark ? AppColors.cardBorder : AppColors.lightCardBorder;
    final bgColor =
        isDark ? AppColors.background : AppColors.lightBackground;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    // Sunucu durum rengi ve etiketi
    // hidovpn.xyz gösterilmez — sadece Bağlı / Offline
    final Color statusColor =
        isConnected ? AppColors.accent : AppColors.textMuted;
    final String statusLabel = isConnected ? 'Bağlı' : 'Offline';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isConnected
                ? AppColors.accent.withOpacity(0.5)
                : isSelected
                    ? AppColors.primary
                    : cardBorderColor,
            width: isSelected || isConnected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Sıra numarası
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.2)
                    : bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Node bilgileri (isim + protokol + durum)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.name,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      // Protokol badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          node.protocol,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Bağlı / Offline durum badge (hidovpn.xyz yok)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
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

            // A1: Ping göstergesi — sadece renk noktası (ms gizli)
            // showPingMs=true ise ms değeri de gösterilir
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                node.isPinging
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _pingColor,
                        ),
                      )
                    : Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _pingColor,
                          boxShadow: [
                            BoxShadow(
                              color: _pingColor.withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                // A1: ms değeri sadece toggle açıksa gösterilir
                if (showPingMs && !node.isPinging) ...[
                  const SizedBox(height: 4),
                  Text(
                    node.pingText,
                    style: TextStyle(
                      color: _pingColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),

            if (isSelected) ...[
              const SizedBox(width: 10),
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ],
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
            delay: Duration(milliseconds: index * 50), duration: 300.ms)
        .slideX(begin: 0.1);
  }
}
