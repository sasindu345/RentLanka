import 'package:flutter/material.dart';

class RentLankaLogo extends StatelessWidget {
  final double? height;
  final double? width;
  final double? fontSize;
  final Color? blendColor;
  final bool isDarkBackground;

  const RentLankaLogo({
    super.key,
    this.height,
    this.width,
    this.fontSize,
    this.blendColor,
    this.isDarkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final double computedHeight = height ?? fontSize ?? 40.0;
    final Color blendTarget = blendColor ?? const Color(0xFFFAFAFA);
    // Renders the official image logo asset from assets/images/image-logo.png
    return Image.asset(
      'assets/images/image-logo.png',
      height: computedHeight,
      width: width,
      fit: BoxFit.contain,
      color: blendTarget,
      colorBlendMode: BlendMode.multiply,
      errorBuilder: (context, error, stackTrace) {
        // Fallback typographic wordmark in case the asset is missing
        return RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
            ),
            children: [
              TextSpan(
                text: 'Rent',
                style: TextStyle(color: Color(0xFF111827)),
              ),
              TextSpan(
                text: 'Lanka',
                style: TextStyle(color: Color(0xFF4F46E5)),
              ),
            ],
          ),
        );
      },
    );
  }
}
