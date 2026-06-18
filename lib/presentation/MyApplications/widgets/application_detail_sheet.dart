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
import '../../../../core/widgets/webview_screen.dart';
import '../../../../domain/entities/university_entity.dart';
import '../../UniversityDetails/cubit/university_details_cubit.dart';
import '../../UniversityDetails/cubit/university_details_state.dart';
import '../../ai/widgets/ai_document_generator.dart';
import '../../ai/widgets/ai_document_review_sheet.dart';
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

class ApplicationDetailSheet extends StatefulWidget {
  final UniversityEntity app;
  const ApplicationDetailSheet({super.key, required this.app});

  @override
  State<ApplicationDetailSheet> createState() => _ApplicationDetailSheetState();
}

class _ApplicationDetailSheetState extends State<ApplicationDetailSheet> {
  late String _portalStatus;
  late String _paymentStatus;
  late bool _autoTrack;

  @override
  void initState() {
    super.initState();
    _portalStatus = widget.app.portalStatus;
    _paymentStatus = widget.app.paymentStatus;
    _autoTrack = widget.app.autoTrack;
  }

  UniversityEntity get app => widget.app;

  void _updatePortal(BuildContext context, {String? portalStatus, String? paymentStatus, bool? autoTrack}) {
    final programId = app.programs.isNotEmpty ? app.programs.first.id : '';
    setState(() {
      if (portalStatus != null) _portalStatus = portalStatus;
      if (paymentStatus != null) _paymentStatus = paymentStatus;
      if (autoTrack != null) _autoTrack = autoTrack;
    });
    context.read<UniversityDetailsCubit>().updatePortalStatus(
      universityId: app.id,
      programId: programId,
      portalStatus: portalStatus ?? app.portalStatus,
      paymentStatus: paymentStatus ?? app.paymentStatus,
      autoTrack: autoTrack ?? app.autoTrack,
    );
    context.read<MyApplicationsCubit>().updateLocalApp(
      app.id,
      programId: programId,
      portalStatus: portalStatus ?? app.portalStatus,
      paymentStatus: paymentStatus ?? app.paymentStatus,
      autoTrack: autoTrack ?? app.autoTrack,
    );
  }

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
                _buildPortalTrackingSection(context),
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

  Widget _buildPortalTrackingSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkSurface : const Color(0xFFF3F0FF),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.travel_explore, size: 18, color: Color(0xFF8B5CF6)),
              SizedBox(width: 8.w),
              Text(
                'Portal Status',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _StatusDropdown(
                  label: 'Status',
                  value: _portalStatus,
                  items: const ['pending', 'submitted', 'acknowledged', 'accepted', 'rejected'],
                  icon: Icons.assignment,
                  onChanged: (v) => _updatePortal(context, portalStatus: v!),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _StatusDropdown(
                  label: 'Payment',
                  value: _paymentStatus,
                  items: const ['unpaid', 'paid', 'waived'],
                  icon: Icons.payment,
                  onChanged: (v) => _updatePortal(context, paymentStatus: v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _autoTrack,
            onChanged: (v) => _updatePortal(context, autoTrack: v),
            title: const Text('Auto Track', style: TextStyle(fontSize: 13)),
            subtitle: const Text('Automatically sync portal status', style: TextStyle(fontSize: 11)),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          if (app.portalUrl != null && app.portalUrl!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WebViewScreen(url: app.portalUrl!),
                  ),
                ),
                icon: const Icon(Icons.open_in_browser, size: 16),
                label: const Text('Open Portal Link'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                  side: const BorderSide(color: Color(0xFF4F46E5)),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
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
        SizedBox(height: 16.h),
        _buildAiActions(context),
      ],
    );
  }

  Widget _buildAiActions(BuildContext context) {
    final String programName = app.programs.isNotEmpty
        ? app.programs.first.programName
        : '';
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to documents screen for AI review
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AiDocumentReviewSheet(
                  reviews: [],
                  error: 'Open Documents screen to review files',
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: Text(
              AppLocalizations.of(context).translate('aiReview'),
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final state = context.read<UniversityDetailsCubit>().state;
              final profile = state is UniversitySaveStatus
                  ? state.studentProfile
                  : null;
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => GenerateSheet(
                  programName: programName.isNotEmpty
                      ? programName
                      : 'German University Application',
                  universityName: app.name,
                  degreeType: app.programs.isNotEmpty
                      ? app.programs.first.degreeType
                      : '',
                  major: profile?['target_major']?.toString() ?? '',
                  studentName: profile?['username']?.toString() ?? '',
                  studentBackground:
                      'GPA: ${profile?['gpa'] ?? 'N/A'}, Major: ${profile?['target_major'] ?? 'N/A'}',
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: Text(
              'Generate CV/SOP with AI',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8B5CF6),
              side: const BorderSide(color: Color(0xFF8B5CF6)),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
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

class _StatusDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  const _StatusDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: context.isDark ? AppColors.darkBorder : Colors.grey[300]!,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(icon, size: 16, color: const Color(0xFF8B5CF6)),
          style: TextStyle(
            fontSize: 13.sp,
            color: context.isDark ? AppColors.textMain : Colors.black87,
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Row(
                children: [
                  Text(
                    item[0].toUpperCase() + item.substring(1),
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
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
