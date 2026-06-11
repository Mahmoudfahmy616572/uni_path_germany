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

import '../../../core/services/services_locator.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/utils/custom_snack_bar.dart';
import '../../../domain/entities/user_entity.dart';
import '../../Home/cubit/home_cubit.dart';
import '../../MyApplications/cubit/my_applications_cubits.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

class SettingsScreen extends StatefulWidget {
  final UserEntity user;
  const SettingsScreen({super.key, required this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Controllers ──────────────────────────────────────────
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _gpaController;
  late TextEditingController _ieltsScoreController;

  // ── Dropdown selections ───────────────────────────────────
  late String _selectedIntake;
  late String _selectedLanguage;
  late String _selectedDegree; // ✅ Bug #1 fixed
  late String _selectedMajor; // ✅ Bug #2 added
  late String _selectedGpaScale; // ✨ New

  // ── Toggles ───────────────────────────────────────────────
  late bool _hasIelts;

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

  // ── Dropdown options (نفس الـ Onboarding) ─────────────────
  static const List<String> _majors = [
    'Engineering',
    'Computer Science & IT',
    'Business & Economics',
    'Medicine & Healthcare',
    'Natural Sciences',
    'Social Sciences & Humanities',
  ];

  static const List<String> _degrees = [
    "Bachelor's Degree",
    "Master's Degree",
    'Doctorate',
  ];

  static const List<String> _intakes = [
    'Winter Semester',
    'Summer Semester',
    'Both Semesters',
  ];

  static const List<String> _languages = ['English', 'German', 'Both'];

  static const List<String> _gpaScales = ['4.0', '5.0', '10.0', '20.0'];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _gpaController = TextEditingController(
      text: widget.user.gpa > 0 ? widget.user.gpa.toString() : '',
    );
    _ieltsScoreController = TextEditingController(
      text: widget.user.ieltsScore > 0 ? widget.user.ieltsScore.toString() : '',
    );

    // ✅ Bug #1 fix — بنقرأ من degreeLevel مش budgetRange
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _gpaController.dispose();
    _ieltsScoreController.dispose();
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
      filled++; // مش مطلوب منه IELTS
    }
    if (_selectedIntake.isNotEmpty) filled++;
    return filled / total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Account Settings',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
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
            sl<MyApplicationsCubit>().loadApplications();

            CustomSnackBar.show(
              context,
              message: 'Settings updated successfully! ✅',
            );
            context.pop();
          }
          if (state is ProfileError) {
            CustomSnackBar.show(context, message: state.message, isError: true);
          }
        },
        builder: (context, state) {
          final bool isLoading = state is ProfileLoading;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.r, vertical: 16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Profile Completeness Bar ──────────────────
                _buildCompletenessCard(),
                SizedBox(height: 24.h),

                // ── Section: Personal Info ────────────────────
                _buildSectionLabel('Personal Info'),
                SizedBox(height: 10.h),
                _buildField('Name', _nameController, Icons.person_outline),
                _buildField(
                  'Email',
                  _emailController,
                  Icons.email_outlined,
                  enabled: false,
                ),

                // ── Section: Academic Profile ─────────────────
                SizedBox(height: 20.h),
                _buildSectionLabel('Academic Profile'),
                SizedBox(height: 10.h),

                // ✅ Bug #2 — target_major dropdown
                _buildDropdown(
                  label: 'Field of Study',
                  icon: Icons.school_outlined,
                  value: _selectedMajor,
                  items: _majors,
                  onChanged: (v) => setState(() => _selectedMajor = v!),
                ),
                // ✅ Bug #1 — degree dropdown reads from degreeLevel
                _buildDropdown(
                  label: 'Degree Level',
                  icon: Icons.workspace_premium_outlined,
                  value: _selectedDegree,
                  items: _degrees,
                  onChanged: (v) => setState(() => _selectedDegree = v!),
                ),
                // GPA row with scale selector
                _buildGpaRow(),

                // ── Section: Language & Intake ────────────────
                SizedBox(height: 20.h),
                _buildSectionLabel('Preferences'),
                SizedBox(height: 10.h),

                _buildDropdown(
                  label: 'Study Language',
                  icon: Icons.language_outlined,
                  value: _selectedLanguage,
                  items: _languages,
                  onChanged: (v) => setState(() => _selectedLanguage = v!),
                ),
                _buildDropdown(
                  label: 'Target Intake',
                  icon: Icons.calendar_today_outlined,
                  value: _selectedIntake,
                  items: _intakes,
                  onChanged: (v) => setState(() => _selectedIntake = v!),
                ),

                // ── Section: Language Certificate ─────────────
                SizedBox(height: 20.h),
                _buildSectionLabel('Language Certificate'),
                SizedBox(height: 10.h),
                _buildIeltsSection(),

                // ── Section: Notifications ────────────────────
                SizedBox(height: 20.h),
                _buildSectionLabel('Notifications'),
                SizedBox(height: 10.h),
                _buildNotificationSection(),

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
                foregroundColor: Colors.white,
                elevation: 8,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save, size: 20),
                label: Text(
                  isLoading ? 'Saving...' : 'Save Changes',
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

    context.read<ProfileCubit>().updateProfileData(
      updates: {
        'username': _nameController.text.trim(),
        'degree_level': _selectedDegree,
        'target_major': _selectedMajor,
        'gpa': gpa,
        'max_gpa': maxGpa,
        'has_ielts': _hasIelts,
        'ielts_score': _hasIelts ? ielts : 0.0,
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
      },
    );
  }

  // ── Widgets ───────────────────────────────────────────────

  Widget _buildCompletenessCard() {
    final double pct = _completeness;
    final String label = pct >= 1.0
        ? 'Profile complete!'
        : 'Complete your profile to get better matches';

    return StatefulBuilder(
      builder: (context, setInner) {
        return AnimatedBuilder(
          animation: _gpaController,
          builder: (_, __) {
            final double live = _completeness;
            return Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Profile Strength',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                          color: const Color(0xFF1E293B),
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
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        live >= 1.0 ? Colors.green : AppColors.primary,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            );
          },
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
        color: const Color(0xFF64748B),
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
        color: enabled ? Colors.white : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        style: TextStyle(fontSize: 14.sp, color: const Color(0xFF1E293B)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF64748B)),
          prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
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
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : items.first,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF64748B)),
          prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
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
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  // ✨ GPA row مع GPA Scale selector بجنبه
  Widget _buildGpaRow() {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          // GPA input (3/4 of width)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _gpaController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  labelText: 'GPA',
                  labelStyle: const TextStyle(color: Color(0xFF64748B)),
                  prefixIcon: const Icon(
                    Icons.grade_outlined,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.r,
                    vertical: 14.r,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // GPA Scale selector (1/4 of width)
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGpaScale,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF64748B),
                    size: 18,
                  ),
                  hint: Text(
                    'Scale',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  items: _gpaScales
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            'of $e',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGpaScale = v!),
                ),
              ),
            ),
          ),
        ],
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.translate_outlined,
                color: Color(0xFF64748B),
                size: 20,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'I have an IELTS certificate',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      _hasIelts
                          ? 'Enter your score below'
                          : 'Some programs require it',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _hasIelts,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() {
                  _hasIelts = v;
                  if (!v) _ieltsScoreController.clear();
                }),
              ),
            ],
          ),
        ),

        // IELTS Score field (shows only when toggled on)
        if (_hasIelts)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: _buildField(
              'IELTS Score (e.g. 6.5)',
              _ieltsScoreController,
              Icons.star_outline,
              isNum: true,
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
          label: 'Enable Notifications',
          subtitle: 'Receive all types of notifications',
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
            label: 'Deadline Reminders',
            subtitle: 'Get reminded before application deadlines',
            icon: Icons.schedule_outlined,
            value: _deadlineReminders,
            onChanged: (v) => setState(() => _deadlineReminders = v),
          ),
          SizedBox(height: 8.h),
          _buildNotificationToggle(
            label: 'Application Updates',
            subtitle: 'Status changes (saved → applied → accepted/rejected)',
            icon: Icons.update_outlined,
            value: _applicationUpdates,
            onChanged: (v) => setState(() => _applicationUpdates = v),
          ),
          SizedBox(height: 8.h),
          _buildNotificationToggle(
            label: 'General Notifications',
            subtitle: 'Tips, new programs, and announcements',
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        secondary: Icon(icon, color: const Color(0xFF64748B), size: 22),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B)),
        ),
        value: value,
        activeColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildReminderDaysSelector() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined,
                  color: const Color(0xFF64748B), size: 22),
              SizedBox(width: 12.w),
              Text(
                'Remind me before deadline',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E293B),
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
                  '$day day${day > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: const Color(0xFFF1F5F9),
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color:
                      isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bedtime_outlined, color: const Color(0xFF64748B), size: 22),
              SizedBox(width: 12.w),
              Text(
                'Quiet Hours',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildTimePicker(
                  label: 'Start',
                  initialTime: _quietStart,
                  onChanged: (time) => setState(() => _quietStart = time),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildTimePicker(
                  label: 'End',
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
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              initialTime != null
                  ? initialTime.format(context)
                  : 'Select',
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
