import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/widgets/shimmer_loading.dart';
import '../cubit/my_applications_cubits.dart';
import '../cubit/my_applications_states.dart';
import '../widgets/MyApplicatons/pipeline_filter_bar.dart';
import '../widgets/MyApplicatons/pipeline_metrics_hub.dart';
import '../widgets/MyApplicatons/pipeline_university_card.dart';
import '../widgets/application_detail_sheet.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // جلب البيانات عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MyApplicationsCubit>().loadApplications();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'My Pipeline',
          style: TextStyle(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: BlocBuilder<MyApplicationsCubit, MyApplicationsState>(
        builder: (context, state) {
          if (state is MyApplicationsLoading) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
              child: Column(
                children: [
                  ShimmerCard(height: 40, borderRadius: 12),
                  SizedBox(height: 16.h),
                  Row(
                    children: List.generate(3, (i) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < 2 ? 8.w : 0),
                        child: ShimmerCard(height: 70, borderRadius: 16),
                      ),
                    )),
                  ),
                  SizedBox(height: 24.h),
                  ShimmerCard(height: 50, borderRadius: 12),
                  SizedBox(height: 16.h),
                  ...List.generate(4, (i) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: ShimmerCard(height: 100, borderRadius: 16),
                  )),
                ],
              ),
            );
          }

          if (state is MyApplicationsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16.h),
                  Text(
                    "Error: ${state.message}",
                    style: const TextStyle(color: Colors.red),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.read<MyApplicationsCubit>().loadApplications(),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          if (state is MyApplicationsLoaded) {
            return Column(
              children: [
                // شريط البحث
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => context
                        .read<MyApplicationsCubit>()
                        .searchApplications(value),
                    decoration: InputDecoration(
                      hintText: 'Search programs or universities...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // شريط الفلاتر
                PipelineFilterBar(
                  activeFilter: state.activeFilter,
                  statusCounts: state.statusCounts,
                  onFilterSelected: (filter) {
                    context.read<MyApplicationsCubit>().filterApplications(
                      filter,
                    );
                  },
                ),

                // كارت الإحصائيات (Metrics)
                PipelineMetricsHub(
                  upcomingDeadlines: state.allApplications.length,
                  matchAverage: 80, // يمكن ربطها بحسبة ديناميكية
                ),

                // قائمة الطلبات
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        context.read<MyApplicationsCubit>().loadApplications(),
                    child: state.filteredApplications.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: 100.h),
                              Center(
                                child: Text(
                                  'No applications found',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(16.r),
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
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
