import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/services_locator.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/utils/build_notes_section.dart';
import '../../../../core/utils/quick_info_metrics.dart';
import '../../../../core/utils/requirements_check_list.dart';
import '../../../../domain/entities/university_entity.dart';
import '../../UniversityDetails/cubit/university_details_cubit.dart';
import '../cubit/my_applications_cubits.dart';

void showApplicationDetailSheet(BuildContext context, UniversityEntity app) {
  final myAppsCubit = context.read<MyApplicationsCubit>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: myAppsCubit),
        BlocProvider<UniversityDetailsCubit>(
          create: (context) => sl<UniversityDetailsCubit>()
            ..initializeUniversityData(
              percentage: app.matchPercentage,
              programs: app.programs,
              university: app,
            ),
        ),
      ],
      child: ApplicationDetailSheet(app: app),
    ),
  );
}

class ApplicationDetailSheet extends StatelessWidget {
  final UniversityEntity app;
  const ApplicationDetailSheet({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(24.r).copyWith(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: _DragHandle()),
                SizedBox(height: 16.h),
                _buildHeader(context),
                SizedBox(height: 20.h),
                QuickInfoMetrics(university: app),
                SizedBox(height: 24.h),
                _buildRequirementsSection(context),
                SizedBox(height: 24.h),
                _buildNotesSection(context),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildFooter(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final String programName = app.programs.isNotEmpty
        ? app.programs.first.programName
        : "Application";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          app.name,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: context.isDark ? AppColors.textMain : null,
          ),
        ),
        Text(
          programName,
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFF4F46E5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('requirementsChecklist'),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: context.isDark ? AppColors.textMain : null,
          ),
        ),
        SizedBox(height: 12.h),
        RequirementsChecklistList(university: app),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return BuildNotesSection(
      university: app,
      onSaveNotes: (newNotes) async {
        // حماية context.mounted عند استدعاء Cubit من شيت قد يُغلق
        if (context.mounted) {
          await context.read<MyApplicationsCubit>().updateNotesInList(
            app.id,
            newNotes,
            programId: app.programs.isNotEmpty ? app.programs.first.id : null,
          );
        }
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    final String programId = app.programs.isNotEmpty
        ? app.programs.first.id
        : "";
    final myCubit = context
        .read<MyApplicationsCubit>(); // 🎯 سحب الكيوبيت في متغير ثابت

    return Container(
      padding: EdgeInsets.all(20.r),
      color: context.isDark ? AppColors.darkSurface : Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              // 🎯 الإصلاح هنا: نغلق الشاشة فوراً، ثم نقوم بعملية الحذف
              Navigator.pop(context);
              myCubit.deleteApplication(app.id, programId);
            },
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                minimumSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).translate('close'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkBorder : Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
