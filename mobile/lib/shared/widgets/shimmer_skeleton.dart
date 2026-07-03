import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_radius.dart';

class ShimmerSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2E3B52) : const Color(0xFFE5E7EB),
      highlightColor: isDark ? const Color(0xFF3F4E66) : const Color(0xFFF3F4F6),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ListingCardSkeleton extends StatelessWidget {
  const ListingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton matching 4:3
          Expanded(
            child: ShimmerSkeleton(
              width: double.infinity,
              height: double.infinity,
              borderRadius: AppRadius.input,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category overline skeleton
                const ShimmerSkeleton(width: 60, height: 10, borderRadius: 4),
                const SizedBox(height: AppSpacing.xxs),
                // Title line skeleton
                const ShimmerSkeleton(width: 110, height: 14, borderRadius: 4),
                const SizedBox(height: AppSpacing.xxs),
                // District location skeleton
                const ShimmerSkeleton(width: 80, height: 11, borderRadius: 4),
                const SizedBox(height: AppSpacing.xs),
                // Price skeleton
                const ShimmerSkeleton(width: 70, height: 13, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ListTileSkeleton extends StatelessWidget {
  const ListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          // Avatar/thumb circle skeleton
          const ShimmerSkeleton(width: 48, height: 48, borderRadius: AppRadius.full),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerSkeleton(width: 140, height: 14, borderRadius: 4),
                SizedBox(height: 6),
                ShimmerSkeleton(width: 220, height: 11, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
