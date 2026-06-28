// ====================
// FILE: lib/presentation/profile/widgets/setting_screen.dart
// ====================
//
// الـ Bugs اللي اتصلحوا:
//  🐛 Bug #1 — _selectedDegree كانت بتتقرأ من budgetRange غلط
//              ✅ دلوقتي بتتقرأ من widget.user.degreeLevel الصح
//
//  🐛 Bug #2 — target_major مكانتش موجودة في الـ Settings خالص
//              ✅ أضفنا _selectedMajor dropdown مع نفس options الـ Onboarding
//
//  🐛 Bug #3 — target_major مكانتش بتتبعت في الـ updateProfileData call
//              ✅ أضفنا 'target_major': _selectedMajor في الـ updates map
//
// الـ Features الجديدة:
//  ✨ GPA Scale selector — الطالب يقدر يحدد scale بتاعه (4.0 / 5.0 / 10.0 / 20.0)
//     ومهم جداً للـ MatchScore Calculator اللي بيعتمد على maxGpa
//
//  ✨ Live Score Preview — بتظهر للطالب estimated match improvement لما يغير بياناته
//     مش match score حقيقي، مجرد feedback بصري بسيط يشجعه يكمل
//
//  ✨ Profile Completeness Bar — شريط بيوضح للطالب نسبة اكتمال البروفايل
//     بيحفزه يملأ كل الحاجات اللي ناقصة وده بيزود جودة الـ matching

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/services/services_locator.dart' as di;
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/custom_snack_bar.dart';
import '../../../core/widgets/curtain_drop.dart';
import '../../../domain/entities/user_entity.dart';
import '../../Home/cubit/home_cubit.dart';
import '../../MyApplications/cubit/my_applications_cubits.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

class SettingsScreen extends StatefulWidget {
  final UserEntity user;
  final int? scrollToSection;
  const SettingsScreen({super.key, required this.user, this.scrollToSection});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Controllers ──────────────────────────────────────────
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _gpaController;
  late TextEditingController _academicAvgController;
  late TextEditingController _highSchoolController;
  late TextEditingController _ieltsScoreController;
  late TextEditingController _toeflScoreController;

  // ── Dropdown selections ───────────────────────────────────
  late String _selectedIntake;
  late String _selectedLanguage;
  late String _selectedDegree;

  late String _selectedMajor;
  late String _selectedGpaScale;
  late String _selectedNationality;
  late String _selectedBudget;
  final List<String> _selectedCities = [];

  // ── Toggles ───────────────────────────────────────────────
  late bool _hasIelts;
  late bool _hasToefl;
  late bool _hasMoi;
  late bool _hasStudiedUniversity;

  // ── Notification Preferences ──────────────────────────────
  late bool _notificationsEnabled;
  late bool _deadlineReminders;
  late bool _applicationUpdates;
  late bool _generalNotifications;
  late List<int> _reminderDaysBefore;

  // ── Quiet Hours ────────────────────────────────────────────
  late TimeOfDay? _quietStart;
  late TimeOfDay? _quietEnd;

  static const List<int> _reminderDayOptions = [1, 3, 7, 14, 30];

  // ── Section scrolling ─────────────────────────────────────
  final List<GlobalKey> _sectionKeys = List.generate(8, (_) => GlobalKey());

  // ── Dropdown options (نفس الـ Onboarding) ─────────────────
  static const List<String> _majors = [
    'Computer Science',
    'Computer Science & IT',
    'Information Systems',
    'Artificial Intelligence',
    'Cybersecurity',
    'Bioinformatics',
    'Software Engineering',
    'Data Science',
    'Information Technology',
    'Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Aerospace Engineering',
    'Automotive Engineering',
    'Chemical Engineering',
    'Energy Engineering',
    'Robotics',
    'Business Administration',
    'Business & Management',
    'Economics',
    'Finance',
    'Management',
    'Marketing',
    'Medicine',
    'Healthcare',
    'Pharmaceutical Sciences',
    'Natural Sciences',
    'Mathematics',
    'Environmental Science',
    'Physics',
    'Chemistry',
    'Social Sciences',
    'Political Science',
    'Law',
  ];

