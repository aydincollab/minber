import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../onboarding/onboarding_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _riseController;
  late AnimationController _glowController;
  late AnimationController _starsController;
  late Animation<double> _riseAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _starsAnim;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _riseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _riseAnim = CurvedAnimation(
      parent: _riseController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _riseController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(_glowController);
    _starsAnim = CurvedAnimation(
      parent: _starsController,
      curve: Curves.easeIn,
    );

    _riseController.forward();
    _starsController.forward();

    // Play intro audio
    _audioPlayer.play(AssetSource('audio/intro.mp3'));

    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _riseController.dispose();
    _glowController.dispose();
    _starsController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (!mounted) return;

    if (hasSeenOnboarding) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.5,
            colors: [
              Color(0xFF1A3D26),
              Color(0xFF0D2118),
              Color(0xFF060F0C),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Twinkling stars ────────────────────────────────────────
            AnimatedBuilder(
              animation: _starsAnim,
              builder: (_, __) => CustomPaint(
                size: Size(size.width, size.height),
                painter: _StarsPainter(_starsAnim.value),
              ),
            ),

            // ── Rising Crescent ────────────────────────────────────────
            AnimatedBuilder(
              animation: _riseAnim,
              builder: (_, __) {
                final rise = _riseAnim.value;
                // Rise from bottom-center to center
                final yOffset = size.height * 0.15 * (1 - rise);

                return Transform.translate(
                  offset: Offset(0, yOffset),
                  child: Opacity(
                    opacity: _fadeAnim.value,
                    child: AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, __) => Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold
                                  .withOpacity(0.3 * _glowAnim.value),
                              blurRadius: 60,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: _CrescentPainter(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── Text labels ────────────────────────────────────────────
            AnimatedBuilder(
              animation: _riseAnim,
              builder: (_, __) => Opacity(
                opacity: (_riseAnim.value - 0.5).clamp(0.0, 1.0) * 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 170), // below crescent
                    Text(
                      'Minber',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 46,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            color: AppColors.gold.withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Hutbe & Namaz Vakitleri',
                      style: TextStyle(
                        color: Color(0xFF8FBF9F),
                        fontSize: 15,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Crescent Moon Painter ──────────────────────────────────────────────────
class _CrescentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.42;

    final goldPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;

    // Draw a full gold circle, then cut with a dark offset circle to form crescent
    final outerPath = Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    final cutPath = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(cx + r * 0.45, cy - r * 0.06), radius: r * 0.82));

    final crescent = Path.combine(PathOperation.difference, outerPath, cutPath);

    // Subtle glow behind crescent
    final glowPaint = Paint()
      ..color = AppColors.gold.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawPath(crescent, glowPaint);

    canvas.drawPath(crescent, goldPaint);

    // Small star beside crescent
    final starX = cx + r * 0.62;
    final starY = cy - r * 0.42;
    _drawStar(canvas, Offset(starX, starY), 6, AppColors.gold);
  }

  void _drawStar(Canvas canvas, Offset center, double r, Color color) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = math.pi / 2 + (2 * math.pi / 5) * i;
      final innerAngle = outerAngle + math.pi / 5;
      final outer = Offset(center.dx + r * math.cos(outerAngle),
          center.dy - r * math.sin(outerAngle));
      final inner = Offset(center.dx + (r * 0.4) * math.cos(innerAngle),
          center.dy - (r * 0.4) * math.sin(innerAngle));
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Stars background Painter ───────────────────────────────────────────────
class _StarsPainter extends CustomPainter {
  final double progress; // 0..1
  static final List<_Star> _stars = _generateStars();

  _StarsPainter(this.progress);

  static List<_Star> _generateStars() {
    final rng = math.Random(42);
    return List.generate(60, (_) => _Star(
      x: rng.nextDouble(),
      y: rng.nextDouble() * 0.8, // top 80% of screen
      r: rng.nextDouble() * 1.5 + 0.5,
      opacity: rng.nextDouble() * 0.6 + 0.2,
      delay: rng.nextDouble(),
    ));
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in _stars) {
      final visible = ((progress - star.delay) / (1 - star.delay)).clamp(0.0, 1.0);
      if (visible <= 0) continue;
      final paint = Paint()
        ..color = Colors.white.withOpacity(star.opacity * visible);
      canvas.drawCircle(
          Offset(star.x * size.width, star.y * size.height), star.r, paint);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.progress != progress;
}

class _Star {
  final double x, y, r, opacity, delay;
  const _Star({required this.x, required this.y, required this.r, required this.opacity, required this.delay});
}
