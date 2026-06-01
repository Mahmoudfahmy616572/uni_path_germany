import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/build_notes_section.dart';
import '../../../../core/utils/quick_info_metrics.dart';
import '../../../../core/utils/requirements_check_list.dart';
import '../../../../data/models/university_model.dart';
import '../../cubit/my_applications_cubits.dart';

// 🎯 الدالة الخارجية المحدثة لتمرير الـ Cubit بشكل آمن للـ BottomSheet
void showApplicationDetailSheet(BuildContext context, UniversityModel app) {
  final myAppsCubit = context.read<MyApplicationsCubit>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => BlocProvider.value(
      value: myAppsCubit, // تغليف الـ BottomSheet بالـ Cubit الحالي
      child: ApplicationDetailSheet(app: app),
    ),
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
                QuickInfoMetrics(university: app),
                const SizedBox(height: 24),
                _buildRequirementChecklist(app),
                const SizedBox(height: 24),

                // 🎯 استدعاء قسم النوتس بدون تعديلات داخلية لأن الـ Context أصبح يرى الـ Cubit بفضل الـ .value
                BuildNotesSection(
                  university: app,
                  onSaveNotes: (String newNotes) async {
                    await context.read<MyApplicationsCubit>().updateNotesInList(
                      app.id,
                      newNotes,
                    );
                  },
                ),
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
            style: TextStyle(
              color: app.matchPercentage > 70
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementChecklist(UniversityModel app) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Requirements Checklist',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        RequirementsChecklistList(university: app),
      ],
    );
  }

  Widget _buildStickyFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
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
