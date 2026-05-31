import 'package:flutter/material.dart';

import '../../../data/models/university_model.dart';

class DetailsHeader extends StatelessWidget {
  final UniversityModel university;
  const DetailsHeader({super.key, required this.university});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. حاوية اللوجو مع معالجة الخطأ تماماً لمنع الـ Red X
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9), // خلفية رمادية هادية
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          clipBehavior: Clip.antiAlias,
          child: university.logoUrl != null && university.logoUrl!.isNotEmpty
              ? Image.network(
                  university.logoUrl!,
                  fit: BoxFit.cover,
                  // في حالة التحميل بنجاح أو الانتظار
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  // 🔥 هنا السحر: لو الصورة باظت أو اختفت، ميعرضش إيرور بل يعرض الـ Text البديل
                  errorBuilder: (context, error, stackTrace) =>
                      _buildFallbackLogo(),
                )
              : _buildFallbackLogo(),
        ),
        const SizedBox(width: 16),

        // 2. اسم الجامعة والبرنامج
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                university.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                university.program.isNotEmpty
                    ? university.program
                    : "Master's Program",
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (university.location != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      university.location!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),

        // 3. دائرة الـ Match Percentage
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                value: university.matchPercentage / 100,
                backgroundColor: const Color(0xFFDCFCE7),
                color: const Color(0xFF10B981),
                strokeWidth: 4,
              ),
            ),
            Text(
              '${university.matchPercentage}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF15803D),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // الـ Widget الاحتياطي اللي هيظهر لو الصورة مش موجودة
  Widget _buildFallbackLogo() {
    return Center(
      child: Text(
        university.logoText.isNotEmpty ? university.logoText : "UNI",
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4F46E5), // لون براند أنيق
        ),
      ),
    );
  }
}
