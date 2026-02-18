import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class YearSlideCards extends StatefulWidget {
  final List<Map<String, dynamic>> years;
  final Function(int)? onYearTap;

  const YearSlideCards({
    super.key,
    required this.years,
    this.onYearTap,
  });

  @override
  State<YearSlideCards> createState() => _YearSlideCardsState();
}

class _YearSlideCardsState extends State<YearSlideCards> {
  final PageController _pageController = PageController(viewportFraction: 0.45);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.years.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.years.length,
            itemBuilder: (context, index) {
              final yearData = widget.years[index];
              return _buildYearCard(yearData, index);
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildDotIndicator(),
      ],
    );
  }

  Widget _buildYearCard(Map<String, dynamic> yearData, int index) {
    final year = yearData['year'] as int;
    final count = yearData['count'] as int;
    
    final gradients = [
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1a3d2b), Color(0xFF0d2019)],
      ), // 2024 - green
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2d1a0d), Color(0xFF1a0d06)],
      ), // 2023 - brown
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0d1f3c), Color(0xFF060d1a)],
      ), // 2022 - blue
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1f0d2d), Color(0xFF0d061a)],
      ), // 2021 - purple
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1a1f0d), Color(0xFF0d1006)],
      ), // 2020 - olive
    ];

    final accents = [
      AppColors.gold,
      const Color(0xFFFF8C42),
      const Color(0xFF4A90E2),
      const Color(0xFFB565D8),
      const Color(0xFF9BC53D),
    ];

    final emojis = ['🌟', '📚', '📖', '📝', '📜'];

    final gradient = gradients[index % gradients.length];
    final accent = accents[index % accents.length];
    final emoji = emojis[index % emojis.length];

    return GestureDetector(
      onTap: () => widget.onYearTap?.call(year),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 160,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Accent circle
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const Spacer(),
                  
                  // Bottom gradient overlay
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Year
                        Text(
                          year.toString(),
                          style: TextStyle(
                            color: accent,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Count
                        Row(
                          children: [
                            const Text('📄', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              '$count hutbe',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.years.length,
        (index) {
          final isActive = index == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? AppColors.gold : AppColors.textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        },
      ),
    );
  }
}
