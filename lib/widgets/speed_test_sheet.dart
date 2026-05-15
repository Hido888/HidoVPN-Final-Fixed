import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hidovpn/flutter_gen/gen_l10n/app_localizations.dart';
import '../theme/app_theme.dart';

enum _TestPhase { idle, ping, download, upload, done }

class SpeedTestSheet extends StatefulWidget {
  const SpeedTestSheet({super.key});

  @override
  State<SpeedTestSheet> createState() => _SpeedTestSheetState();
}

class _SpeedTestSheetState extends State<SpeedTestSheet>
    with SingleTickerProviderStateMixin {
  _TestPhase _phase = _TestPhase.idle;
  double? _ping;
  double? _download;
  double? _upload;
  double _currentSpeed = 0.0;

  late AnimationController _needleController;
  late Animation<double> _needleAnimation;

  @override
  void initState() {
    super.initState();
    _needleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _needleAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _needleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _needleController.dispose();
    super.dispose();
  }

  void _updateNeedle(double speed) {
    if (!mounted) return;
    final endValue = math.min(speed / 100.0, 1.0); // Max 100 Mbps gösterge
    _needleAnimation = Tween<double>(
      begin: _needleAnimation.value,
      end: endValue,
    ).animate(CurvedAnimation(parent: _needleController, curve: Curves.easeOut));
    _needleController.forward(from: 0);
    setState(() {
      _currentSpeed = speed;
    });
  }

  Future<void> _startTest() async {
    if (_phase != _TestPhase.idle && _phase != _TestPhase.done) return;

    setState(() {
      _phase = _TestPhase.ping;
      _ping = null;
      _download = null;
      _upload = null;
      _currentSpeed = 0.0;
    });
    _updateNeedle(0);

    // 1. Ping Testi
    final pingStart = DateTime.now();
    try {
      final socket = await Socket.connect('8.8.8.8', 53,
          timeout: const Duration(seconds: 5));
      socket.destroy();
      _ping = DateTime.now().difference(pingStart).inMilliseconds.toDouble();
    } catch (_) {
      _ping = 0.0;
    }

    if (!mounted) return;
    setState(() => _phase = _TestPhase.download);

    // 2. Download Testi
    final dlStart = DateTime.now();
    int dlBytes = 0;
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      
      // v2.5: 20MB dosya
      var req = await client.getUrl(Uri.parse('https://speed.cloudflare.com/__down?bytes=20000000'));
      req.headers.set('User-Agent', 'HidoVPN-SpeedTest/2.0');
      var res = await req.close();
      
      // Fallback
      if (res.statusCode != 200) {
        req = await client.getUrl(Uri.parse('https://proof.ovh.net/files/10Mb.dat'));
        res = await req.close();
      }

      await for (final chunk in res) {
        dlBytes += chunk.length;
        final elapsed = DateTime.now().difference(dlStart).inMilliseconds / 1000.0;
        if (elapsed > 0) {
          final currentMbps = (dlBytes * 8) / (elapsed * 1000000);
          _updateNeedle(currentMbps);
        }
        if (elapsed >= 8) break; // Max 8 saniye
      }
      client.close();
    } catch (_) {}
    
    final dlSeconds = DateTime.now().difference(dlStart).inMilliseconds / 1000.0;
    if (dlSeconds > 0 && dlBytes > 0) {
      _download = (dlBytes * 8) / (dlSeconds * 1000000);
    } else {
      _download = 0.0;
    }
    _updateNeedle(0);

    if (!mounted) return;
    setState(() => _phase = _TestPhase.upload);

    // 3. Upload Testi
    final ulStart = DateTime.now();
    int ulBytes = 0;
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final data = List<int>.filled(1000000, 0); // 1MB chunk
      
      // HATA DÜZELTİLDİ: __upF yerine __up
      var req = await client.postUrl(Uri.parse('https://speed.cloudflare.com/__up'));
      req.headers.set('Content-Type', 'application/octet-stream');
      req.headers.set('User-Agent', 'HidoVPN-SpeedTest/2.0');
      req.headers.contentLength = data.length;
      req.add(data);
      ulBytes = data.length;
      var res = await req.close();
      
      // Fallback
      if (res.statusCode != 200) {
        req = await client.postUrl(Uri.parse('https://httpbin.org/post'));
        req.headers.set('Content-Type', 'application/octet-stream');
        req.headers.contentLength = data.length;
        req.add(data);
        res = await req.close();
      }
      
      final elapsed = DateTime.now().difference(ulStart).inMilliseconds / 1000.0;
      if (elapsed > 0) {
        final currentMbps = (ulBytes * 8) / (elapsed * 1000000);
        _updateNeedle(currentMbps);
      }
      client.close();
    } catch (_) {}
    
    final ulSeconds = DateTime.now().difference(ulStart).inMilliseconds / 1000.0;
    if (ulSeconds > 0 && ulBytes > 0) {
      _upload = (ulBytes * 8) / (ulSeconds * 1000000);
    } else {
      _upload = 0.0;
    }
    _updateNeedle(0);

    if (!mounted) return;
    setState(() => _phase = _TestPhase.done);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.card : AppColors.lightCard;
    final textColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l.speedTest,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          
          // Speedometer
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                CustomPaint(
                  size: const Size(240, 120),
                  painter: _SpeedometerPainter(
                    progress: _needleAnimation.value,
                    color: _phase == _TestPhase.upload ? AppColors.accent : AppColors.primary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentSpeed.toStringAsFixed(1),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l.speedTestMbps,
                      style: TextStyle(color: textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Results
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SpeedItem(
                label: l.speedTestPing,
                value: _ping != null ? '${_ping!.toStringAsFixed(0)} ${l.speedTestMs}' : '--',
                icon: Icons.compare_arrows_rounded,
                color: Colors.orange,
                isActive: _phase == _TestPhase.ping,
              ),
              _SpeedItem(
                label: l.speedTestDownload,
                value: _download != null ? '${_download!.toStringAsFixed(1)} ${l.speedTestMbps}' : '--',
                icon: Icons.download_rounded,
                color: AppColors.primary,
                isActive: _phase == _TestPhase.download,
              ),
              _SpeedItem(
                label: l.speedTestUpload,
                value: _upload != null ? '${_upload!.toStringAsFixed(1)} ${l.speedTestMbps}' : '--',
                icon: Icons.upload_rounded,
                color: AppColors.accent,
                isActive: _phase == _TestPhase.upload,
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: (_phase == _TestPhase.idle || _phase == _TestPhase.done) ? _startTest : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _phase == _TestPhase.idle ? l.speedTestStart : 
                _phase == _TestPhase.done ? l.retry : l.speedTestRunning,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SpeedItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isActive;

  const _SpeedItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Column(
      children: [
        Icon(icon, color: color, size: 24)
            .animate(target: isActive ? 1 : 0)
            .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _SpeedometerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
