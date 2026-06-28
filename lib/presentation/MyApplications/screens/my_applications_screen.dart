import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:germany_travel/core/widgets/curtain_drop.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
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
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MyApplicationsCubit>().loadApplications();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
            AppLocalizations.of(context).translate('applications'),
            style: TextStyle(
              color: context.isDark ? AppColors.textMain : const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
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
                  CurtainDrop(
                    index: 0,
                    child: ShimmerCard(height: 40.h, borderRadius: 12.r),
                  ),
                  SizedBox(height: 16.h),
                  CurtainDrop(
                    index: 1,
                    child: Row(
                      children: List.generate(3, (i) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i < 2 ? 8.w : 0),
                          child: ShimmerCard(height: 70.h, borderRadius: 16.r),
                        ),
                      )),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  CurtainDrop(
                    index: 2,
                    child: ShimmerCard(height: 50.h, borderRadius: 12.r),
                  ),
                  SizedBox(height: 16.h),
                  CurtainDrop(
                    index: 3,
                    child: Column(
                      children: List.generate(4, (i) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: ShimmerCard(height: 100.h, borderRadius: 16.r),
                      )),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is MyApplicationsError) {
            return Center(
              child: CurtainDrop(
                index: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48.sp),
                    SizedBox(height: 16.h),
                    Text(
                      '${AppLocalizations.of(context).translate('error')}${state.message}',
                      style: const TextStyle(color: Colors.red),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.read<MyApplicationsCubit>().loadApplications(),
                      child: Text(AppLocalizations.of(context).translate('retry')),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is MyApplicationsLoaded) {
            return Column(
              children: [
                // شريط البحث
                CurtainDrop(
                  index: 0,
                  child: Container(
                    color: context.isDark ? AppColors.darkCardBg : Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(
                          const Duration(milliseconds: 300),
                          () => context.read<MyApplicationsCubit>().searchApplications(value),
                        );
                      },
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).translate('searchPrograms'),
                        prefixIcon: Icon(
                          Icons.search,
                          color: context.isDark ? AppColors.textMuted : AppColors.textGrey,
                        ),
                        filled: true,
                        fillColor: context.isDark ? AppColors.darkCardBg : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),

                // شريط الفلاتر
                CurtainDrop(
                  index: 1,
                  child: PipelineFilterBar(
                    activeFilter: state.activeFilter,
                    statusCounts: state.statusCounts,
                    onFilterSelected: (filter) {
                      context.read<MyApplicationsCubit>().filterApplications(
                        filter,
                      );
                    },
                  ),
                ),

                // كارت الإحصائيات (Metrics)
                CurtainDrop(
                  index: 2,
                  child: PipelineMetricsHub(
                    applications: state.allApplications,
                    statusCounts: state.statusCounts,
                  ),
                ),

                // قائمة الطلبات
                Expanded(
                  child: CurtainDrop(
                    index: 3,
                    child: RefreshIndicator(
                      onRefresh: () =>
                          context.read<MyApplicationsCubit>().loadApplications(),
                      child: state.filteredApplications.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(height: 100.h),
                                Center(
                                  child: Text(
                                    AppLocalizations.of(context).translate('noApplicationsFound'),
                                    style: TextStyle(
                                      color: context.isDark ? AppColors.textMuted : Colors.grey,
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
