import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/animated_match_score.dart';

class MatchScoreCard extends StatelessWidget {
  final int score;
  final VoidCallback? onAiTap;

  const MatchScoreCard({super.key, required this.score, this.onAiTap});

  String _statusText(AppLocalizations t) {
    if (score >= 80) return t.translate('excellentChance');
    if (score >= 60) return "Good Chance";
    if (score >= 40) return t.translate('fairChance');
    return t.translate('needsImprovement');
  }

  Color get _statusColor {
    if (score >= 80) return const Color(0xFF4ADE80);
    if (score >= 60) return const Color(0xFF68D391);
    if (score >= 40) return const Color(0xFFF6E05E);
    return const Color(0xFFFC8181);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 180.h,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 15.r,
            offset: Offset(0, 8.r),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.translate('yourMatchScore'),
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      AnimatedScoreText(
                        score: score,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42.sp,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _statusText(t),
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "You have ${score >= 50 ? 'good' : 'fair'} chances for most programs.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11.sp,
                          height: 1.4,
                        ),
                      ),
                      if (onAiTap != null) ...[
                        SizedBox(height: 10.h),
                        SizedBox(
                          height: 32.h,
                          child: ElevatedButton.icon(
                            onPressed: onAiTap,
                            icon: Icon(Icons.auto_awesome, size: 14.sp),
                            label: Text(
                              t.translate('aiTips'),
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: 80.w,
                  height: 80.h,
                  child: AnimatedCircularScore(score: score),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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

    Paint dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(size.width, size.height * 0.2), 4, dotPaint);

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
