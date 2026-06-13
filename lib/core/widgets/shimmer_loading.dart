import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
    this.height = 20,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    return Container(
      height: height.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius.r),
        color: Colors.grey[300],
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double borderRadius;
  final EdgeInsets? padding;

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 120,
    this.borderRadius = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: ShimmerLoading(
            isLoading: true,
            height: itemHeight,
            borderRadius: borderRadius,
            child: Container(),
          ),
        );
      },
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;

  const ShimmerCard({
    super.key,
    this.height = 100,
    this.width = double.infinity,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      isLoading: true,
      height: height,
      borderRadius: borderRadius,
      child: Container(),
    );
  }
}

class ShimmerText extends StatelessWidget {
  final int lines;
  final double height;
  final double width;
  final double spacing;

  const ShimmerText({
    super.key,
    this.lines = 3,
    this.height = 16,
    this.width = double.infinity,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        lines,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: spacing.h),
          child: ShimmerLoading(
            isLoading: true,
            height: height,
            borderRadius: 8,
            child: Container(
              width: index == lines - 1 ? width * 0.6 : width,
            ),
          ),
        ),
      ),
    );
  }
}
