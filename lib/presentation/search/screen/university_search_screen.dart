import 'dart:async';

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
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
                    ShimmerText(lines: 2, height: 18.h, spacing: 12.h),
                    SizedBox(height: 24.h),
                    ShimmerCard(height: 50.h, borderRadius: 12.r),
                    SizedBox(height: 16.h),
                    ShimmerCard(height: 50.h, borderRadius: 12.r),
                    SizedBox(height: 16.h),
                    ShimmerCard(height: 50.h, borderRadius: 12.r),
                    SizedBox(height: 24.h),
                    ShimmerText(lines: 3, height: 14.h, spacing: 8.h),
                    SizedBox(height: 16.h),
                    ...List.generate(3, (i) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: ShimmerCard(height: 80.h, borderRadius: 16.r),
                    )),
                  ],
                ),
              );
            }

            if (state is UniversitySearchError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48.sp, color: Colors.red[300]),
                      SizedBox(height: 16.h),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 24.h),
                      ElevatedButton.icon(
                        onPressed: () => context.read<UniversitySearchCubit>().updateFilters(),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(AppLocalizations.of(context).translate('retry')),
                      ),
                    ],
                  ),
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
                  RefreshIndicator(
                    onRefresh: context.read<UniversitySearchCubit>().refresh,
                    color: const Color(0xFF6366F1),
                    child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
        onChanged: (val) {
          _searchDebounce?.cancel();
          _searchDebounce = Timer(
            const Duration(milliseconds: 300),
            () => context.read<UniversitySearchCubit>().updateFilters(query: val),
          );
        },
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).translate('searchForCourses'),
          prefixIcon: Icon(Icons.search, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14.h),
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
    final selectedIds = <String>{};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
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
              if (selectedIds.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    '${selectedIds.length} selected — tap Compare to view side-by-side',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.primary),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16.r),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final uni = results[index];
                    final isSelected = selectedIds.contains(uni.id);
                    return Card(
                      child: ListTile(
                        tileColor: context.isDark ? AppColors.darkCardBg : Colors.white,
                        onTap: () =>
                            context.push('/university_details', extra: uni),
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (v) {
                            setSheetState(() {
                              if (v == true) {
                                selectedIds.add(uni.id);
                              } else {
                                selectedIds.remove(uni.id);
                              }
                            });
                          },
                          activeColor: const Color(0xFF6366F1),
                        ),
                        title: Text(
                          uni.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${uni.programs.length} Matching Programs',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScoreText(
                              score: uni.matchPercentage,
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isSelected)
                              Padding(
                                padding: EdgeInsets.only(left: 8.w),
                                child: Icon(Icons.check_circle, color: AppColors.primary, size: 18.sp),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (selectedIds.length >= 2)
                Padding(
                  padding: EdgeInsets.all(16.r),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final selected = results.where((u) => selectedIds.contains(u.id)).toList();
                        Navigator.pop(context);
                        context.push('/compare', extra: selected);
                      },
                      icon: Icon(Icons.compare_arrows, size: 18.sp),
                      label: Text('Compare ${selectedIds.length} Universities'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
