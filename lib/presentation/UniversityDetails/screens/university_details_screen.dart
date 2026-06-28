import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:germany_travel/core/widgets/curtain_drop.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/services/services_locator.dart';
import '../../../core/utils/build_notes_section.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/quick_info_metrics.dart';
import '../../../domain/entities/program_entity.dart';
import '../../../domain/entities/university_entity.dart';
import '../../../domain/repositories/applications_repository.dart';
import '../cubit/university_details_cubit.dart';
import '../cubit/university_details_state.dart';
import '../widgets/about_program_section.dart';
import '../widgets/admission_analysis_tables.dart';
import '../widgets/custom_category_bar.dart';
import '../widgets/details_header.dart';
import '../widgets/premium_match_progress_bar.dart';
import '../widgets/program_card.dart';
import '../widgets/uni_pass_ai_sheet.dart';
import '../widgets/university_image_carousel.dart';

class UniversityDetailsScreen extends StatefulWidget {
  final UniversityEntity university;

  const UniversityDetailsScreen({super.key, required this.university});

  @override
  State<UniversityDetailsScreen> createState() =>
      _UniversityDetailsScreenState();
}

class _UniversityDetailsScreenState extends State<UniversityDetailsScreen> {
  int _currentSelectionIndex = 0;
  bool _isPremium = false;
  late final List<String> _images;

  @override
  void initState() {
    super.initState();
    _images = _buildImageList();
    _checkPremium();
  }

  List<String> _tabs(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return [
      loc.translate('overview'),
      loc.translate('curriculum'),
      loc.translate('checklist'),
      loc.translate('notes'),
    ];
  }

  List<String> _buildImageList() {
    bool isSvg(String url) =>
        url.endsWith('.svg') || url.contains('.svg?') || url.contains('.svg/');
    final list = <String>[];
    if (widget.university.imageUrl != null &&
        widget.university.imageUrl!.isNotEmpty &&
        !isSvg(widget.university.imageUrl!)) {
      list.add(widget.university.imageUrl!);
    }
    if (widget.university.logoUrl != null &&
        widget.university.logoUrl!.isNotEmpty &&
        !list.contains(widget.university.logoUrl!) &&
        !isSvg(widget.university.logoUrl!)) {
      list.add(widget.university.logoUrl!);
    }
    if (list.isEmpty) {
      list.add(
        'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?q=80&w=800',
      );
    }
    return list;
  }

