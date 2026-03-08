import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/constants.dart';

/// Wraps a grey placeholder box in a shimmer effect.
class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    this.width = double.infinity,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A single shimmer list tile that mimics a Card + ListTile layout.
class SkeletonListTile extends StatelessWidget {
  final bool showSubtitle2;

  const SkeletonListTile({super.key, this.showSubtitle2 = false});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: Colors.grey.shade100,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const _ShimmerBox(width: 44, height: 44, radius: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: MediaQuery.of(context).size.width * 0.45, height: 14),
                    const SizedBox(height: 8),
                    _ShimmerBox(width: MediaQuery.of(context).size.width * 0.6, height: 11),
                    if (showSubtitle2) ...[
                      const SizedBox(height: 6),
                      _ShimmerBox(width: MediaQuery.of(context).size.width * 0.4, height: 11),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  const _ShimmerBox(width: 56, height: 14),
                  const SizedBox(height: 6),
                  const _ShimmerBox(width: 40, height: 11),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders [count] shimmer list-tile skeletons.
class SkeletonList extends StatelessWidget {
  final int count;
  final bool showSubtitle2;

  const SkeletonList({super.key, this.count = 6, this.showSubtitle2 = false});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      itemBuilder: (_, __) => SkeletonListTile(showSubtitle2: showSubtitle2),
    );
  }
}

/// A shimmer summary card (used at tops of finance screens).
class SkeletonSummaryCard extends StatelessWidget {
  const SkeletonSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: double.infinity,
        height: 90,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
