import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MatchScoreCard extends StatelessWidget {
  final int score;

  const MatchScoreCard({super.key, required this.score});

  String get _statusText {
    if (score >= 80) return "Excellent Chance";
    if (score >= 60) return "Good Chance";
    if (score >= 40) return "Fair Chance";
    return "Needs Improvement";
  }

  Color get _statusColor {
    if (score >= 80) return const Color(0xFF4ADE80);
    if (score >= 60) return const Color(0xFF68D391);
    if (score >= 40) return const Color(0xFFF6E05E);
    return const Color(0xFFFC8181);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 180.h,
      ), // 🎯 استخدام constraints بدلاً من height ثابت
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 60.h,
              child: CustomPaint(painter: ChartWavePainter()),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(24.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize:
                        MainAxisSize.min, // 🎯 جعل العمود يأخذ أقل مساحة ممكنة
                    children: [
                      Text(
                        "Your Match Score",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        "$score%",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42.sp,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _statusText,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // 🎯 استخدام Flexible أو تقليل النص لمنع الـ Overflow
                      Text(
                        "You have ${score >= 50 ? 'good' : 'fair'} chances for most programs.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11.sp,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80.w,
                  height: 80.h,
                  child: CustomPaint(
                    painter: CircularProgressPainter(progress: score / 100),
                    child: Center(
                      child: Transform.rotate(
                        angle: pi / 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// باقي الـ Painters (Wave و Circular) يبقون كما هم دون تغيير
class CircularProgressPainter extends CustomPainter {
  final double progress;
  CircularProgressPainter({required this.progress});
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

class ChartWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    Path path = Path();
    path.moveTo(0, size.height * 0.8);

    // رسم تعرجات عشوائية بسيطة تشبه الـ Chart في الصورة
    path.quadraticBezierTo(
      size.width * 0.1,
      size.height * 0.5,
      size.width * 0.2,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.9,
      size.width * 0.4,
      size.height * 0.6,
    );

    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.3,
      size.width * 0.6,
      size.height * 0.8,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 1.0,
      size.width,
      size.height * 0.2,
    );
    canvas.drawPath(path, wavePaint);

    // إضافة النقطة اللي في آخر الـ Chart
    Paint dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(size.width, size.height * 0.2), 4, dotPaint);

    // تلوين خفيف تحت الـ Wave
    Paint fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    Path fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
