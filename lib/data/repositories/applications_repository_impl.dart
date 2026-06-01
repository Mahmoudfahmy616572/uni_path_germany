import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/applications_repository.dart';
import '../models/university_model.dart';
import '../sources/applications_remote_data_source.dart';

class ApplicationsRepositoryImpl implements ApplicationsRepository {
  final ApplicationsRemoteDataSource remoteDataSource;
  ApplicationsRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> saveUniversity(String universityId) async {
    await remoteDataSource.saveUniversity(universityId);
  }

  @override
  Future<List<UniversityModel>> getMyApplications() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final List<dynamic> rawApplications = await remoteDataSource
        .getMyApplications();
    if (rawApplications.isEmpty) return [];

    final studentData = await Supabase.instance.client
        .from('profiles')
        .select(
          'gpa, max_gpa, min_gpa, has_ielts, ielts_score, target_major, has_moi',
        )
        .eq('id', user.id)
        .single();

    return rawApplications.map((item) {
      final uniData = Map<String, dynamic>.from(
        item['test_universities'] as Map<String, dynamic>,
      );

      // 🎯 السر هنا: نضمن يقيناً إن الـ id الممرر للموديل هو الـ university_id الحقيقي المربوط بالطلب
      // عشان لما الـ UI يرجعه للـ Cubit يروح للـ Supabase يطابق الـ eq('university_id') علطول!
      if (item['university_id'] != null) {
        uniData['id'] = item['university_id'].toString();
      }

      return UniversityModel.fromJson(
        uniData,
        studentProfile: studentData,
        status: item['status'] ?? 'saved',
        notes: item['notes'] ?? '',
        hasTranscripts: item['has_transcripts'] ?? false,
        hasCv: item['has_cv'] ?? false,
        hasSop: item['has_sop'] ?? false,
        hasBachelorCert: item['has_bachelor_cert'] ?? false,
      );
    }).toList();
  }

  @override
  Future<bool> checkIfSaved(String universityId) async {
    return await remoteDataSource.checkIfSaved(universityId);
  }

  @override
  Future<void> removeSavedUniversity(String universityId) async {
    await remoteDataSource.removeSavedUniversity(universityId);
    // تأخير بسيط لضمان تزامن قاعدة البيانات قبل جلب البيانات المحدثة
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> updateApplicationNotes({
    required String universityId,
    required String newNotes,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await Supabase.instance.client
          .from('my_applications')
          .update({'notes': newNotes})
          .eq('user_id', user.id)
          .eq('university_id', universityId);
    } catch (e) {
      throw Exception('Failed to update notes: ${e.toString()}');
    }
  }

  @override
  Future<void> updateApplicationDocument({
    required String universityId,
    required String columnName,
    required bool newValue,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await Supabase.instance.client
          .from('my_applications')
          .update({columnName: newValue})
          .eq('user_id', user.id)
          .eq('university_id', universityId);
    } catch (e) {
      throw Exception('Failed to update $columnName: ${e.toString()}');
    }
  }
}
