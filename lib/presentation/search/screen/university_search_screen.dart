import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Study in Germany',
            style: GoogleFonts.poppins(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<UniversitySearchCubit, UniversitySearchState>(
          builder: (context, state) {
            if (state is UniversitySearchLoading)
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              );

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
                        _buildSearchBar(context),
                        SizedBox(height: 16.h),
                        // 🎯 تم تعديل هذا الـ Widget ليشمل اختيار الـ Intake
                        SearchDropdownsRow(
                          currentIntake: (state)
                              .selectedCountry, // استخدمنا الحقل مؤقتاً لتمرير الـ Intake
                          currentDegree: state.selectedDegree,
                          currentMajor: state.selectedMajor,
                        ),
                        SizedBox(height: 20.h),
                        AdvancedFilterPanel(
                          requiresIelts: state.requiresIelts,
                          maxTuition: state.maxTuition,
                          selectedLanguage: state.selectedLanguage,
                          acceptsMoi: state.acceptsMoi,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _textSearchController,
        onChanged: (val) =>
            context.read<UniversitySearchCubit>().updateFilters(query: val),
        decoration: InputDecoration(
          hintText: 'Search for courses or universities...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
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
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 16.h),
            Text(
              '${results.length} Universities Found',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16.r),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final uni = results[index];
                  return Card(
                    child: ListTile(
                      onTap: () =>
                          context.push('/university_details', extra: uni),
                      title: Text(
                        uni.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${uni.programs.length} Matching Programs',
                      ),
                      trailing: Text(
                        '${uni.matchPercentage}%',
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
