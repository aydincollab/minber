import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../models/hutbe.dart';

class FeaturedHutbeCard extends StatefulWidget {
  final Hutbe? hutbe;
  final VoidCallback? onTap;

  const FeaturedHutbeCard({
    super.key,
    this.hutbe,
    this.onTap,
  });

  @override
  State<FeaturedHutbeCard> createState() => _FeaturedHutbeCardState();
}

class _FeaturedHutbeCardState extends State<FeaturedHutbeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hutbe == null) return _buildPlaceholder();

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: AppColors.gold.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.5, 1.0],
                  colors: [
                    Color(0xFF1B6B42), // rich emerald
                    Color(0xFF14532D), // deep emerald
                    Color(0xFF0D3B20), // darkest emerald
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Decorative golden arc top-right
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.25),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -10,
                    right: -10,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold.withOpacity(0.08),
                      ),
                    ),
                  ),

                  // Mosque emoji — faded watermark
                  const Positioned(
                    right: 12,
                    bottom: 0,
                    child: Text(
                      '🕌',
                      style: TextStyle(fontSize: 90, height: 1),
                    ),
                  ),
                  // mask the emoji with opacity
                  Positioned(
                    right: 12,
                    bottom: 0,
                    child: Container(
                      width: 110,
                      height: 110,
                      color: const Color(0xFF14532D).withOpacity(0.55),
                    ),
                  ),

                  // Shimmer line at top
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.gold,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // "Bu Haftanın Hutbesi" badge
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.gold, AppColors.goldLight],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🌙', style: TextStyle(fontSize: 11)),
                          SizedBox(width: 5),
                          Text(
                            'Bu Haftanın Hutbesi',
                            style: TextStyle(
                              color: AppColors.dark,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content — bottom aligned
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 32, 100, 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date + reading time row
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                DateFormat('dd MMMM yyyy', 'tr_TR')
                                    .format(widget.hutbe!.date),
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.menu_book_rounded,
                                size: 12,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.hutbe!.readingTimeMinutes ?? 5} dk',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Title
                          Text(
                            widget.hutbe!.title,
                            style: const TextStyle(
                              fontFamily: 'Playfair Display',
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 10),

                          // Read button
                          Row(
                            children: [
                              Text(
                                'Hutbeyi Oku',
                                style: TextStyle(
                                  color: AppColors.gold.withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 11,
                                color: AppColors.gold.withOpacity(0.9),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B6B42),
            Color(0xFF0D3B20),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🕌', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(
              'Bu Haftanın Hutbesi',
              style: TextStyle(
                color: AppColors.gold.withOpacity(0.9),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Yükleniyor...',
              style: TextStyle(
                color: AppColors.textMuted.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
