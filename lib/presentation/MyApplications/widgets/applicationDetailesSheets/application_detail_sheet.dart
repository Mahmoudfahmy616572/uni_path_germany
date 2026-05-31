import 'package:flutter/material.dart';

import '../../../../data/models/university_model.dart';

void showApplicationDetailSheet(BuildContext context, UniversityModel app) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ApplicationDetailSheet(app: app),
  );
}

class ApplicationDetailSheet extends StatelessWidget {
  final UniversityModel app;
  const ApplicationDetailSheet({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Stack(
        children: [
          // الـ Body القابل للإسكورل
          SingleChildScrollView(
            padding: const EdgeInsets.all(24).copyWith(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: SheetDragHandle()),
                const SizedBox(height: 16),
                _buildHeader(app),
                const SizedBox(height: 20),
                _buildQuickFinanceRow(app),
                const SizedBox(height: 24),
                _buildRequirementChecklist(app),
                const SizedBox(height: 24),
                _buildNotesSection(app),
              ],
            ),
          ),
          // زاوية التحكم السفلية الثابتة (الـ Action Buttons)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStickyFooter(context),
          ),
        ],
      ),
    );
  }

  // رأس الصفحة (الاسم والبرنامج والـ Match)
  Widget _buildHeader(UniversityModel app) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                app.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                app.program,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFECFDF5),
            shape: BoxShape.circle,
          ),
          child: Text(
            '${app.matchPercentage}%',
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // صف التمويل والتواريخ السريع
  Widget _buildQuickFinanceRow(UniversityModel app) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildFinanceItem('Deadline', '15 Jul 2026', 'In 18 days', Colors.red),
        _buildFinanceItem(
          'Application Fee',
          '€85',
          'Non-refundable',
          const Color(0xFF0F172A),
        ),
        _buildFinanceItem(
          'Tuition (Year)',
          '€0',
          'Semester fee only',
          const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildFinanceItem(
    String label,
    String value,
    String sub,
    Color valColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valColor,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  // قائمة الـ Checklist
  Widget _buildRequirementChecklist(UniversityModel app) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Requirements Checklist',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        ChecklistTile(
          title: 'Academic Transcripts',
          isCompleted: app.hasTranscripts,
        ),
        ChecklistTile(title: 'Bachelor Certificate', isCompleted: true),
        ChecklistTile(
          title: 'SOP / Motivation Letter',
          isCompleted: app.hasSop,
        ),
        ChecklistTile(title: 'CV / Resume', isCompleted: app.hasCv),
      ],
    );
  }

  // سيكشن الملاحظات
  Widget _buildNotesSection(UniversityModel app) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Notes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Edit',
                style: TextStyle(color: Color(0xFF4F46E5)),
              ),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: const Text(
            'Really interested in the curriculum and research opportunities. Need to improve my SOP and take IELTS.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // الـ Footer الثابت تحت الشاشة
  Widget _buildStickyFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      // border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF4F46E5)),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Update Status',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ويدجيت مقبض السحب العلوي للـ Sheet
class SheetDragHandle extends StatelessWidget {
  const SheetDragHandle({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ويدجيت الـ Checklist Tile المـعزولة
class ChecklistTile extends StatelessWidget {
  final String title;
  final bool isCompleted;

  const ChecklistTile({
    super.key,
    required this.title,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted
                ? const Color(0xFF10B981)
                : const Color(0xFFCBD5E1),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isCompleted
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF64748B),
            ),
          ),
          const Spacer(),
          Text(
            isCompleted ? 'Completed' : 'Missing',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isCompleted
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }
}