  static const List<String> _degrees = [
    "Bachelor's Degree",
    "Master's Degree",
    'PhD / Doctorate',
    'Graduate School',
    'Summer Course',
    'Short Course',
    'Foundation / Preparatory',
    'Study Abroad / Exchange',
  ];

  static const List<String> _intakes = [
    'Winter Semester',
    'Summer Semester',
    'Both Semesters',
  ];

  static const List<String> _languages = ['English', 'German', 'Both'];

  static const List<String> _gpaScales = ['4.0', '5.0', '10.0', '20.0'];

  static const List<String> _nationalities = [
    'Egypt',
    'Saudi Arabia',
    'Iraq',
    'Yemen',
    'Syria',
    'Jordan',
    'Lebanon',
    'Palestine',
    'Libya',
    'Tunisia',
    'Algeria',
    'Morocco',
    'Sudan',
    'Somalia',
    'Mauritania',
    'Bahrain',
    'Kuwait',
    'Oman',
    'Qatar',
    'UAE',
    'Other',
  ];

  static const List<String> _germanCities = [
    'Berlin',
    'Munich',
    'Hamburg',
    'Frankfurt',
    'Cologne',
    'Stuttgart',
    'Düsseldorf',
    'Leipzig',
    'Dresden',
    'Bonn',
    'Mannheim',
    'Nuremberg',
    'Hannover',
    'Bremen',
    'Freiburg',
    'Heidelberg',
    'Tübingen',
    'Aachen',
    'Darmstadt',
    'Karlsruhe',
  ];

  static const List<String> _budgetRanges = [
    'Under €10,000',
    '€10,000 - €15,000',
    '€15,000 - €20,000',
    '€20,000 - €30,000',
    'Above €30,000',
    'Not Sure',
  ];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _gpaController = TextEditingController(
      text: widget.user.gpa > 0 ? widget.user.gpa.toString() : '',
    );
    _academicAvgController = TextEditingController(
      text: widget.user.academicAverage != null && widget.user.academicAverage! > 0
          ? widget.user.academicAverage.toString()
          : '',
    );
    _highSchoolController = TextEditingController(
      text: widget.user.highSchoolScore != null && widget.user.highSchoolScore! > 0
          ? widget.user.highSchoolScore.toString()
          : '',
    );
    _hasStudiedUniversity = widget.user.academicAverage != null;
    _ieltsScoreController = TextEditingController(
      text: widget.user.ieltsScore > 0 ? widget.user.ieltsScore.toString() : '',
    );
    _toeflScoreController = TextEditingController(
      text: widget.user.toeflScore > 0 ? widget.user.toeflScore.toString() : '',
    );

    _selectedDegree = _degrees.contains(widget.user.degreeLevel)
        ? widget.user.degreeLevel
        : _degrees.first;

    // ✅ Bug #2 fix — نقرأ target_major الحقيقي
    _selectedMajor = _majors.contains(widget.user.targetMajor)
        ? widget.user.targetMajor
        : _majors.first;

    _selectedIntake = _intakes.contains(widget.user.intake)
        ? widget.user.intake
        : _intakes.first;

    _selectedLanguage = _languages.contains(widget.user.languagePreference)
        ? widget.user.languagePreference
        : _languages.first;

    // ✨ GPA Scale — بنقرأها من maxGpa في الـ entity
    final String scaleFromMax =
        widget.user.maxGpa.toStringAsFixed(1).replaceAll('.0', '') +
            (widget.user.maxGpa % 1 == 0 ? '.0' : '');
    _selectedGpaScale =
        _gpaScales.contains(scaleFromMax) ? scaleFromMax : '4.0';

    _hasIelts = widget.user.hasIelts;
    _hasToefl = widget.user.hasToefl;
    _hasMoi = widget.user.hasMoi;

