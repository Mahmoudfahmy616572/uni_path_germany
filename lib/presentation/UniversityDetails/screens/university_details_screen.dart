import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/services_locator.dart';
import '../../../data/models/university_model.dart';
import '../../../domain/repositories/applications_repository.dart';
import '../cubit/university_details_cubit.dart';
import '../widgets/about_program_section.dart';
import '../widgets/admission_analysis_tables.dart';
import '../widgets/custom_category_bar.dart'; // الـ Bar الجديد
import '../widgets/details_header.dart';
import '../widgets/notes_section.dart';
import '../widgets/premium_match_progress_bar.dart';
import '../widgets/quick_info_metrics.dart';
import '../widgets/sticky_bottom_bar.dart';
// استدعاء كافة الـ Widgets (الكاوتشات المنفصلة) لضمان عدم النقصان
import '../widgets/university_image_carousel.dart';
import '../widgets/university_stats_section.dart';

class UniversityDetailsScreen extends StatefulWidget {
  final UniversityModel university;

  const UniversityDetailsScreen({super.key, required this.university});

  @override
  State<UniversityDetailsScreen> createState() =>
      _UniversityDetailsScreenState();
}

class _UniversityDetailsScreenState extends State<UniversityDetailsScreen> {
  // الخانات الأربعة كاملة دون نقصان أي واحدة
  final List<String> _tabs = ['Overview', 'Curriculum', 'Checklist', 'Notes'];
  int _currentSelectionIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool initialSavedCheck =
        widget.university.status == 'saved' ||
        widget.university.status == 'preparing' ||
        widget.university.status == 'applied';

    final List<String> images =
        widget.university.logoUrl != null &&
            widget.university.logoUrl!.isNotEmpty
        ? [widget.university.logoUrl!]
        : ['broken_link_to_trigger_errorBuilder'];

    return BlocProvider(
      create: (context) =>
          UniversityDetailsCubit(sl<ApplicationsRepository>())
            ..checkInitialSaveStatus(widget.university.id),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: CustomScrollView(
          slivers: [
            // الكاروسيل العلوي الثابت بالـ Sliver مع معالجة حماية الـ Red X
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF0F172A),
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: UniversityImageCarousel(
                  images: images,
                  university: widget.university,
                ),
              ),
            ),

            // محتوى الشاشة الديناميكي
            SliverPadding(
              padding: const EdgeInsets.all(24.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  DetailsHeader(university: widget.university),
                  const SizedBox(height: 20),

                  QuickInfoMetrics(university: widget.university),
                  const SizedBox(height: 24),

                  // 🔥 استدعاء الـ Bar الجديد بالشكل المطابق للصورة تماماً
                  CustomCategoryBar(
                    tabs: _tabs,
                    selectedIndex: _currentSelectionIndex,
                    onTabSelected: (index) {
                      setState(() {
                        _currentSelectionIndex = index;
                      });
                    },
                  ),
                  const SizedBox(height: 28),

                  // عرض الداتا بالكامل بناءً على البار المختار
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildDynamicContent(),
                  ),

                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
        bottomNavigationBar: StickyBottomBar(
          university: widget.university,
          initialSavedCheck: initialSavedCheck,
        ),
      ),
    );
  }

  // فرز وعرض الأقسام بالكامل وبنفس محتواها دون نقصان
  // فرز وعرض الأقسام بعد نقل البار وإضافة جداول التحليل
  Widget _buildDynamicContent() {
    switch (_currentSelectionIndex) {
      case 0: // Overview (شيلنا البار من هنا)
        return Column(
          key: const ValueKey(0),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AboutProgramSection(description: widget.university.description),
            const SizedBox(height: 24),
            UniversityStatsSection(
              uniName: widget.university.name,
              qsRanking: widget.university.rankings,
            ),
          ],
        );
      case 1: // Curriculum
        return Column(
          key: const ValueKey(1),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Program Curriculum',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                widget.university.curriculum ??
                    "No custom curriculum details provided for this track yet.",
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
            ),
          ],
        );
      case 2: // Checklist (هنا حطينا البار والجدولين سوا)
        return Column(
          key: const ValueKey(2),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. بار النسبة المئوية المطور
            PremiumMatchProgressBar(
              totalScore: widget.university.matchPercentage,
            ),
            const SizedBox(height: 16),

            // 2. 🔥 جدولين التحليل جمب بعض لشرح تفاصيل النسبة
            AdmissionAnalysisTables(university: widget.university),
            const SizedBox(height: 28),

            // 3. قائمة المتطلبات التفاعلية الاصلية
          ],
        );
      case 3: // Notes
        return NotesSection(
          key: const ValueKey(3),
          university: widget.university,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
