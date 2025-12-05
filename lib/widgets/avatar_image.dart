import 'package:flutter/material.dart';

/// A widget that displays an avatar image with error handling.
/// Falls back to initials if the image fails to load.
class AvatarImage extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final TextStyle? textStyle;

  const AvatarImage({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 30,
    this.backgroundColor,
    this.textColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).primaryColor;
    final txtColor = textColor ?? Colors.white;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    // If no image URL, show initials
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          initials,
          style: textStyle ??
              TextStyle(
                color: txtColor,
                fontSize: radius * 0.6,
                fontWeight: FontWeight.bold,
              ),
        ),
      );
    }

    // Try to load network image with error handling
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: ClipOval(
        child: Image.network(
          imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // If image fails to load, show initials
            return Container(
              width: radius * 2,
              height: radius * 2,
              color: bgColor,
              child: Center(
                child: Text(
                  initials,
                  style: textStyle ??
                      TextStyle(
                        color: txtColor,
                        fontSize: radius * 0.6,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            // Show loading indicator while image loads
            return Container(
              width: radius * 2,
              height: radius * 2,
              color: bgColor,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(txtColor),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

