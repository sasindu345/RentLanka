import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/theme/app_theme.dart';

/// Network listing image with placeholder for missing/broken URLs (e.g. old S3 seed data).
class ListingImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ListingImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return _placeholder();
    }

    return CachedNetworkImage(
      imageUrl: resolveMediaUrl(url!),
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Center(
          child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    final isSmall = width != null && width! <= 60;
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Center(
        child: isSmall
            ? const Icon(Icons.image_outlined, size: 24, color: AppTheme.muted)
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 40, color: AppTheme.muted),
                  SizedBox(height: 8),
                  Text('No photo', style: TextStyle(color: AppTheme.muted, fontSize: 13)),
                ],
              ),
      ),
    );
  }
}
