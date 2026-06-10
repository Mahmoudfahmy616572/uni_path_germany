import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/services/services_locator.dart';
import '../../../core/utils/requirements_check_list.dart';
import '../../../domain/entities/university_entity.dart';
import '../../UniversityDetails/cubit/university_details_cubit.dart';

class DocumentsScreen extends StatelessWidget {
  final UniversityEntity userFiles;

  const DocumentsScreen({super.key, required this.userFiles});

  @override
  Widget build(BuildContext context) {
    // 🎯 السحر هنا: تغليف الشاشة بالكيوبيت المسؤول عن الرفع لضمان عدم حدوث الخطأ الأحمر
    return BlocProvider(
      create: (context) => sl<UniversityDetailsCubit>()
        ..initializeUniversityData(
          percentage: 0,
          programs: [],
          university: userFiles,
        ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            "My Document Vault",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Global Documents",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Files uploaded here will automatically be used for all your German university applications.",
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 24.h),

              // الآن سيجد هذا الويدجيت الـ Cubit فوقه مباشرة ولن يحدث Error
              RequirementsChecklistList(university: userFiles),
            ],
          ),
        ),
      ),
    );
  }
}
