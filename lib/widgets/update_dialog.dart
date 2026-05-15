import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/update_provider.dart';
import '../theme/app_theme.dart';

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateProvider>(
      builder: (context, update, _) {
        if (!update.hasUpdate || update.latestVersion == null) {
          return const SizedBox.shrink();
        }

        final version = update.latestVersion!;

        return PopScope(
          canPop: !update.isForceUpdate,
          child: AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.primary, width: 1),
            ),
            title: Row(
              children: [
                const Icon(Icons.system_update_rounded,
                    color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  update.isForceUpdate ? 'Zorunlu Güncelleme' : 'Yeni Sürüm Mevcut',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Sürüm ${version.versionName}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (version.apkSizeMb > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Boyut: ${version.apkSizeMb.toStringAsFixed(1)} MB',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
                if (version.releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Yenilikler:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    version.releaseNotes,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
                if (update.isForceUpdate) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_rounded, color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bu güncelleme zorunludur. Uygulamayı kullanmaya devam etmek için güncellemeniz gerekmektedir.',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (!update.isForceUpdate)
                TextButton(
                  onPressed: () {
                    update.dismissUpdate();
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Sonra',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(version.downloadUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Güncelle'),
              ),
            ],
          ),
        );
      },
    );
  }
}
