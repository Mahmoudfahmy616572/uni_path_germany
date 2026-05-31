import 'package:flutter/material.dart';

class PremiumMatchProgressBar extends StatelessWidget {
  final int totalScore; // النسبة الكلية القادمة من الـ Repository

  const PremiumMatchProgressBar({super.key, required this.totalScore});

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
        const Text(
          'Admission Chance Evaluation',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),

        // 📊 البار الذكي والنصوص جواه
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 28, // كبرنا الارتفاع عشان النص يظهر براحته
            child: Row(
              children: [
                // 🟢 الجزء الأخضر: التقييم الأكاديمي الحالي للطالب
                if (academicEarned > 0)
                  Expanded(
                    flex: academicEarned,
                    child: Container(
                      color: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit
                              .scaleDown, // تصغير الخط تلقائياً لو المساحة ضيقة
                          child: Text(
                            'Academic Match ($academicEarned%)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
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
                      child: const Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '', // سيبناه فاضي عشان الشكل الجمالي، أو ممكن تكتب (-)
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // 🔒 الجزء المقفول: الـ 20% الخاصة بالـ AI والخدمة المدفوعة
                Expanded(
                  flex: premiumLocked,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFE2E8F0), // رمادي أغمق ليوحي بالقفل
                      border: Border(
                        left: BorderSide(
                          color: Colors.white,
                          width: 2,
                        ), // فاصل شيك جداً
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.lock,
                              size: 12,
                              color: Color(0xFF64748B),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'AI Premium (20%)',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
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

        const SizedBox(height: 16),

        // ⚡ كارت التسويق السريع تحت البار مباشرة
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEDE9FE)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFF8B5CF6),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Want to unlock the remaining 20%?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4C1D95),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Optimize your CV & SOP via our AI Tailoring service to match this program.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF6D28D9)),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Color(0xFF8B5CF6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
