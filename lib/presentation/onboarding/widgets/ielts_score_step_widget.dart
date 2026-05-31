import 'package:flutter/material.dart';

import '../../../core/themes/app_colors.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_states.dart';

class IeltsScoreStepWidget extends StatelessWidget {
  final OnboardingCubit cubit;
  final OnboardingDataState state;

  const IeltsScoreStepWidget({
    super.key,
    required this.cubit,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What is your overall\nIELTS band score?',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Drag the slider to match your certificate score',
            style: TextStyle(color: AppColors.textGrey, fontSize: 15),
          ),
          const Spacer(),

          // عرض الـ Score الحالي بشكل دائري كبير وجذاب
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 3),
              ),
              child: Center(
                child: Text(
                  state.ieltsScore.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          // الـ Slider لاختيار الـ Score بسهولة
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.inputBackground,
              trackHeight: 8.0,
              thumbColor: AppColors.primary,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14.0),
              overlayColor: AppColors.primary.withOpacity(0.2),
              valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
              valueIndicatorColor: AppColors.primary,
              valueIndicatorTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            child: Slider(
              value: state.ieltsScore >= 4.0
                  ? state.ieltsScore
                  : 6.0, // ديفولت 6.0
              min: 4.0,
              max: 9.0,
              divisions: 10, // عشان يتحرك بمقدار 0.5 في كل تكة
              label: state.ieltsScore.toStringAsFixed(1),
              onChanged: (value) => cubit.updateIeltsScore(value),
            ),
          ),

          // أرقام توضيحية تحت الـ Slider
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '4.0',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '6.5',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '9.0',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
