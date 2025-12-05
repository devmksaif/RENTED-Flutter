import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class ImageCarousel extends StatefulWidget {
  final List<String> images;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;

  const ImageCarousel({
    required this.images,
    this.onFavoriteTap,
    this.isFavorite = false,
    super.key,
  });

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentPage = index);
          },
          itemCount: widget.images.length,
          itemBuilder: (context, index) {
            return Image.asset(
              widget.images[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            );
          },
        ),
        Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: widget.onFavoriteTap,
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.brightness == Brightness.dark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black12,
                    blurRadius: 8,
                  ),
                ],
              ),
              padding: EdgeInsets.all(12),
              child: Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: widget.isFavorite ? AppTheme.errorRed : theme.hintColor,
                size: 24,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.images.length,
              (index) => Container(
                width: _currentPage == index ? 12 : 8,
                height: 8,
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppTheme.primaryGreen
                      : theme.cardColor.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
