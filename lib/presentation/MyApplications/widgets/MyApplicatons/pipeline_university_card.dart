import 'package:flutter/material.dart';

import '../../../../data/models/university_model.dart';

class PipelineUniversityCard extends StatelessWidget {
  final UniversityModel app;
  final VoidCallback onTap;

  const PipelineUniversityCard({
    super.key,
    required this.app,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // حسبة الـ Progress
    int docsCount = [
      app.hasTranscripts,
      app.hasCv,
      app.hasSop,
      app.hasBachelorCert,
    ].where((c) => c).length;
    double progress = docsCount / 4;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // السطر العلوي: اللوجو والاسم والنسبة
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      app.logoText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          app.program,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildMatchBadge(app.matchPercentage),
                ],
              ),
              const SizedBox(height: 16),

              // الـ Deadlines والـ Missing Docs سريعا
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetaInfo(
                    Icons.calendar_today,
                    '15 Jul 2026',
                    'In 18 days',
                    Colors.red,
                  ),
                  _buildMetaInfo(
                    Icons.assignment_outlined,
                    'Missing',
                    app.hasBachelorCert ? 'None' : 'Bachelor Certificate',
                    const Color(0xFF4F46E5),
                  ),
                  _buildMetaInfo(
                    Icons.trending_up,
                    'Chance',
                    'High',
                    const Color(0xFF10B981),
                  ),
                ],
              ),

              // الـ AI Recommendation Banner الذكي
              if (!app.hasSop) ...[
                const SizedBox(height: 12),
                _buildAiSuggestionBanner(
                  "Improving your SOP could increase your chances by 10%.",
                ),
              ],

              const Divider(height: 24, color: Color(0xFFF1F5F9)),

              // أزرار التحكم السفلية للكارد
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF4F46E5),
                        size: 18,
                      ),
                      onPressed: () {}, // Ask AI Button
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchBadge(int match) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 42,
          height: 42,
          child: CircularProgressIndicator(
            value: match / 100,
            backgroundColor: const Color(0xFFF1F5F9),
            color: const Color(0xFF10B981),
            strokeWidth: 4,
          ),
        ),
        Text(
          '$match%',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaInfo(IconData icon, String title, String sub, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 18.0),
          child: Text(
            sub,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiSuggestionBanner(String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF4F46E5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: Color(0xFF4F46E5),
          ),
        ],
      ),
    );
  }
}
