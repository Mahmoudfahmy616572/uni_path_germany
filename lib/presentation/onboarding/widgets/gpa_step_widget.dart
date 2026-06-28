import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/curtain_drop.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_states.dart';

class GpaStepWidget extends StatefulWidget {
  final OnboardingCubit cubit;
  final OnboardingDataState state;

  const GpaStepWidget({super.key, required this.cubit, required this.state});

  @override
  State<GpaStepWidget> createState() => _GpaStepWidgetState();
}

class _GpaStepWidgetState extends State<GpaStepWidget> {
  final TextEditingController _gpaController = TextEditingController();
  final TextEditingController _academicAvgController = TextEditingController();
  final TextEditingController _highSchoolController = TextEditingController();

  final List<String> _scales = ['4.0 Scale', '5.0 Scale', '100% Percentage'];
  String? _gpaErrorText;

  double _maxForScale(String scale) {
    if (scale == '4.0 Scale') return 4.0;
    if (scale == '5.0 Scale') return 5.0;
    return 100.0;
  }

  String? _validateGpa(String value, String scale) {
    final max = _maxForScale(scale);
    final parsed = double.tryParse(value);
    if (parsed == null) return null;
    if (parsed < 0) return 'Value cannot be negative';
    if (parsed > max) return 'Value must be ≤ $max for $scale';
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.state.gpa != 0.0) {
      _gpaController.text = widget.state.gpa.toString();
    }
    if (widget.state.academicAverage != null) {
      _academicAvgController.text = widget.state.academicAverage.toString();
    }
    if (widget.state.highSchoolScore != null) {
      _highSchoolController.text = widget.state.highSchoolScore.toString();
    }
  }

  @override
  void dispose() {
    _gpaController.dispose();
    _academicAvgController.dispose();
    _highSchoolController.dispose();
    super.dispose();
  }

  bool get _isGraduateLevel {
    final lvl = widget.state.studyLevel;
    return lvl == "Master's Degree" || lvl == 'PhD / Doctorate' || lvl == 'Graduate School';
  }

  @override
  Widget build(BuildContext context) {
    if (_isGraduateLevel) {
      return _buildGpaScreen(context);
    }
    return _buildAcademicAverageScreen(context);
  }

  // ── Master's / PhD: Full GPA screen ─────────────────────────
  Widget _buildGpaScreen(BuildContext context) {
    String currentScale = widget.state.gpaScale.isNotEmpty
        ? widget.state.gpaScale
        : '4.0 Scale';

    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurtainDrop(
            index: 0,
            child: Text(
              AppLocalizations.of(context).translate('gpaHeading'),
              style: TextStyle(
                color: context.isDark ? AppColors.textMain : AppColors.textDark,
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          CurtainDrop(
            index: 1,
            child: Text(
              AppLocalizations.of(context).translate('gpaSubtitle'),
              style: TextStyle(color: context.textMutedColor, fontSize: 15.sp),
            ),
          ),
          SizedBox(height: 32.h),
          _buildScaleDropdown(context, currentScale),
          SizedBox(height: 24.h),
          _buildGpaField(context, currentScale),
          SizedBox(height: 12.h),
          CurtainDrop(
            index: 4,
            child: Text(
              _getHintText(currentScale),
              style: TextStyle(
                color: context.textMutedColor,
                fontSize: 13.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bachelor & others: Academic screen ─────────────────────
  Widget _buildAcademicAverageScreen(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurtainDrop(
            index: 0,
            child: Text(
              'Academic Information',
              style: TextStyle(
                color: context.isDark ? AppColors.textMain : AppColors.textDark,
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          CurtainDrop(
            index: 1,
            child: Text(
              'Have you studied at a university before?',
              style: TextStyle(color: context.textMutedColor, fontSize: 15.sp),
            ),
          ),
          SizedBox(height: 24.h),
          CurtainDrop(
            index: 2,
            child: Row(
              children: [
                Expanded(
                  child: _buildToggleChoice(
                    label: 'Yes',
                    selected: widget.state.hasStudiedUniversity,
                    onTap: () => widget.cubit.updateHasStudiedUniversity(true),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildToggleChoice(
                    label: 'No',
                    selected: !widget.state.hasStudiedUniversity,
                    onTap: () => widget.cubit.updateHasStudiedUniversity(false),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          if (widget.state.hasStudiedUniversity)
            _buildField(
              controller: _academicAvgController,
              label: 'Academic Average (your current university average)',
              hint: 'e.g. 2.5',
              onChanged: (v) {
                double? parsed = double.tryParse(v);
                widget.cubit.updateAcademicAverage(parsed);
              },
            )
          else
            _buildField(
              controller: _highSchoolController,
              label: 'High School Score (e.g. Tawjihi / Thanawiya)',
              hint: 'e.g. 85.5',
              onChanged: (v) {
                double? parsed = double.tryParse(v);
                widget.cubit.updateHighSchoolScore(parsed);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required void Function(String) onChanged,
  }) {
    return CurtainDrop(
      index: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.isDark ? AppColors.textMain : AppColors.textDark,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: context.isDark ? AppColors.textMain : AppColors.textDark,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: context.textMutedColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: context.inputBgColor,
              prefixIcon: const Icon(
                Icons.analytics_outlined,
                color: AppColors.textGrey,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChoice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.r),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : context.inputBgColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textGrey,
              size: 22,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textGrey,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────
  Widget _buildScaleDropdown(BuildContext context, String currentScale) {
    return CurtainDrop(
      index: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('gpaScaleLabel'),
            style: TextStyle(
              color: context.isDark ? AppColors.textMain : AppColors.textDark,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.r),
            decoration: BoxDecoration(
              color: context.inputBgColor,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _scales.contains(currentScale) ? currentScale : _scales.first,
                isExpanded: true,
                dropdownColor: context.inputBgColor,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textGrey),
                items: _scales.map((String scale) {
                  return DropdownMenuItem<String>(
                    value: scale,
                    child: Text(
                      scale,
                      style: TextStyle(
                        color: context.isDark ? AppColors.textMain : AppColors.textDark,
                        fontSize: 16.sp,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newScale) {
                  if (newScale != null) {
                    setState(() => _gpaErrorText = null);
                    widget.cubit.updateGpa(scale: newScale);
                    _gpaController.clear();
                    widget.cubit.updateGpa(gpa: 0.0);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpaField(BuildContext context, String currentScale) {
    return CurtainDrop(
      index: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('gpaEarnedLabel'),
            style: TextStyle(
              color: context.isDark ? AppColors.textMain : AppColors.textDark,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: _gpaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: context.isDark ? AppColors.textMain : AppColors.textDark,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              hintText: currentScale == '100% Percentage' ? 'e.g. 85.5' : 'e.g. 3.4',
              hintStyle: TextStyle(
                color: context.textMutedColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: context.inputBgColor,
              prefixIcon: const Icon(Icons.analytics_outlined, color: AppColors.textGrey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
              errorText: _gpaErrorText,
              errorStyle: TextStyle(
                color: AppColors.primary,
                fontSize: 13.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _gpaErrorText = _validateGpa(value, currentScale);
              });
              if (_gpaErrorText == null) {
                double? parsedGpa = double.tryParse(value);
                if (parsedGpa != null) {
                  widget.cubit.updateGpa(gpa: parsedGpa);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  String _getHintText(String scale) {
    final t = AppLocalizations.of(context).translate;
    if (scale == '4.0 Scale') return t('gpaHint4');
    if (scale == '5.0 Scale') return t('gpaHint5');
    return t('gpaHint100');
  }
}
