import 'dart:math';

import 'package:flutter/material.dart';

class MatchScoreCard extends StatelessWidget {
  final int score;

  const MatchScoreCard({super.key, required this.score});

  // دالة عشان تحدد حالة القبول بناءً على النسبة
  String get _statusText {
    if (score >= 80) return "Excellent Chance";
    if (score >= 60) return "Good Chance";
    if (score >= 40) return "Fair Chance";
    return "Needs Improvement";
  }

  // دالة عشان تحدد لون النص بتاع الحالة
  Color get _statusColor {
    if (score >= 80) return const Color(0xFF4ADE80); // أخضر فاتح
    if (score >= 60) return const Color(0xFF68D391); // أخضر
    if (score >= 40) return const Color(0xFFF6E05E); // أصفر
    return const Color(0xFFFC8181); // أحمر
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180, // ثبتنا الطول عشان الـ Chart اللي تحت يظبط
      clipBehavior: Clip.antiAlias, // عشان الـ Wave ماتخرجش برا الحواف
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1), // اللون البنفسجي/الأزرق بتاع الديزاين
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 1. Chart Wave Background (الرسمة اللي تحت)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 60,
              child: CustomPaint(painter: ChartWavePainter()),
            ),
          ),

          // 2. المحتوى الأساسي (النصوص والدايرة)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // الجزء اللي على الشمال (النصوص)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Your Match Score",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$score%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _statusText,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Keep improving! You have good\nchances for most programs.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // الجزء اللي على اليمين (الدايرة الـ Dynamic)
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CustomPaint(
                    painter: CircularProgressPainter(progress: score / 100),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape
                              .rectangle, // المربع الصغير اللي في نص الدايرة
                        ),
                        transform: Matrix4.rotationZ(
                          pi / 4,
                        ), // لفيناه عشان يبقى زي النجمة/المعين
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

// ==========================================
// Custom Painter for Dynamic Circular Progress
// ==========================================
class CircularProgressPainter extends CustomPainter {
  final double progress; // نسبة من 0.0 لـ 1.0

  CircularProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = min(size.width / 2, size.height / 2);
    double strokeWidth = 12.0;

    // 1. رسم الدايرة الخلفية الشفافة
    Paint backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, backgroundPaint);

    // 2. رسم نسبة التقدم (Progress Arc)
    Paint progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap
          .round // عشان أطراف الدايرة تكون ناعمة
      ..strokeWidth = strokeWidth;

    // بنبدأ من فوق (-pi / 2) ونرسم الزاوية بناءً على النسبة
    double sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress; // تحديث الرسمة لو النسبة اتغيرت
  }
}

// ==========================================
// Custom Painter for Chart Wave Background
// ==========================================
class ChartWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
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
      size.height * 1.2,
      size.width * 0.85,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.95,
      size.height * 0.1,
      size.width,
      size.height * 0.2,
    );

    canvas.drawPath(path, wavePaint);

    // إضافة النقطة اللي في آخر الـ Chart
    Paint dotPaint = Paint()..color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(Offset(size.width, size.height * 0.2), 4, dotPaint);

    // تلوين خفيف تحت الـ Wave
    Paint fillPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
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
