import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

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

  static const _visaSteps = [
    VisaStep(
      title: 'Check Visa Requirements',
      description: 'Determine if you need a German student visa based on your nationality. EU/EEA citizens do not need a visa. Check the DAAD and German embassy websites.',
      icon: Icons.visibility,
      link: 'https://www.daad.de/en/studying-in-germany/visa-and-entrance/',
      linkLabel: 'DAAD Visa Info',
    ),
    VisaStep(
      title: 'Prepare Required Documents',
      description: 'Valid passport, university admission letter, proof of financial resources (€11,208/year in blocked account), health insurance, passport photos, CV, and motivation letter.',
      icon: Icons.description,
      link: 'https://www.make-it-in-germany.com/en/visa-residence/student-visa',
      linkLabel: 'Document Checklist',
    ),
    VisaStep(
      title: 'Open a Blocked Account',
      description: 'Open a blocked account (Sperrkonto) with a German bank or approved provider (Expatrio, Fintiba, Coracle). Deposit ~€11,208 to show financial proof.',
      icon: Icons.account_balance,
      link: 'https://www.expatrio.com/blocked-account',
      linkLabel: 'Expatrio Blocked Account',
    ),
    VisaStep(
      title: 'Get Health Insurance',
      description: 'German student health insurance (~€110/month). Choose a public provider like TK, AOK, or private options for EU citizens. Must be valid for visa application.',
      icon: Icons.health_and_safety,
      link: 'https://www.tk.de/en/student-health-insurance-2068502',
      linkLabel: 'TK Student Insurance',
    ),
    VisaStep(
      title: 'Book Visa Appointment',
      description: 'Schedule an appointment at the German embassy/consulate in your country. Wait times can be 2-12 weeks — book early!',
      icon: Icons.calendar_month,
      link: 'https://www.diplo.de/',
      linkLabel: 'German Missions',
    ),
    VisaStep(
      title: 'Attend Visa Interview',
      description: 'Bring all original + 2 copies of documents. Be prepared to explain your study plans, finances, and post-graduation intentions. Interview is typically 10-15 minutes.',
      icon: Icons.person,
    ),
    VisaStep(
      title: 'Wait for Processing',
      description: 'Normal processing: 4-12 weeks. Avoid making non-refundable travel arrangements until approved. You can track status online in some countries.',
      icon: Icons.hourglass_bottom,
    ),
    VisaStep(
      title: 'Register in Germany (Anmeldung)',
      description: 'Within 14 days of arrival, register your address at the local Bürgeramt. Required for bank account, phone contract, and residence permit.',
      icon: Icons.location_city,
      link: 'https://service.berlin.de/dienstleistung/120686/',
      linkLabel: 'Berlin Anmeldung',
    ),
    VisaStep(
      title: 'Apply for Residence Permit',
      description: 'Visit the Ausländerbehörde within 90 days to convert your student visa to a residence permit. Bring registration certificate, passport, insurance, and proof of enrollment.',
      icon: Icons.badge,
    ),
    VisaStep(
      title: 'Open German Bank Account',
      description: 'With Anmeldung and residence permit, open a regular German bank account (N26, Deutsche Bank, Commerzbank). Easier for daily transactions than block account.',
      icon: Icons.money,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _completed.length / _visaSteps.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Visa & Pre-departure Guide')),
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
                const Text('Pre-departure Checklist',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8.h),
                Text('${_completed.length} of ${_visaSteps.length} completed',
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
          const Text('Essential Steps', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12.h),
          ..._visaSteps.asMap().entries.map((entry) => _buildStep(entry.key, entry.value, isDark)),
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
                  child: Text('Keep all documents organized in a folder. Make digital backups of everything!',
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
                    const Icon(Icons.open_in_new, size: 14, color: Color(0xFF4F46E5)),
                    SizedBox(width: 4.w),
                    Text(step.linkLabel ?? 'Learn more',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF4F46E5), decoration: TextDecoration.underline)),
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
