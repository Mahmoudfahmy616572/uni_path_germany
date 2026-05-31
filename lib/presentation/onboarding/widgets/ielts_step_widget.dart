import 'package:flutter/material.dart';

import '../../../core/themes/app_colors.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_states.dart';

class IeltsStepWidget extends StatelessWidget {
  final OnboardingCubit cubit;
  final OnboardingDataState state;

  const IeltsStepWidget({super.key, required this.cubit, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'English Language\nProficiency',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Have you taken the IELTS exam?',
            style: TextStyle(color: AppColors.textGrey, fontSize: 15),
          ),
          const SizedBox(height: 40),

          // خيار: نعم (Yes)
          _buildSelectionCard(
            title: 'Yes, I have an IELTS score',
            subtitle: 'You will enter your band score next',
            icon: Icons.check_circle_outline,
            isSelected: state.hasIELTS == true,
            onTap: () => cubit.updateIeltsStatus(true),
          ),

          const SizedBox(height: 16),

          // خيار: لا (No)
          _buildSelectionCard(
            title: 'No, I don\'t have one',
            subtitle: 'Skip language score requirements',
            icon: Icons.cancel_outlined,
            isSelected: state.hasIELTS == false,
            onTap: () => cubit.updateIeltsStatus(false),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textGrey,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.radio_button_checked, color: AppColors.primary)
            else
              Icon(
                Icons.radio_button_off,
                color: AppColors.textGrey.withOpacity(0.4),
              ),
          ],
        ),
      ),
    );
  }
}