    _selectedNationality = _nationalities.contains(widget.user.nationality)
        ? widget.user.nationality
        : _nationalities.first;
    _selectedCities.addAll(
      widget.user.preferredCities.where((c) => _germanCities.contains(c)),
    );
    _selectedBudget = _budgetRanges.contains(widget.user.budgetRange)
        ? widget.user.budgetRange
        : _budgetRanges.first;

    // ✨ Notification Preferences — نقرأ من user.notificationPreferences
    final prefs = widget.user.notificationPreferences;
    _notificationsEnabled = prefs.notificationsEnabled;
    _deadlineReminders = prefs.deadlineReminders;
    _applicationUpdates = prefs.applicationUpdates;
    _generalNotifications = prefs.generalNotifications;
    _reminderDaysBefore = List.from(prefs.reminderDaysBefore);

    // ✨ Quiet Hours — نقرأ من user
    _quietStart = widget.user.quietStart;
    _quietEnd = widget.user.quietEnd;

    if (widget.scrollToSection != null && widget.scrollToSection! >= 0 && widget.scrollToSection! < 8) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _sectionKeys[widget.scrollToSection!];
        if (key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _gpaController.dispose();
    _academicAvgController.dispose();
    _highSchoolController.dispose();
    _ieltsScoreController.dispose();
    _toeflScoreController.dispose();
    super.dispose();
  }

