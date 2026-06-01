import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/university_model.dart';
import '../../../domain/entities/university_entity.dart';
import '../../Home/cubit/home_cubit.dart';
import '../../Home/cubit/home_state.dart';
import '../cubit/university_search_cubit.dart';
import '../cubit/university_search_state.dart';
import '../widgets/advanced_filter_panel.dart';
import '../widgets/search_dropdowns_row.dart';

// المكان المركزي الموحد لحساب النسبة لو مش جاية من الباك إند
// مستقبلاً لما تضيف الـ AI، هتدخل تعدل الرقم ده فقط في الأبلكيشن كله!
int centralEvaluateUniversity(UniversityModel uni) {
  return 80; // القيمة الافتراضية للتوافق مع الهوم سكرين حالياً
}

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
          title: const Text(
            'Find Programs',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        ),
        body: BlocBuilder<UniversitySearchCubit, UniversitySearchState>(
          builder: (context, state) {
            if (state is UniversitySearchLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              );
            }
            if (state is UniversitySearchError) {
              return Center(
                child: Text(
                  'Error: ${state.message}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (state is UniversitySearchLoaded) {
              return Stack(
                children: [
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 100,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: TextField(
                            controller: _textSearchController,
                            onChanged: (val) {
                              context
                                  .read<UniversitySearchCubit>()
                                  .updateFilters(query: val);
                            },
                            decoration: const InputDecoration(
                              hintText:
                                  'Search by degree, course or university...',
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Color(0xFF64748B),
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SearchDropdownsRow(
                          currentCountry: state.selectedCountry,
                          currentDegree: state.selectedDegree,
                          currentMajor: state.selectedMajor,
                        ),
                        const SizedBox(height: 20),
                        AdvancedFilterPanel(
                          requiresIelts: state.requiresIelts,
                          maxTuition: state.maxTuition,
                          selectedLanguage: state.selectedLanguage,
                          acceptsMoi: state.acceptsMoi,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          _showResultsBottomSheet(
                            context,
                            state.filteredResults,
                          );
                        },
                        child: Text(
                          'Show ${state.filteredResults.length} Programs',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
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

  void _showResultsBottomSheet(
    BuildContext context,
    List<UniversityModel> filteredResults,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        height: MediaQuery.of(bottomSheetContext).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${filteredResults.length} Programs Found',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filteredResults.isEmpty
                  ? const Center(
                      child: Text('No programs match these filters.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredResults.length,
                      itemBuilder: (bottomSheetContext, index) {
                        final uni = filteredResults[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            onTap: () {
                              final homeCubit = context.read<HomeCubit>();
                              UniversityEntity evaluatedUni = uni;

                              if (homeCubit.state is HomeLoaded) {
                                final homeLoaded =
                                    homeCubit.state as HomeLoaded;

                                // محاولة إيجاد الكارد بنسبته الـ 80% المحسوبة مسبقاً في الهوم
                                final existingUni = homeLoaded.recommendations
                                    .firstWhere(
                                      (element) => element.id == uni.id,
                                      orElse: () => uni,
                                    );

                                if (existingUni.matchPercentage > 0) {
                                  evaluatedUni = existingUni;
                                } else {
                                  final centralScore =
                                      centralEvaluateUniversity(uni);
                                  // 🎯 تعديل مباشر على الـ Entity بدون أي كاستنج مسبب للكراشات
                                  evaluatedUni = uni.copyWith(
                                    matchPercentage: centralScore,
                                  );
                                }
                              } else {
                                final centralScore = centralEvaluateUniversity(
                                  uni,
                                );
                                // 🎯 تعديل مباشر على الـ Entity بدون أي كاستنج مسبب للكراشات
                                evaluatedUni = uni.copyWith(
                                  matchPercentage: centralScore,
                                );
                              }

                              // تمرير النسخة المتقيمة والمطابقة للهوم تماماً
                              context.push(
                                '/university_details',
                                extra: evaluatedUni,
                              );
                            },
                            title: Text(
                              uni.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(uni.program),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
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
