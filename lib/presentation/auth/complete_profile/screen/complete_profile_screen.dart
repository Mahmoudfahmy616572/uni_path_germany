import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/complete_profile_cubit.dart';
import '../cubit/complete_profile_state.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({Key? key}) : super(key: key);

  @override
  _CompleteProfileScreenState createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _gpaController = TextEditingController();
  final _ieltsController = TextEditingController();
  bool _hasIelts = false;
  double _maxGpa = 4.0; // 👈 قيمة افتراضية للـ maxGpa
  double _minGpa = 1.0; // 👈 قيمة افتراضية للـ minGpa
  bool _hasMoi = false;
  String _selectedMajor = 'Computer Science';
  String _selectedCountry = 'Germany';

  final List<String> _majors = [
    'Computer Science',
    'Engineering',
    'Business',
    'Medicine',
  ];

  final List<String> _countries = ['Germany', 'France', 'Canada', 'USA'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<CompleteProfileCubit, CompleteProfileState>(
        listener: (context, state) {
          if (state is CompleteProfileSuccess) {
            // بنجمع البيانات اللي اليوزر دخلها في الشاشة الحالية
            final profileData = {
              'gpa': double.tryParse(_gpaController.text) ?? 0.0,
              'hasIelts': _hasIelts,
              'ieltsScore': double.tryParse(_ieltsController.text),
              'targetMajor': _selectedMajor,
              'targetCountry': _selectedCountry,
            };

            // بنباصيها للراوتر في الـ extra
            context.go('/register', extra: profileData);
          } else if (state is CompleteProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Set Your Academic Profile 🚀",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Let AI customize your university match score.",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                const Text(
                  "Your GPA",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _gpaController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: "e.g., 3.75",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    "Do you have an IELTS score?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  value: _hasIelts,
                  activeColor: const Color(0xFF4F46E5),
                  onChanged: (val) => setState(() => _hasIelts = val),
                ),

                if (_hasIelts) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ieltsController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter Score (e.g., 6.5)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                const Text(
                  "Target Major",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedMajor,
                  items: _majors
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedMajor = val!),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                BlocBuilder<CompleteProfileCubit, CompleteProfileState>(
                  builder: (context, state) {
                    if (state is CompleteProfileLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final gpa =
                              double.tryParse(_gpaController.text) ?? 0.0;
                          final ielts = _hasIelts
                              ? (double.tryParse(_ieltsController.text) ?? 0.0)
                              : 0.0;

                          context
                              .read<CompleteProfileCubit>()
                              .submitProfileData(
                                gpa: gpa,
                                maxGpa: _maxGpa,
                                minGpa: _minGpa,
                                hasMoi: _hasMoi,
                                hasIelts: _hasIelts,
                                ieltsScore: ielts,
                                targetMajor: _selectedMajor,
                                targetCountry: _selectedCountry,
                              );
                        },
                        child: const Text(
                          "Calculate My Matches 🎯",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
