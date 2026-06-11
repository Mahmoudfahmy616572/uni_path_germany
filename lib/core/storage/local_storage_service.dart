// lib/core/storage/local_storage_service.dart
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'hive_models.dart';

class LocalStorageService {
  static const String _credentialsBox = 'user_credentials';
  static const String _universitiesBox = 'cached_universities';
  static const String _programsBox = 'cached_programs';

  static late Box<CachedUserCredentials> _credentialsBoxInstance;
  static late Box<CachedUniversity> _universitiesBoxInstance;
  static late Box<CachedProgram> _programsBoxInstance;

  static Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);

    Hive.registerAdapter(CachedUserCredentialsAdapter());
    Hive.registerAdapter(CachedUniversityAdapter());
    Hive.registerAdapter(CachedProgramAdapter());

    _credentialsBoxInstance = await Hive.openBox<CachedUserCredentials>(_credentialsBox);
    _universitiesBoxInstance = await Hive.openBox<CachedUniversity>(_universitiesBox);
    _programsBoxInstance = await Hive.openBox<CachedProgram>(_programsBox);
  }

  // ─── User Credentials ───

  static Future<void> saveCredentials({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    if (!rememberMe) {
      await clearCredentials();
      return;
    }

    final credentials = CachedUserCredentials(
      email: email,
      password: password,
      rememberMe: rememberMe,
      lastUpdated: DateTime.now(),
    );

    await _credentialsBoxInstance.put('current_user', credentials);
  }

  static CachedUserCredentials? getCredentials() {
    return _credentialsBoxInstance.get('current_user');
  }

  static Future<void> clearCredentials() async {
    await _credentialsBoxInstance.delete('current_user');
  }

  static bool get hasSavedCredentials {
    final creds = _credentialsBoxInstance.get('current_user');
    return creds != null && creds.rememberMe;
  }

  // ─── Universities Cache ───

  static Future<void> cacheUniversities(List<CachedUniversity> universities) async {
    await _universitiesBoxInstance.clear();
    for (final uni in universities) {
      await _universitiesBoxInstance.put(uni.id, uni);
    }
  }

  static List<CachedUniversity> getCachedUniversities() {
    return _universitiesBoxInstance.values.toList();
  }

  static bool get hasCachedUniversities => _universitiesBoxInstance.isNotEmpty;

  // ─── Programs Cache ───

  static Future<void> cachePrograms(List<CachedProgram> programs) async {
    await _programsBoxInstance.clear();
    for (final program in programs) {
      await _programsBoxInstance.put(program.id, program);
    }
  }

  static List<CachedProgram> getCachedPrograms() {
    return _programsBoxInstance.values.toList();
  }

  static List<CachedProgram> getCachedProgramsForUniversity(String universityId) {
    return _programsBoxInstance.values
        .where((p) => p.universityId == universityId)
        .toList();
  }

  // ─── Clear All ───

  static Future<void> clearAll() async {
    await _credentialsBoxInstance.clear();
    await _universitiesBoxInstance.clear();
    await _programsBoxInstance.clear();
  }
}