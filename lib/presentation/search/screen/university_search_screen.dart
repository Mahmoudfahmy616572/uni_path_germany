import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/animated_match_score.dart';
import '../../../core/widgets/curtain_drop.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../domain/entities/university_entity.dart';
import '../cubit/university_search_cubit.dart';
import '../cubit/university_search_state.dart';
import '../widgets/advanced_filter_panel.dart';
import '../widgets/search_dropdowns_row.dart';

class UniversitySearchScreen extends StatefulWidget {
  const UniversitySearchScreen({super.key});

  @override
  State<UniversitySearchScreen> createState() => _UniversitySearchScreenState();
}

class _UniversitySearchScreenState extends State<UniversitySearchScreen> {
  final TextEditingController _textSearchController = TextEditingController();

  @override
  void dispose() {
    _textSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UniversitySearchCubit()..updateFilters(query: ''),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            AppLocalizations.of(context).translate('studyInGermany'),
            style: GoogleFonts.poppins(
              color: context.isDark ? AppColors.textMain : const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<UniversitySearchCubit, UniversitySearchState>(
          builder: (context, state) {
            if (state is UniversitySearchLoading) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                child: Column(
                  children: [
                    ShimmerText(lines: 2, height: 18, spacing: 12),
                    SizedBox(height: 24.h),
                    ShimmerCard(height: 50, borderRadius: 12),
                    SizedBox(height: 16.h),
                    ShimmerCard(height: 50, borderRadius: 12),
                    SizedBox(height: 16.h),
                    ShimmerCard(height: 50, borderRadius: 12),
                    SizedBox(height: 24.h),
                    ShimmerText(lines: 3, height: 14, spacing: 8),
                    SizedBox(height: 16.h),
                    ...List.generate(3, (i) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: ShimmerCard(height: 80, borderRadius: 16),
                    )),
                  ],
                ),
              );
            }

            if (state is UniversitySearchLoaded) {
              final int totalProgramsCount = state.filteredResults.fold(
                0,
                (sum, uni) => sum + uni.programs.length,
              );

              return Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                    child: Column(
                      children: [
                        CurtainDrop(
                          index: 0,
                          child: _buildSearchBar(context),
                        ),
                        SizedBox(height: 16.h),
                        // 🎯 تم تعديل هذا الـ Widget ليشمل اختيار الـ Intake
                        CurtainDrop(
                          index: 1,
                          child: SearchDropdownsRow(
                            currentIntake: state.selectedIntake,
                            currentDegree: state.selectedDegree,
                            currentMajor: state.selectedMajor,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        CurtainDrop(
                          index: 2,
                          child: AdvancedFilterPanel(
                            requiresIelts: state.requiresIelts,
                            maxTuition: state.maxTuition,
                            selectedLanguage: state.selectedLanguage,
                            acceptsMoi: state.acceptsMoi,
                            selectedLocation: state.selectedLocation,
                            availableLocations: context
                                .read<UniversitySearchCubit>()
                                .availableLocations,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildFloatingShowButton(
                    context,
                    totalProgramsCount,
                    state.filteredResults,
                  ),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _textSearchController,
        onChanged: (val) =>
            context.read<UniversitySearchCubit>().updateFilters(query: val),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).translate('searchForCourses'),
          prefixIcon: Icon(Icons.search, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFloatingShowButton(
    BuildContext context,
    int count,
    List<UniversityEntity> results,
  ) {
    return Positioned(
      bottom: 20.h,
      left: 16.w,
      right: 16.w,
      child: SizedBox(
        height: 54.h,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          onPressed: () => _showResultsBottomSheet(context, results),
          child: Text(
            'Show $count Available Programs',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showResultsBottomSheet(
    BuildContext context,
    List<UniversityEntity> results,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: context.isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 16.h),
            Text(
              '${results.length} ${AppLocalizations.of(context).translate('universitiesFound')}',
              style: TextStyle(fontWeight: FontWeight.bold, color: context.isDark ? AppColors.textMain : null),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16.r),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final uni = results[index];
                  return Card(
                    child: ListTile(
                      tileColor: context.isDark ? AppColors.darkCardBg : Colors.white,
                      onTap: () =>
                          context.push('/university_details', extra: uni),
                      title: Text(
                        uni.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${uni.programs.length} Matching Programs',
                      ),
                      trailing: AnimatedScoreText(
                        score: uni.matchPercentage,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
