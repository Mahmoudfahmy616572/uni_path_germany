import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/my_applications_cubits.dart';
import '../cubit/my_applications_states.dart';
import '../widgets/MyApplicatons/pipeline_filter_bar.dart';
import '../widgets/MyApplicatons/pipeline_metrics_hub.dart';
import '../widgets/MyApplicatons/pipeline_university_card.dart';
import '../widgets/applicationDetailesSheets/application_detail_sheet.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  // 🎯 وحدة التحكم في نص البحث
  final TextEditingController _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<MyApplicationsCubit>().loadApplications();
  }

  @override
  void dispose() {
    // 🎯 تنظيف الـ controller عند إغلاق الشاشة
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Applications',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<MyApplicationsCubit, MyApplicationsState>(
        builder: (context, state) {
          if (state is MyApplicationsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            );
          }

          if (state is MyApplicationsLoaded) {
            double sumMatch = state.allApplications.fold(
              0,
              (sum, item) => sum + item.matchPercentage,
            );
            int dynamicAverage = state.allApplications.isNotEmpty
                ? (sumMatch / state.allApplications.length).round()
                : 0;

            return RefreshIndicator(
              color: const Color(0xFF4F46E5),
              onRefresh: () async {
                _searchController.clear(); // مسح البحث عند السحب للتحديث
                await context.read<MyApplicationsCubit>().loadApplications();
              },
              child: Column(
                children: [
                  // 🎯 شريط البحث الجميل والاحترافي
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        // استدعاء دالة البحث في الكيوبيت فوراً عند الكتابة
                        context.read<MyApplicationsCubit>().searchApplications(
                          value,
                        );
                      },
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search by university or program...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Color(0xFF94A3B8),
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  context
                                      .read<MyApplicationsCubit>()
                                      .searchApplications('');
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  PipelineFilterBar(
                    activeFilter: state.activeFilter,
                    statusCounts: state.statusCounts,
                    onFilterSelected: (filter) {
                      _searchController
                          .clear(); // مسح السيرش بار عند الانتقال بين التابات
                      context.read<MyApplicationsCubit>().filterApplications(
                        filter,
                      );
                    },
                  ),
                  PipelineMetricsHub(
                    upcomingDeadlines: state.allApplications.length,
                    matchAverage: dynamicAverage,
                  ),
                  Expanded(
                    child: state.filteredApplications.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Text(
                                  'No applications found',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            key: ValueKey(state.filteredApplications.length),
                            padding: const EdgeInsets.all(16),
                            itemCount: state.filteredApplications.length,
                            itemBuilder: (context, index) {
                              final app = state.filteredApplications[index];
                              return PipelineUniversityCard(
                                app: app,
                                onTap: () =>
                                    showApplicationDetailSheet(context, app),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          }

          if (state is MyApplicationsError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return const Center(child: Text('Initialize your applications'));
        },
      ),
    );
  }
}
