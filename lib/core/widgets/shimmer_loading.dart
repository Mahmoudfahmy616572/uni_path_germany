// lib/core/widgets/shimmer_loading.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShimmerLoading extends StatefulWidget {
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
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius.r),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                0.0,
                _animation.value,
                1.0,
              ],
            ),
          ),
        );
      },
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