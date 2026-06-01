import '../../data/models/university_model.dart';

abstract class ApplicationsRepository {
  Future<void> saveUniversity(String universityId);
  Future<List<UniversityModel>> getMyApplications();
  Future<void> removeSavedUniversity(String universityId);
  Future<bool> checkIfSaved(String universityId);
  Future<void> updateApplicationDocument({
    required String universityId,
    required String columnName,
    required bool newValue,
  });
  Future<void> updateApplicationNotes({
    required String universityId,
    required String newNotes,
  });
}
