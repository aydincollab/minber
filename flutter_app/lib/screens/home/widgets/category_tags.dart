import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class CategoryTags extends StatefulWidget {
  final Function(String)? onCategorySelected;

  const CategoryTags({super.key, this.onCategorySelected});

  @override
  State<CategoryTags> createState() => _CategoryTagsState();
}

class _CategoryTagsState extends State<CategoryTags> {
  String selectedCategory = 'Tümü';
  
  final List<String> categories = [
    'Tümü',
    'İman',
    'Aile',
    'Ahlak',
    'İbadet',
    'Toplum',
    'Oruç',
    'Hac',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isActive = category == selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory = category;
                });
                widget.onCategorySelected?.call(category);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.gold
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isActive
                          ? AppColors.dark
                          : AppColors.textMuted,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
