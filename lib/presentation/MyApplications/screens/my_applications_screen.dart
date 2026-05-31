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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // جلب البيانات عند فتح الشاشة لأول مرة
    context.read<MyApplicationsCubit>().loadApplications();
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

            // ✅ تغليف المحتوى داخل RefreshIndicator للسحب لأسفل
            return RefreshIndicator(
              color: const Color(0xFF4F46E5),
              onRefresh: () async {
                // سحب البيانات من السيرفر فوراً عند السحب
                await context.read<MyApplicationsCubit>().loadApplications();
              },
              child: Column(
                children: [
                  PipelineFilterBar(
                    activeFilter: state.activeFilter,
                    statusCounts: state.statusCounts,
                    onFilterSelected: (filter) => context
                        .read<MyApplicationsCubit>()
                        .filterApplications(filter),
                  ),
                  PipelineMetricsHub(
                    upcomingDeadlines: state.allApplications.length,
                    matchAverage: dynamicAverage,
                  ),
                  Expanded(
                    child: state.filteredApplications.isEmpty
                        ? ListView(
                            // ListView بسيط عشان الـ RefreshIndicator يشتغل حتى لو القائمة فاضية
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
