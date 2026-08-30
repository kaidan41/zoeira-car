import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zoeira_car/theme/app_colors.dart';

/// Caixa de shimmer reutilizável para estados de loading.
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Lista de ShimmerBox para simular cards em carregamento.
class ShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;
  final EdgeInsets padding;

  const ShimmerList({
    super.key,
    this.count = 5,
    this.itemHeight = 80,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: padding,
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => ShimmerBox(
        width: double.infinity,
        height: itemHeight,
        borderRadius: 14,
      ),
    );
  }
}