  Future<void> _checkPremium() async {
    final premium = await sl<PremiumService>().isPremium();
    if (mounted) setState(() => _isPremium = premium);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UniversityDetailsCubit(sl<ApplicationsRepository>())
        ..initializeUniversityData(
          percentage: widget.university.matchPercentage,
          programs: widget.university.programs,
          university: widget.university,
        )
        ..checkInitialSaveStatus(widget.university.id),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // الهيدر مع الصورة المتحركة
            SliverAppBar(
              expandedHeight: 220.h,
              pinned: true,
              elevation: 0,
              leading: Padding(
                padding: EdgeInsets.all(8.r),
                child: CircleAvatar(
                  backgroundColor: context.isDark ? AppColors.darkCardBg : Colors.white,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: context.isDark ? AppColors.textMain : const Color(0xFF0F172A),
                      size: 20.r,
                    ),
                    onPressed: () {
                      final nav = Navigator.of(context);
                      if (nav.canPop()) nav.pop();
                    },
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: UniversityImageCarousel(
                  images: _images,
                  university: widget.university,
                ),
              ),
            ),

            // محتوى الصفحة
            SliverPadding(
              padding: EdgeInsets.all(24.r),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  CurtainDrop(
                    index: 0,
                    child: DetailsHeader(university: widget.university),
                  ),
                  SizedBox(height: 20.h),
                  CurtainDrop(
                    index: 1,
                    child: QuickInfoMetrics(university: widget.university),
                  ),
                  SizedBox(height: 24.h),

                  // شريط التبويب (Overview, Curriculum, etc.)
                  CurtainDrop(
                    index: 2,
                    child: CustomCategoryBar(
                      tabs: _tabs(context),
                      selectedIndex: _currentSelectionIndex,
                      onTabSelected: (index) {
                        setState(() => _currentSelectionIndex = index);
                      },
                    ),
                  ),
                  SizedBox(height: 28.h),

                  // المحتوى الديناميكي بناءً على التبويب المختار
                  CurtainDrop(
                    index: 3,
                    child: RepaintBoundary(
                      key: ValueKey('tab_$_currentSelectionIndex'),
                      child: _buildTabContent(),
                    ),
                  ),
                  SizedBox(height: 40.h),
                ]),
              ),
            ),
          ],
        ),
        bottomNavigationBar: CurtainDrop(
          index: 4,
          child: RepaintBoundary(child: _buildBottomActionBar()),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentSelectionIndex) {
      case 0: // Overview
        return BlocBuilder<UniversityDetailsCubit, UniversityDetailsState>(
          builder: (context, state) {
            final bool isFiltered = (state is UniversitySaveStatus)
                ? state.showOnlyRecommended
                : false;
            final List<ProgramEntity> displayPrograms =
                (state is UniversitySaveStatus)
                ? state.displayedPrograms
                : widget.university.programs;

            return Column(
              key: const ValueKey(0),
              children: [
                _buildRecommendationToggle(context, isFiltered),
                SizedBox(height: 16.h),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayPrograms.length,
                  itemBuilder: (context, index) {
                    return ProgramCard(
                      program: displayPrograms[index],
                      universityId: widget.university.id,
                    );
                  },
                ),
                SizedBox(height: 16.h),
                AboutProgramSection(description: widget.university.description),
              ],
            );
          },
        );
      case 1: // Curriculum
        final loc = AppLocalizations.of(context);
        return Column(
          key: const ValueKey(1),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('programCurriculum'),
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: context.isDark ? AppColors.darkCardBg : Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
              ),
              child: Text(
                widget.university.programs.isNotEmpty
                    ? (widget.university.programs.first.curriculum ??
                          loc.translate('noDetails'))
                    : loc.translate('noCurriculumData'),
                style: TextStyle(
                  fontSize: 13.sp,
                  color: context.isDark ? AppColors.textMuted : const Color(0xFF475569),
                  height: 1.5,
                ),
              ),
            ),
          ],
        );
      case 2: // Checklist (PDF Upload Section)
        return Column(
          key: const ValueKey(2),
          children: [
            PremiumMatchProgressBar(
              totalScore: widget.university.matchPercentage,
              isPremium: _isPremium,
            ),
            SizedBox(height: 24.h),
            AdmissionAnalysisTables(university: widget.university),
          ],
        );
      case 3: // Notes
        return BuildNotesSection(
          key: const ValueKey(3),
          university: widget.university,
          onSaveNotes: (newNotes) async {
            await context.read<UniversityDetailsCubit>().updateNotes(
              universityId: widget.university.id,
              newNotes: newNotes,
            );
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRecommendationToggle(BuildContext context, bool isFiltered) {
    return InkWell(
      onTap: () => context.read<UniversityDetailsCubit>().toggleProgramFilter(
        !isFiltered,
      ),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: isFiltered ? const Color(0xFFDCFCE7) : context.isDark ? AppColors.darkSurface : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isFiltered
                ? const Color(0xFFBBF7D0)
                : context.isDark ? AppColors.darkBorder : const Color(0xFFC7D2FE),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isFiltered ? Icons.filter_alt_off : Icons.auto_awesome,
              color: isFiltered
                  ? const Color(0xFF166534)
                  : const Color(0xFF4F46E5),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                AppLocalizations.of(context).translate('filterAiRecommended'),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: isFiltered ? const Color(0xFF166534) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkCardBg : Colors.white,
        border: Border(
          top: BorderSide(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => showUniPassAiSheet(context, widget.university),
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: Text(
                  AppLocalizations.of(context).translate('askUniPathAi'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  minimumSize: Size.fromHeight(56.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            if (widget.university.websiteUrl != null && widget.university.websiteUrl!.isNotEmpty) ...[
              SizedBox(width: 12.w),
              Container(
                height: 56.h,
                width: 56.w,
                decoration: BoxDecoration(
                  color: context.isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.language,
                    color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B),
                  ),
                  onPressed: () => launchUrl(Uri.parse(widget.university.websiteUrl!)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