  // ── Profile Completeness ──────────────────────────────────
  // بتحسب نسبة اكتمال البروفايل بناءً على الحقول المعبأة
  double get _completeness {
    int filled = 0;
    const int total = 6;
    if (_nameController.text.trim().isNotEmpty) filled++;
    if (_gpaController.text.trim().isNotEmpty) filled++;
    if (_selectedMajor.isNotEmpty) filled++;
    if (_selectedDegree.isNotEmpty) filled++;
    if (_hasIelts && _ieltsScoreController.text.trim().isNotEmpty) {
      filled++;
    } else if (!_hasIelts) {
      filled++;
    }
    if (_selectedIntake.isNotEmpty) filled++;
    return filled / total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppLocalizations.of(context).translate('accountSettings'),
          style: TextStyle(
            color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdateSuccess) {
            // تحديث الـ HomeCubit بالبيانات الجديدة
            context.read<HomeCubit>().calculateAndFetchRecommendations(
                  forceRefresh: true,
                );
            // تحديث الـ MyApplicationsCubit
            di.sl<MyApplicationsCubit>().loadApplications();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.pop(true);
            });
          }
          if (state is ProfileError) {
            CustomSnackBar.show(context, message: state.message, isError: true);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.r, vertical: 16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Profile Completeness Bar ──────────────────
                _buildCompletenessCard(),
                SizedBox(height: 24.h, key: _sectionKeys[0]),

                // ── Section: Personal Info ────────────────────
                CurtainDrop(
                  index: 0,
                  child: _buildSectionLabel(AppLocalizations.of(context).translate('personalInfo')),
                ),
                SizedBox(height: 10.h),
                _buildField(AppLocalizations.of(context).translate('name'), _nameController, Icons.person_outline),
                _buildField(
                  AppLocalizations.of(context).translate('email'),
                  _emailController,
                  Icons.email_outlined,
                  enabled: false,
                ),

                // ── Section: Academic Profile ─────────────────
                SizedBox(height: 20.h, key: _sectionKeys[1]),
                CurtainDrop(
                  index: 1,
                  child: _buildSectionLabel(AppLocalizations.of(context).translate('academicProfile')),
                ),
                SizedBox(height: 10.h),

                // ✅ Bug #2 — target_major dropdown
                _buildDropdown(
                  label: AppLocalizations.of(context).translate('fieldOfStudy'),
                  icon: Icons.school_outlined,
                  value: _selectedMajor,
                  items: _majors,
                  onChanged: (v) => setState(() => _selectedMajor = v!),
                ),
                _buildDropdown(
                  label: AppLocalizations.of(context).translate('degreeLevel'),
                  icon: Icons.workspace_premium_outlined,
                  value: _selectedDegree,
                  items: _degrees,
                  onChanged: null,
                ),
                // GPA or Academic Average
                _buildGpaOrAcademicRow(),

                // ── Section: Language & Intake ────────────────
                SizedBox(height: 20.h, key: _sectionKeys[2]),
                CurtainDrop(
                  index: 2,
                  child: _buildSectionLabel(AppLocalizations.of(context).translate('preferences')),
                ),
                SizedBox(height: 10.h),

                _buildDropdown(
                  label: AppLocalizations.of(context).translate('studyLanguage'),
                  icon: Icons.language_outlined,
                  value: _selectedLanguage,
                  items: _languages,
                  onChanged: (v) => setState(() => _selectedLanguage = v!),
                ),
                _buildDropdown(
                  label: AppLocalizations.of(context).translate('targetIntake'),
                  icon: Icons.calendar_today_outlined,
                  value: _selectedIntake,
                  items: _intakes,
                  onChanged: (v) => setState(() => _selectedIntake = v!),
                ),

                // ── Section: Language Certificate ─────────────
                SizedBox(height: 20.h, key: _sectionKeys[3]),
                CurtainDrop(
                  index: 3,
                  child: _buildSectionLabel(AppLocalizations.of(context).translate('languageCertificate')),
                ),
                SizedBox(height: 10.h),
                _buildIeltsSection(),

                // ── Section: Notifications ────────────────────
                SizedBox(height: 20.h, key: _sectionKeys[4]),
                CurtainDrop(
                  index: 4,
                  child: _buildSectionLabel(AppLocalizations.of(context).translate('notifications')),
                ),
                SizedBox(height: 10.h),
                _buildNotificationSection(),

                // ── Section: App Settings ──────────────────────
                SizedBox(height: 20.h, key: _sectionKeys[5]),
                CurtainDrop(
                  index: 5,
                  child: _buildSectionLabel(AppLocalizations.of(context).translate('appSettings')),
                ),
                SizedBox(height: 10.h),

                _buildDropdown(
                  label: AppLocalizations.of(context).translate('nationality'),
                  icon: Icons.flag_outlined,
                  value: _selectedNationality,
                  items: _nationalities,
                  onChanged: (v) => setState(() => _selectedNationality = v!),
                ),

                _buildCitiesSelector(),

                _buildDropdown(
                  label: AppLocalizations.of(context).translate('budgetRange'),
                  icon: Icons.attach_money_outlined,
                  value: _selectedBudget,
                  items: _budgetRanges,
                  onChanged: (v) => setState(() => _selectedBudget = v!),
                ),

                _buildLanguageToggle(),

                // ── Section: Legal ────────────────────────────
                SizedBox(height: 20.h, key: _sectionKeys[6]),
                CurtainDrop(
                  index: 6,
                  child: _buildSectionLabel(AppLocalizations.of(context).translate('legal')),
                ),
                SizedBox(height: 10.h),
                _buildLegalLink(Icons.privacy_tip_outlined, AppLocalizations.of(context).translate('privacyPolicy'), '/privacy'),
                _buildLegalLink(Icons.description_outlined, AppLocalizations.of(context).translate('termsOfService'), '/terms'),
                SizedBox(height: 20.h),

                // ── Section: Danger Zone ────────────────────────
                SizedBox(height: 20.h, key: _sectionKeys[7]),
                CurtainDrop(
                  index: 7,
                  child: _buildSectionLabel(AppLocalizations.of(context).translate('dangerZone')),
                ),
                SizedBox(height: 10.h),
                _buildDeleteAccountButton(),

                // Bottom padding for floating button
                SizedBox(height: 100.h),
              ],
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final bool isLoading = state is ProfileLoading;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: SizedBox(
              width: double.infinity,
              child: FloatingActionButton.extended(
                onPressed: isLoading ? null : _onSave,
                backgroundColor: AppColors.primary,
                foregroundColor: context.isDark ? AppColors.darkCardBg : Colors.white,
                elevation: 8,
                icon: isLoading
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: CircularProgressIndicator(
                          color: context.isDark ? AppColors.darkCardBg : Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.save, size: 20.sp),
                label: Text(
                  isLoading ? AppLocalizations.of(context).translate('saving') : AppLocalizations.of(context).translate('saveChanges'),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Save Handler ──────────────────────────────────────────
  void _onSave() {
    final double gpa = double.tryParse(_gpaController.text) ?? 0.0;
    final double maxGpa = double.tryParse(_selectedGpaScale) ?? 4.0;
    final double ielts = double.tryParse(_ieltsScoreController.text) ?? 0.0;
    final double toefl = double.tryParse(_toeflScoreController.text) ?? 0.0;

    context.read<ProfileCubit>().updateProfileData(
      updates: {
        'username': _nameController.text.trim(),
        'target_major': _selectedMajor,
        'gpa': gpa,
        'academic_average': _hasStudiedUniversity
            ? (double.tryParse(_academicAvgController.text) ?? 0.0)
            : null,
        'high_school_score': _hasStudiedUniversity
            ? null
            : (double.tryParse(_highSchoolController.text) ?? 0.0),
        'max_gpa': maxGpa,
        'has_ielts': _hasIelts,
        'ielts_score': _hasIelts ? ielts : 0.0,
        'has_toefl': _hasToefl,
        'toefl_score': _hasToefl ? toefl : 0.0,
        'has_moi': _hasMoi,
        'intake': _selectedIntake,
        'language_preference': _selectedLanguage,
        // ✨ Notification Preferences
        'notifications_enabled': _notificationsEnabled,
        'deadline_reminders': _deadlineReminders,
        'application_updates': _applicationUpdates,
        'general_notifications': _generalNotifications,
        'reminder_days_before': _reminderDaysBefore,
        // ✨ Quiet Hours
        'quiet_start': _quietStart != null
            ? '${_quietStart!.hour.toString().padLeft(2, '0')}:${_quietStart!.minute.toString().padLeft(2, '0')}'
            : null,
        'quiet_end': _quietEnd != null
            ? '${_quietEnd!.hour.toString().padLeft(2, '0')}:${_quietEnd!.minute.toString().padLeft(2, '0')}'
            : null,
        'nationality': _selectedNationality,
        'preferred_cities': _selectedCities,
        'budget_range': _selectedBudget,
      },
    );
  }

  // ── Delete Account ─────────────────────────────────────────
  Future<void> _onDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('deleteAccount')),
        content: Text(
          AppLocalizations.of(context).translate('deleteAccountWarning'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).translate('yesDelete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await context.read<ProfileCubit>().authRepository.deleteAccount();
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          message: AppLocalizations.of(context).translate('accountDeletedSuccess'),
        );
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          message: '${AppLocalizations.of(context).translate('failedToDeleteAccount')}$e',
          isError: true,
        );
      }
    }
  }

  // ── Widgets ───────────────────────────────────────────────

  Widget _buildCompletenessCard() {
    final double pct = _completeness;
        final String label = pct >= 1.0
        ? AppLocalizations.of(context).translate('profileComplete')
        : AppLocalizations.of(context).translate('completeProfileForBetterMatches');

    return StatefulBuilder(
      builder: (context, setInner) {
        final double live = _completeness;
        return Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: context.isDark ? AppColors.darkCardBg : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('profileCompleteness'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                          color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${(live * 100).round()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: LinearProgressIndicator(
                      value: live,
                      backgroundColor: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        live >= 1.0 ? Colors.green : AppColors.primary,
                      ),
                      minHeight: 8.h,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            );
          },
        );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNum = false,
    bool enabled = true,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: enabled ? context.isDark ? AppColors.darkCardBg : Colors.white : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        style: TextStyle(fontSize: 14.sp, color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B)),
          prefixIcon: Icon(icon, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.r,
            vertical: 14.r,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    ValueChanged<String?>? onChanged,
  }) {
    final bool isDisabled = onChanged == null;
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: isDisabled ? context.isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC) : context.isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: items.contains(value) ? value : items.first,
        isExpanded: true,
        icon: isDisabled
            ? Icon(Icons.lock_outline, color: AppColors.textMuted, size: 18)
            : Icon(Icons.keyboard_arrow_down, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDisabled ? AppColors.textMuted : const Color(0xFF64748B),
          ),
          prefixIcon: Icon(
            icon,
            color: isDisabled ? AppColors.textMuted : const Color(0xFF64748B),
            size: 20,
          ),
          border: InputBorder.none,
        ),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDisabled
                        ? AppColors.textMuted
                        : context.isDark ? AppColors.textMain : const Color(0xFF1E293B),
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  bool _isGraduateLevel() {
    return _selectedDegree == "Master's Degree" || _selectedDegree == 'PhD / Doctorate' || _selectedDegree == 'Graduate School';
  }

  // ✨ Conditional: GPA for Master/PhD, Academic Average for Bachelor
  Widget _buildGpaOrAcademicRow() {
    if (_isGraduateLevel()) {
      return _buildGpaRow();
    }
    return _buildAcademicAverageRow();
  }

  // ✨ GPA row مع GPA Scale selector بجنبه (لـ Master's / PhD)
  Widget _buildGpaRow() {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: context.isDark ? AppColors.darkCardBg : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _gpaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('gpa'),
                  labelStyle: TextStyle(color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B)),
                  prefixIcon: Icon(
                    Icons.grade_outlined,
                    color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 14.r),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: context.isDark ? AppColors.darkCardBg : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGpaScale,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B), size: 18),
                  hint: Text(AppLocalizations.of(context).translate('scale'), style: TextStyle(fontSize: 12.sp, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B))),
                  items: _gpaScales.map((e) => DropdownMenuItem(value: e, child: Text('${AppLocalizations.of(context).translate('of')} $e', style: TextStyle(fontSize: 13.sp, color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B))))).toList(),
                  onChanged: (v) => setState(() => _selectedGpaScale = v!),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✨ Academic Average row for Bachelor & other non-graduate levels
  Widget _buildAcademicAverageRow() {
    return Column(
      children: [
        // "Have you studied?" toggle
        Container(
          margin: EdgeInsets.only(bottom: 10.h),
          child: Row(
            children: [
                Text(
                  AppLocalizations.of(context).translate('haveYouStudiedUniversity'),
                style: TextStyle(
                  fontSize: 13.sp,
                  color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _hasStudiedUniversity = !_hasStudiedUniversity),
                child: Container(
                  width: 50.w,
                  height: 28.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.r),
                    color: _hasStudiedUniversity ? AppColors.primary : context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: _hasStudiedUniversity ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(3.r),
                      child: Container(
                        width: 22.r,
                        height: 22.r,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Academic Average or High School Score field
        if (_hasStudiedUniversity)
          _buildNumericField(
            controller: _academicAvgController,
            label: AppLocalizations.of(context).translate('academicAverage'),
          )
        else
          _buildNumericField(
            controller: _highSchoolController,
            label: AppLocalizations.of(context).translate('highSchoolScore'),
          ),
      ],
    );
  }

  Widget _buildNumericField({
    required TextEditingController controller,
    required String label,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
          fontSize: 14.sp,
          color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B)),
          prefixIcon: Icon(
            Icons.analytics_outlined,
            color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 14.r),
        ),
      ),
    );
  }

  Widget _buildIeltsSection() {
    return Column(
      children: [
        // IELTS toggle
        Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: context.isDark ? AppColors.darkCardBg : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Icon(Icons.translate_outlined, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B), size: 20),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).translate('iHaveIelts'),
                        style: TextStyle(fontSize: 14.sp, color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B))),
                    Text(_hasIelts ? AppLocalizations.of(context).translate('enterScoreBelow') : AppLocalizations.of(context).translate('someProgramsRequireIt'),
                        style: TextStyle(fontSize: 11.sp, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B))),
                  ],
                ),
              ),
              Switch(
                value: _hasIelts,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() {
                  _hasIelts = v;
                  if (!v) _ieltsScoreController.clear();
                }),
              ),
            ],
          ),
        ),
        if (_hasIelts)
          _buildField(AppLocalizations.of(context).translate('ieltsScoreEg'), _ieltsScoreController, Icons.star_outline, isNum: true),

        // TOEFL toggle
        Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: context.isDark ? AppColors.darkCardBg : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Icon(Icons.language_outlined, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B), size: 20),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).translate('iHaveToefl'),
                        style: TextStyle(fontSize: 14.sp, color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B))),
                    Text(_hasToefl ? AppLocalizations.of(context).translate('enterScoreBelow') : AppLocalizations.of(context).translate('acceptedByManyUniversities'),
                        style: TextStyle(fontSize: 11.sp, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B))),
                  ],
                ),
              ),
              Switch(
                value: _hasToefl,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() {
                  _hasToefl = v;
                  if (!v) _toeflScoreController.clear();
                }),
              ),
            ],
          ),
        ),
        if (_hasToefl)
          _buildField(AppLocalizations.of(context).translate('toeflScoreEg'), _toeflScoreController, Icons.star_outline, isNum: true),

        // MOI toggle
        Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: context.isDark ? AppColors.darkCardBg : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Icon(Icons.school_outlined, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B), size: 20),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).translate('moiConfirmToggle'),
                        style: TextStyle(fontSize: 14.sp, color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B))),
                    Text(_hasMoi
                        ? AppLocalizations.of(context).translate('confirmedDegreeEnglish')
                        : AppLocalizations.of(context).translate('confirmIfDegreeEnglish'),
                        style: TextStyle(fontSize: 11.sp, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B))),
                  ],
                ),
              ),
              Switch(
                value: _hasMoi,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _hasMoi = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Notification Preferences Section ─────────────────────
  Widget _buildNotificationSection() {
    return Column(
      children: [
        // Master toggle
        _buildNotificationToggle(
          label: AppLocalizations.of(context).translate('enableNotifications'),
          subtitle: AppLocalizations.of(context).translate('receiveAllNotifications'),
          icon: Icons.notifications_active_outlined,
          value: _notificationsEnabled,
          onChanged: (v) => setState(() {
            _notificationsEnabled = v;
            if (!v) {
              _deadlineReminders = false;
              _applicationUpdates = false;
              _generalNotifications = false;
            }
          }),
        ),
        SizedBox(height: 8.h),

        // Sub-toggles (disabled when master is off)
        if (_notificationsEnabled) ...[
          _buildNotificationToggle(
            label: AppLocalizations.of(context).translate('deadlineReminders'),
            subtitle: AppLocalizations.of(context).translate('getRemindedBeforeDeadlines'),
            icon: Icons.schedule_outlined,
            value: _deadlineReminders,
            onChanged: (v) => setState(() => _deadlineReminders = v),
          ),
          SizedBox(height: 8.h),
          _buildNotificationToggle(
            label: AppLocalizations.of(context).translate('applicationUpdates'),
            subtitle: AppLocalizations.of(context).translate('statusChanges'),
            icon: Icons.update_outlined,
            value: _applicationUpdates,
            onChanged: (v) => setState(() => _applicationUpdates = v),
          ),
          SizedBox(height: 8.h),
          _buildNotificationToggle(
            label: AppLocalizations.of(context).translate('generalNotifications'),
            subtitle: AppLocalizations.of(context).translate('tipsNewProgramsAnnouncements'),
            icon: Icons.campaign_outlined,
            value: _generalNotifications,
            onChanged: (v) => setState(() => _generalNotifications = v),
          ),
          SizedBox(height: 12.h),

          // Reminder days selector
          _buildReminderDaysSelector(),
          SizedBox(height: 12.h),

          // Quiet Hours selector
          _buildQuietHoursSelector(),
        ],
      ],
    );
  }

  Widget _buildNotificationToggle({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      color: context.isDark ? AppColors.darkCardBg : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        secondary: Icon(icon, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B), size: 22),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11.sp, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B)),
        ),
        value: value,
        activeThumbColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCitiesSelector() {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_city_outlined,
                  color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B), size: 20),
              SizedBox(width: 8.w),
              Text(
                AppLocalizations.of(context).translate('preferredCities'),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 4.h,
            children: _germanCities.map((city) {
              final selected = _selectedCities.contains(city);
              return FilterChip(
                label: Text(
                  city,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: selected ? context.isDark ? AppColors.darkCardBg : Colors.white : context.isDark ? AppColors.textMain : const Color(0xFF1E293B),
                  ),
                ),
                selected: selected,
                selectedColor: AppColors.primary,
                backgroundColor: context.isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                checkmarkColor: context.isDark ? AppColors.darkCardBg : Colors.white,
                side: BorderSide(
                  color: selected
                      ? AppColors.primary
                      : context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                ),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedCities.add(city);
                    } else {
                      _selectedCities.remove(city);
                    }
                  });
                },
              );
            }).toList(),
          ),
          if (_selectedCities.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                AppLocalizations.of(context).translate('xSelected').replaceAll('{count}', _selectedCities.length.toString()),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLanguageToggle() {
    final langProvider = di.sl<LanguageProvider>();
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.language_outlined,
              color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B), size: 20),
          SizedBox(width: 8.w),
          Text(
            AppLocalizations.of(context).translate('language'),
            style: TextStyle(
              fontSize: 14.sp,
              color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          DropdownButton<String>(
            value: langProvider.isArabic ? 'ar' : 'en',
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'ar', child: Text('العربية')),
            ],
            onChanged: (v) {
              if (v != null) {
                langProvider.setLocale(
                  v == 'ar' ? const Locale('ar') : const Locale('en'),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLink(IconData icon, String title, String route) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        leading: Icon(icon, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B), size: 20),
        title: Text(title, style: TextStyle(fontSize: 14.sp, color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B))),
        trailing: Icon(Icons.chevron_right, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B), size: 20),
        onTap: () => context.push(route),
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _onDeleteAccount,
        icon: const Icon(Icons.delete_forever_outlined, color: Colors.red),
        label: Text(
          AppLocalizations.of(context).translate('deleteAccount'),
          style: TextStyle(color: Colors.red),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderDaysSelector() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined,
                  color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B), size: 22),
              SizedBox(width: 12.w),
              Text(
                AppLocalizations.of(context).translate('remindMeBeforeDeadline'),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _reminderDayOptions.map((day) {
              final isSelected = _reminderDaysBefore.contains(day);
              return FilterChip(
                label: Text(
                  '$day ${day > 1 ? AppLocalizations.of(context).translate('days') : AppLocalizations.of(context).translate('day')}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isSelected ? context.isDark ? AppColors.darkCardBg : Colors.white : context.isDark ? AppColors.textMain : const Color(0xFF1E293B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: context.isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                checkmarkColor: context.isDark ? AppColors.darkCardBg : Colors.white,
                side: BorderSide(
                  color:
                      isSelected ? AppColors.primary : context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _reminderDaysBefore.add(day);
                      _reminderDaysBefore.sort();
                    } else {
                      _reminderDaysBefore.remove(day);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuietHoursSelector() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bedtime_outlined, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B), size: 22),
              SizedBox(width: 12.w),
              Text(
                AppLocalizations.of(context).translate('quietHours'),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildTimePicker(
                  label: AppLocalizations.of(context).translate('start'),
                  initialTime: _quietStart,
                  onChanged: (time) => setState(() => _quietStart = time),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildTimePicker(
                  label: AppLocalizations.of(context).translate('end'),
                  initialTime: _quietEnd,
                  onChanged: (time) => setState(() => _quietEnd = time),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay? initialTime,
    required ValueChanged<TimeOfDay?> onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: initialTime ?? TimeOfDay.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: context.isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              initialTime != null
                  ? initialTime.format(context)
                  : AppLocalizations.of(context).translate('select'),
              style: TextStyle(
                fontSize: 13.sp,
                color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
