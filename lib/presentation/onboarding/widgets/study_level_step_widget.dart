import 'package:flutter/material.dart';
import 'package:germany_travel/presentation/onboarding/cubit/onboarding_cubit.dart';

import '../../../core/themes/app_colors.dart';
import '../cubit/onboarding_states.dart';

class StudyLevelStepWidget extends StatelessWidget {
  final OnboardingCubit cubit;
  final OnboardingDataState state;

  const StudyLevelStepWidget({
    super.key,
    required this.cubit,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final levels = [
      {
        'title': 'Bachelor\'s Degree',
        'sub': 'Undergraduate programs',
        'icon': Icons.school_outlined,
      },
      {
        'title': 'Master\'s Degree',
        'sub': 'Postgraduate programs',
        'icon': Icons.workspace_premium_outlined,
      },
      {
        'title': 'PhD / Doctorate',
        'sub': 'Research programs',
        'icon': Icons.biotech_outlined,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What level of study are\nyou looking for?',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can select your target degree',
            style: TextStyle(color: AppColors.textGrey, fontSize: 15),
          ),
          const SizedBox(height: 32),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: levels.length,
            itemBuilder: (context, index) {
              final level = levels[index];
              final isSelected = state.studyLevel == level['title'];

              return GestureDetector(
                onTap: () => cubit.updateStudyLevel(level['title'] as String),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.08)
                        : AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        level['icon'] as IconData,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textGrey,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level['title'] as String,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            level['sub'] as String,
                            style: const TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 22,
                        )
                      else
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.textGrey.withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
