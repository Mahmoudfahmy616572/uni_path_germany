import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AnimatedScoreText extends StatelessWidget {
  final int score;
  final TextStyle? style;

  const AnimatedScoreText({super.key, required this.score, this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score.toDouble()),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          '${value.round()}%',
          style: style,
        );
      },
    );
  }
}

class AnimatedCircularScore extends StatelessWidget {
  final int score;

  const AnimatedCircularScore({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score / 100),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return CustomPaint(
          painter: _CircularProgressPainter(progress: value),
          child: Center(
            child: Transform.rotate(
              angle: pi / 4,
              child: Container(
                width: 8.r,
                height: 8.r,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  _CircularProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = min(size.width / 2, size.height / 2);
    Paint backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0;
    canvas.drawCircle(center, radius, backgroundPaint);
    Paint progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10.0;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
