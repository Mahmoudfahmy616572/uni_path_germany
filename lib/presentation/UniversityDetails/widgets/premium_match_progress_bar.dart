import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/animated_match_score.dart';

class PremiumMatchProgressBar extends StatelessWidget {
  final int totalScore;
  final bool isPremium;

  const PremiumMatchProgressBar({
    super.key,
    required this.totalScore,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    // حساب النسب بدقة من أصل 100%
    final int academicEarned = totalScore.clamp(0, 80);
    final int academicMissed = 80 - academicEarned;
    const int premiumLocked = 20; // الـ 20% الخاصة بالـ AI

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // هيدر بسيط وأنيق فوق البار
        Text(
          'Admission Chance Evaluation',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 12.h),

        // 📊 البار الذكي والنصوص جواه
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: SizedBox(
            height: 28.h, // كبرنا الارتفاع عشان النص يظهر براحته
            child: Row(
              children: [
                // 🟢 الجزء الأخضر: التقييم الأكاديمي الحالي للطالب
                if (academicEarned > 0)
                  Expanded(
                    flex: academicEarned,
                    child: Container(
                      color: const Color(0xFF10B981),
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Academic Match (',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              AnimatedScoreText(
                                score: academicEarned,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                ')',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // ⚪ الجزء الرمادي الفاتح: المتبقي من التقييم الأكاديمي (لو الطالب منقص درجات)
                if (academicMissed > 0)
                  Expanded(
                    flex: academicMissed,
                    child: Container(
                      color: const Color(0xFFF1F5F9), // رمادي ناعم جداً
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '', // سيبناه فاضي عشان الشكل الجمالي، أو ممكن تكتب (-)
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // 🔒 الجزء المقفول/المفتوح: الـ 20% الخاصة بالـ AI
                Expanded(
                  flex: premiumLocked,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isPremium ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                      border: Border(
                        left: BorderSide(
                          color: Colors.white,
                          width: 2.w,
                        ),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isPremium ? Icons.check_circle : Icons.lock,
                              size: 12.sp,
                              color: isPremium ? Colors.white : const Color(0xFF64748B),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              isPremium
                                  ? AppLocalizations.of(context).translate('unlocked')
                                  : 'AI Premium (20%)',
                              style: TextStyle(
                                color: isPremium ? Colors.white : const Color(0xFF64748B),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // ⚡ كارت التسويق السريع تحت البار مباشرة
        GestureDetector(
          onTap: () => context.push('/premium'),
          child: Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFEDE9FE)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 20.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPremium
                            ? AppLocalizations.of(context).translate('youArePremium')
                            : 'Want to unlock the remaining 20%?',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4C1D95),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        isPremium
                            ? AppLocalizations.of(context).translate('premiumFeatures')
                            : 'Optimize your CV & SOP via our AI Tailoring service to match this program.',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Color(0xFF6D28D9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12.sp,
                  color: Color(0xFF8B5CF6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
