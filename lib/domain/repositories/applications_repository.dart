import 'dart:io';

import '../../domain/entities/university_entity.dart';

abstract class ApplicationsRepository {
  Future<void> saveProgram({
    required String universityId,
    required String programId,
  });
  Future<List<UniversityEntity>> getMyApplications();
  Future<void> removeSavedProgram({
    required String universityId,
    required String programId,
  });
  Future<bool> checkIfSaved(String universityId, {String? programId});
  Future<Set<String>> getSavedProgramIds(String userId, String universityId);

  // 🎯 دالة رفع الملفات الحقيقية
  Future<String> uploadDocument({
    required String universityId,
    required String columnName,
    required File file,
    void Function(double progress)? onProgress,
  });

  // 🎯 دالة تحديث الحالة (التي تسببت في الخطأ)
  Future<void> updateApplicationDocument({
    required String universityId,
    String? programId,
    required String columnName,
    required dynamic newValue, // جعلناها dynamic لتقبل bool أو String
  });

  Future<void> updateApplicationNotes({
    required String universityId,
    String? programId,
    required String newNotes,
  });

  // 🎯 تحديث حالة الطلب مع إشعار
  Future<void> updateApplicationStatus({
    required String universityId,
    required String programId,
    required String newStatus,
  });

  Future<Map<String, dynamic>?> getApplicationDetails({
    required String universityId,
    required String programId,
  });

  // 🎯 تحديث حالة بوابة التقديم والدفع
  Future<void> updatePortalStatus({
    required String universityId,
    required String programId,
    required String portalStatus,
    String? paymentStatus,
    String? portalUrl,
    String? submittedAt,
    bool? autoTrack,
  });
}
