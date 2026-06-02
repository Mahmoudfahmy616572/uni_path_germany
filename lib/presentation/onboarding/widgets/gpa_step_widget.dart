import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/themes/app_colors.dart';
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

  final List<String> _scales = ['4.0 Scale', '5.0 Scale', '100% Percentage'];

  @override
  void initState() {
    super.initState();
    // لو فيه قيمة متسيفة مسبقاً حطها في الـ Controller
    if (widget.state.gpa != 0.0) {
      _gpaController.text = widget.state.gpa.toString();
    }
  }

  @override
  void dispose() {
    _gpaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // تحديد الـ Scale الحالي أو اختيار الافتراضي (4.0) لو فاضي
    String currentScale = widget.state.gpaScale.isNotEmpty
        ? widget.state.gpaScale
        : '4.0 Scale';

    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Academic\nPerformance',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Enter your cumulative GPA or percentage',
            style: TextStyle(color: AppColors.textGrey, fontSize: 15.sp),
          ),
          SizedBox(height: 32.h),

          // 1️⃣ اختيار نظام الـ Scale
          Text(
            'GPA Scale System',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.r),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _scales.contains(currentScale)
                    ? currentScale
                    : _scales.first,
                isExpanded: true,
                dropdownColor: AppColors.inputBackground,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textGrey,
                ),
                items: _scales.map((String scale) {
                  return DropdownMenuItem<String>(
                    value: scale,
                    child: Text(
                      scale,
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16.sp,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newScale) {
                  if (newScale != null) {
                    widget.cubit.updateGpa(scale: newScale);
                    // تصفير الخانة لو غير النظام عشان الـ Validation
                    _gpaController.clear();
                    widget.cubit.updateGpa(gpa: 0.0);
                  }
                },
              ),
            ),
          ),

          SizedBox(height: 24.h),

          // 2️⃣ حقل إدخال الـ GPA الرقمي
          Text(
            'Earned GPA / Score',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: _gpaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
            inputFormatters: [
              // بيسمح بالأرقام والنقطة العشرية بس
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              hintText: currentScale == '100% Percentage'
                  ? 'e.g. 85.5'
                  : 'e.g. 3.4',
              hintStyle: TextStyle(
                color: AppColors.textGrey,
                fontSize: 16.sp,
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: AppColors.inputBackground,
              prefixIcon: const Icon(
                Icons.analytics_outlined,
                color: AppColors.textGrey,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              double? parsedGpa = double.tryParse(value);
              if (parsedGpa != null) {
                widget.cubit.updateGpa(gpa: parsedGpa);
              }
            },
          ),

          SizedBox(height: 12.h),
          // نص توضيحي صغير بناءً على السكيل المختار
          Text(
            _getHintText(currentScale),
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 13.sp,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _getHintText(String scale) {
    if (scale == '4.0 Scale') return 'Enter a value between 0.0 and 4.0';
    if (scale == '5.0 Scale') return 'Enter a value between 0.0 and 5.0';
    return 'Enter your overall percentage (0 - 100)';
  }
}
