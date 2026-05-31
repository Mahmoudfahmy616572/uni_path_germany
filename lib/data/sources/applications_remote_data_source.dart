import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ApplicationsRemoteDataSource {
  Future<void> saveUniversity(String universityId);
  Future<List<Map<String, dynamic>>> getMyApplications();
  Future<void> removeSavedUniversity(String universityId);
  Future<bool> checkIfSaved(String universityId);
}

class ApplicationsRemoteDataSourceImpl implements ApplicationsRemoteDataSource {
  final SupabaseClient client;
  ApplicationsRemoteDataSourceImpl(this.client);

  @override
  Future<void> saveUniversity(String universityId) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    await client.from('my_applications').insert({
      'user_id': user.id,
      'university_id': universityId,
      'status': 'saved',
      'created_at': DateTime.now().toIso8601String(), // للتأكد من الترتيب
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getMyApplications() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // التعديل: الترتيب يجبر الكاش على التحديث
      final response = await client
          .from('my_applications')
          .select('*, test_universities(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception("Failed to fetch applications: $e");
    }
  }

  @override
  Future<bool> checkIfSaved(String universityId) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await client
        .from('my_applications')
        .select('id')
        .eq('user_id', userId)
        .eq('university_id', universityId)
        .maybeSingle();

    return response != null;
  }

  @override
  Future<void> removeSavedUniversity(String universityId) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    await client
        .from('my_applications')
        .delete()
        .eq('user_id', userId)
        .eq('university_id', universityId);
  }
}
