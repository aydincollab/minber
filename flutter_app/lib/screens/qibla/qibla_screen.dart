import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/preferences_provider.dart';
import '../../services/location_service.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with SingleTickerProviderStateMixin {
  double? _deviceHeading;
  double? _qiblaAngle;
  String _statusMsg = 'Konum alınıyor...';
  String _locationLabel = '';

  static const double _meccaLat = 21.3891;
  static const double _meccaLon = 39.8579;

  @override
  void initState() {
    super.initState();
    _initQibla();
  }

  Future<void> _initQibla() async {
    try {
      final locationService = LocationService();
      final prefs = Provider.of<PreferencesProvider>(context, listen: false);

      double? userLat;
      double? userLon;

      final position = await locationService.getCurrentPosition();
      if (position != null) {
        userLat = position.latitude;
        userLon = position.longitude;
        if (mounted) setState(() => _locationLabel = 'GPS konumunuza göre hesaplandı');
      } else {
        final cityCoords = _cityCoords(prefs.city);
        userLat = cityCoords.$1;
        userLon = cityCoords.$2;
        if (mounted) setState(() => _locationLabel = '${prefs.city} şehir konumuna göre hesaplandı');
      }

      if (userLat != null && userLon != null) {
        final bearing = _calculateBearing(userLat, userLon, _meccaLat, _meccaLon);
        if (mounted) {
          setState(() {
            _qiblaAngle = bearing;
            _statusMsg = '';
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _statusMsg = 'Konum alınamadı');
    }
  }


  /// Spherical bearing from (lat1,lon1) to (lat2,lon2) in degrees 0‑360.
  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final l1 = lat1 * math.pi / 180;
    final l2 = lat2 * math.pi / 180;
    final dl = (lon2 - lon1) * math.pi / 180;
    final y = math.sin(dl) * math.cos(l2);
    final x = math.cos(l1) * math.sin(l2) - math.sin(l1) * math.cos(l2) * math.cos(dl);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  (double, double) _cityCoords(String city) {
    const Map<String, (double, double)> coords = {
      'İstanbul': (41.015, 28.979),
      'Ankara': (39.925, 32.836),
      'İzmir': (38.423, 27.142),
      'Bursa': (40.182, 29.061),
      'Antalya': (36.897, 30.713),
      'Adana': (37.001, 35.328),
      'Konya': (37.875, 32.492),
      'Erzurum': (39.904, 41.267),
    };
    return coords[city] ?? (39.925, 32.836); // default Ankara
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.darkMid,
        title: const Text(
          'Kıble Yönü',
          style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textLight),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<CompassEvent>(
        stream: FlutterCompass.events,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Pusula sensörü bulunamadı',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          final heading = snapshot.data?.heading;
          if (heading != null) _deviceHeading = heading;

          return _buildCompassUI();
        },
      ),
    );
  }

  Widget _buildCompassUI() {
    final heading = _deviceHeading ?? 0;
    final qibla = _qiblaAngle;

    // Angle to rotate the compass so that qibla points up
    final compassRotation = qibla != null
        ? -(heading * math.pi / 180)
        : -(heading * math.pi / 180);

    // Qibla needle angle relative to compass
    final qiblaNeedleAngle = qibla != null
        ? (qibla - heading) * math.pi / 180
        : 0.0;

    final isAligned = qibla != null &&
        ((qibla - heading).abs() < 5 || (qibla - heading + 360).abs() < 5 || (qibla - heading - 360).abs() < 5);

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Status / info
          if (_statusMsg.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _statusMsg,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

          if (_locationLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
              child: Text(
                _locationLabel,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),

          if (isAligned)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withOpacity(0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.gold, size: 16),
                  SizedBox(width: 8),
                  Text('Kıble yönüne bakıyorsunuz!',
                      style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Compass ring + needle
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating compass rose
                  Transform.rotate(
                    angle: compassRotation,
                    child: _CompassRose(),
                  ),

                  // Qibla needle (always points towards Mecca)
                  if (qibla != null)
                    Transform.rotate(
                      angle: qiblaNeedleAngle,
                      child: _QiblaNeedle(),
                    ),

                  // Center dot
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Degree info
          if (qibla != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  Text(
                    '${qibla.toStringAsFixed(1)}°',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kıble Açısı (Kuzeyden)',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CompassRose extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: CustomPaint(painter: _CompassRosePainter()),
    );
  }
}

class _CompassRosePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer ring
    final ringPaint = Paint()
      ..color = AppColors.gold.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 4, ringPaint);

    // Inner ring
    canvas.drawCircle(center, radius * 0.7,
        Paint()
          ..color = AppColors.gold.withOpacity(0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    // Cardinal tick marks
    final tickPaint = Paint()
      ..color = AppColors.textMuted.withOpacity(0.5)
      ..strokeWidth = 1.5;

    final majorTickPaint = Paint()
      ..color = AppColors.gold.withOpacity(0.6)
      ..strokeWidth = 2;

    for (int i = 0; i < 36; i++) {
      final angle = i * 10.0 * math.pi / 180;
      final isMajor = i % 9 == 0;
      final tickLen = isMajor ? 18.0 : 8.0;
      final startR = radius - 4 - tickLen;
      final endR = radius - 4;
      canvas.drawLine(
        center + Offset(math.cos(angle) * startR, math.sin(angle) * startR),
        center + Offset(math.cos(angle) * endR, math.sin(angle) * endR),
        isMajor ? majorTickPaint : tickPaint,
      );
    }

    // Cardinal labels
    const labels = ['K', 'D', 'G', 'B'];
    const angles = [-math.pi / 2, 0.0, math.pi / 2, math.pi];
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < 4; i++) {
      tp.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: i == 0 ? AppColors.gold : AppColors.textMuted,
          fontSize: i == 0 ? 16 : 13,
          fontWeight: FontWeight.bold,
        ),
      );
      tp.layout();
      final pos = center +
          Offset(
            math.cos(angles[i]) * (radius - 28) - tp.width / 2,
            math.sin(angles[i]) * (radius - 28) - tp.height / 2,
          );
      tp.paint(canvas, pos);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QiblaNeedle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: CustomPaint(painter: _QiblaNeedlePainter()),
    );
  }
}

class _QiblaNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Golden needle pointing up (towards Mecca)
    final needlePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.gold, AppColors.gold.withOpacity(0.3)],
      ).createShader(Rect.fromCenter(
          center: center, width: 10, height: radius * 1.4))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy - radius * 0.65)
      ..lineTo(center.dx - 7, center.dy)
      ..lineTo(center.dx, center.dy + radius * 0.2)
      ..lineTo(center.dx + 7, center.dy)
      ..close();

    canvas.drawPath(path, needlePaint);

    // Kaaba emoji-style marker at tip
    final tipPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      center + Offset(0, -(radius * 0.65)),
      7,
      tipPaint,
    );
    canvas.drawCircle(
      center + Offset(0, -(radius * 0.65)),
      7,
      Paint()
        ..color = AppColors.dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
