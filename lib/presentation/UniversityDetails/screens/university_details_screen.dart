import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/services/services_locator.dart';
import '../../../core/utils/build_notes_section.dart';
import '../../../core/utils/quick_info_metrics.dart';
import '../../../data/models/university_model.dart';
import '../../../domain/repositories/applications_repository.dart';
import '../cubit/university_details_cubit.dart';
import '../cubit/university_details_state.dart';
import '../widgets/about_program_section.dart';
import '../widgets/admission_analysis_tables.dart';
import '../widgets/custom_category_bar.dart';
import '../widgets/details_header.dart';
import '../widgets/premium_match_progress_bar.dart';
import '../widgets/sticky_bottom_bar.dart';
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
      create: (context) => UniversityDetailsCubit(sl<ApplicationsRepository>())
        ..setInitialMatchPercentage(widget.university.matchPercentage)
        ..checkInitialSaveStatus(widget.university.id),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: Padding(
                padding: EdgeInsets.all(8.0),
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
              padding: EdgeInsets.all(24.r),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  DetailsHeader(university: widget.university),
                  SizedBox(height: 20.h),

                  QuickInfoMetrics(university: widget.university),
                  SizedBox(height: 24.h),

                  CustomCategoryBar(
                    tabs: _tabs,
                    selectedIndex: _currentSelectionIndex,
                    onTabSelected: (index) {
                      setState(() {
                        _currentSelectionIndex = index;
                      });
                    },
                  ),
                  SizedBox(height: 28.h),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildDynamicContent(),
                  ),

                  SizedBox(height: 40.h),
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

  Widget _buildDynamicContent() {
    switch (_currentSelectionIndex) {
      case 0:
        return Column(
          key: const ValueKey(0),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AboutProgramSection(description: widget.university.description),
            SizedBox(height: 24.h),
            UniversityStatsSection(
              uniName: widget.university.name,
              qsRanking: widget.university.rankings,
            ),
          ],
        );
      case 1:
        return Column(
          key: const ValueKey(1),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Program Curriculum',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                widget.university.curriculum ??
                    "No custom curriculum details provided for this track yet.",
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
            ),
          ],
        );
      case 2:
        return BlocBuilder<UniversityDetailsCubit, UniversityDetailsState>(
          builder: (context, state) {
            int displayPercentage = widget.university.matchPercentage;

            if (state is UniversitySaveStatus) {
              displayPercentage = state.matchPercentage;
            }

            return Column(
              key: const ValueKey(2),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PremiumMatchProgressBar(totalScore: displayPercentage),
                SizedBox(height: 16.h),
                AdmissionAnalysisTables(university: widget.university),
                SizedBox(height: 28.h),
              ],
            );
          },
        );
      case 3: // 🎯 قسم الـ Notes المطور والمحمي بالـ Builder
        return Builder(
          key: const ValueKey(3),
          builder: (innerContext) {
            return BuildNotesSection(
              university: widget.university,
              onSaveNotes: (String newNotes) async {
                // استخدام الـ innerContext لضمان رؤية الـ Cubit الموجود في الـ BlocProvider أعلاه
                await innerContext.read<UniversityDetailsCubit>().updateNotes(
                  universityId: widget.university.id,
                  newNotes: newNotes,
                );
              },
            );
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
