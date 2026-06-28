import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/themes/app_colors.dart';

class VisaStep {
  final String title;
  final String description;
  final IconData icon;
  final String? link;
  final String? linkLabel;

  const VisaStep({
    required this.title,
    required this.description,
    required this.icon,
    this.link,
    this.linkLabel,
  });
}

class VisaGuideScreen extends StatefulWidget {
  const VisaGuideScreen({super.key});

  @override
  State<VisaGuideScreen> createState() => _VisaGuideScreenState();
}

class _VisaGuideScreenState extends State<VisaGuideScreen> {
  final Set<int> _completed = {};

  static final List<VisaStep> Function(BuildContext) _visaSteps = (ctx) { final t = AppLocalizations.of(ctx).translate; return [
    VisaStep(
      title: t('stepCheckRequirements'),
      description: t('stepCheckRequirementsDesc'),
      icon: Icons.visibility,
      link: 'https://www.daad.de/en/studying-in-germany/visa-and-entrance/',
      linkLabel: t('daadVisaInfo'),
    ),
    VisaStep(
      title: t('stepPrepareDocuments'),
      description: t('stepPrepareDocumentsDesc'),
      icon: Icons.description,
      link: 'https://www.make-it-in-germany.com/en/visa-residence/student-visa',
      linkLabel: t('documentChecklist'),
    ),
    VisaStep(
      title: t('stepOpenBlockedAccount'),
      description: t('stepOpenBlockedAccountDesc'),
      icon: Icons.account_balance,
      link: 'https://www.expatrio.com/blocked-account',
      linkLabel: t('expatrioBlockedAccount'),
    ),
    VisaStep(
      title: t('stepHealthInsurance'),
      description: t('stepHealthInsuranceDesc'),
      icon: Icons.health_and_safety,
      link: 'https://www.tk.de/en/student-health-insurance-2068502',
      linkLabel: t('tkStudentInsurance'),
    ),
    VisaStep(
      title: t('stepBookAppointment'),
      description: t('stepBookAppointmentDesc'),
      icon: Icons.calendar_month,
      link: 'https://www.diplo.de/',
      linkLabel: t('germanMissions'),
    ),
    VisaStep(
      title: t('stepAttendInterview'),
      description: t('stepAttendInterviewDesc'),
      icon: Icons.person,
    ),
    VisaStep(
      title: t('stepWaitProcessing'),
      description: t('stepWaitProcessingDesc'),
      icon: Icons.hourglass_bottom,
    ),
    VisaStep(
      title: t('stepAnmeldung'),
      description: t('stepAnmeldungDesc'),
      icon: Icons.location_city,
      link: 'https://service.berlin.de/dienstleistung/120686/',
      linkLabel: t('berlinAnmeldung'),
    ),
    VisaStep(
      title: t('stepResidencePermit'),
      description: t('stepResidencePermitDesc'),
      icon: Icons.badge,
    ),
    VisaStep(
      title: t('stepBankAccount'),
      description: t('stepBankAccountDesc'),
      icon: Icons.money,
    ),
  ]; };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final steps = _visaSteps(context);
    final progress = _completed.length / steps.length;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).translate('visaGuide'))),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).translate('preDepartureChecklist'),
                    style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 8.h),
                Text(AppLocalizations.of(context).translate('completedOf').replaceAll('{count}', '${_completed.length}').replaceAll('{total}', '${steps.length}'),
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
                SizedBox(height: 12.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6.h,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Text(AppLocalizations.of(context).translate('essentialSteps'), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 12.h),
          ...steps.asMap().entries.map((entry) => _buildStep(entry.key, entry.value, isDark)),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Color(0xFFD97706)),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(AppLocalizations.of(context).translate('visaTip'),
                      style: TextStyle(fontSize: 12.sp, color: const Color(0xFF92400E))),
                ),
              ],
            ),
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildStep(int index, VisaStep step, bool isDark) {
    final done = _completed.contains(index);
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: CheckboxListTile(
        value: done,
        onChanged: (v) {
          setState(() {
            if (v == true) _completed.add(index); else _completed.remove(index);
          });
        },
        title: Text(step.title,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp,
                color: isDark ? AppColors.textMain : const Color(0xFF0F172A))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Text(step.description, style: TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B))),
            if (step.link != null) ...[
              SizedBox(height: 6.h),
              InkWell(
                onTap: () => launchUrl(Uri.parse(step.link!)),
                child: Row(
                  children: [
                    Icon(Icons.open_in_new, size: 14.sp, color: const Color(0xFF4F46E5)),
                    SizedBox(width: 4.w),
                    Text(step.linkLabel ?? AppLocalizations.of(context).translate('learnMore'),
                        style: TextStyle(fontSize: 12.sp, color: const Color(0xFF4F46E5), decoration: TextDecoration.underline)),
                  ],
                ),
              ),
            ],
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: const Color(0xFF4F46E5),
      ),
    );
  }
}
