import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerWidget extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const ShimmerWidget.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
  }) : shapeBorder = const RoundedRectangleBorder();

  const ShimmerWidget.circular({
    super.key,
    required this.width,
    required this.height,
    this.shapeBorder = const CircleBorder(),
  });

  ShimmerWidget.rounded({
    super.key,
    this.width = double.infinity,
    required this.height,
    double borderRadius = 8,
  }) : shapeBorder = RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(borderRadius),
       );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(color: baseColor, shape: shapeBorder),
      ),
    );
  }
}

class ListShimmer extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ListShimmer({super.key, this.itemCount = 10, this.itemHeight = 72});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const ShimmerWidget.circular(width: 50, height: 50),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerWidget.rectangular(height: 16, width: 150),
                    const SizedBox(height: 8),
                    const ShimmerWidget.rectangular(height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TableShimmer extends StatelessWidget {
  final int rows;
  final int columns;

  const TableShimmer({super.key, this.rows = 5, this.columns = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(rows, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: List.generate(columns, (colIndex) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: const ShimmerWidget.rectangular(height: 20),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class CardShimmer extends StatelessWidget {
  const CardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerWidget.rectangular(height: 150),
          const SizedBox(height: 16),
          const ShimmerWidget.rectangular(height: 20, width: 200),
          const SizedBox(height: 8),
          const ShimmerWidget.rectangular(height: 14),
        ],
      ),
    );
  }
}

class SidebarShimmer extends StatelessWidget {
  const SidebarShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(8, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const ShimmerWidget.rectangular(width: 24, height: 24),
              const SizedBox(width: 16),
              const ShimmerWidget.rectangular(height: 16, width: 120),
            ],
          ),
        );
      }),
    );
  }
}

class CircleShimmer extends StatelessWidget {
  final double size;
  const CircleShimmer({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return ShimmerWidget.circular(width: size, height: size);
  }
}

class BusinessProfileShimmer extends StatelessWidget {
  const BusinessProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const ShimmerWidget.circular(width: 160, height: 160),
          const SizedBox(height: 32),
          const ShimmerWidget.rectangular(height: 50),
          const SizedBox(height: 24),
          const ShimmerWidget.rectangular(height: 50),
          const SizedBox(height: 24),
          const ShimmerWidget.rectangular(height: 120),
          const SizedBox(height: 24),
          const ShimmerWidget.rectangular(height: 50),
        ],
      ),
    );
  }
}
