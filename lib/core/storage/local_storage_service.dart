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

  // ─── Raw JSON Universities Cache ───

  static const String _rawCacheBox = 'universities_raw';
  static Box? _rawCacheBoxInstance;

  static Future<Box> _getRawCacheBox() async {
    if (_rawCacheBoxInstance != null && _rawCacheBoxInstance!.isOpen) return _rawCacheBoxInstance!;
    _rawCacheBoxInstance = await Hive.openBox(_rawCacheBox);
    return _rawCacheBoxInstance!;
  }

  static Future<void> cacheRawUniversities(String jsonData) async {
    final box = await _getRawCacheBox();
    await box.put('data', jsonData);
    await box.put('timestamp', DateTime.now().toIso8601String());
  }

  static Future<String?> getRawCachedUniversities() async {
    final box = await _getRawCacheBox();
    final timestamp = box.get('timestamp');
    if (timestamp == null) return null;
    final cached = DateTime.tryParse(timestamp.toString());
    if (cached == null) return null;
    if (DateTime.now().difference(cached).inHours > 1) return null;
    return box.get('data')?.toString();
  }

  // ─── Offline Mode Support ───

  static const String _offlineBox = 'offline_data';
  static Box? _offlineBoxInstance;

  static Future<Box> _getOfflineBox() async {
    if (_offlineBoxInstance != null && _offlineBoxInstance!.isOpen) return _offlineBoxInstance!;
    _offlineBoxInstance = await Hive.openBox(_offlineBox);
    return _offlineBoxInstance!;
  }

  /// Track the last time the user was online (for offline data staleness)
  static Future<void> markOnline() async {
    final box = await _getOfflineBox();
    await box.put('last_online', DateTime.now().toIso8601String());
    await box.put('is_offline', false);
  }

  static Future<bool> get isOffline async {
    final box = await _getOfflineBox();
    return box.get('is_offline', defaultValue: true) as bool;
  }

  static Future<void> setOffline(bool value) async {
    final box = await _getOfflineBox();
    await box.put('is_offline', value);
  }

  static Future<DateTime?> get lastOnline async {
    final box = await _getOfflineBox();
    final ts = box.get('last_online') as String?;
    if (ts == null) return null;
    return DateTime.tryParse(ts);
  }

  /// Queue an action to be executed when online
  static Future<void> queueAction(Map<String, dynamic> action) async {
    final box = await _getOfflineBox();
    final pending = _getPendingActions(box);
    pending.add(action);
    await box.put('pending_actions', pending);
  }

  static List<Map<String, dynamic>> getPendingQueue() {
    final box = _offlineBoxInstance;
    if (box == null) return [];
    return _getPendingActions(box);
  }

  static Future<void> clearPendingQueue() async {
    final box = await _getOfflineBox();
    await box.put('pending_actions', <Map<String, dynamic>>[]);
  }

  static List<Map<String, dynamic>> _getPendingActions(Box box) {
    final raw = box.get('pending_actions');
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  /// Cache data for offline use (generic key-value)
  static Future<void> cacheOfflineData(String key, dynamic data) async {
    final box = await _getOfflineBox();
    await box.put('data_$key', data);
    await box.put('data_${key}_ts', DateTime.now().toIso8601String());
  }

  static Future<T?> getOfflineData<T>(String key, {Duration maxAge = const Duration(hours: 24)}) async {
    final box = await _getOfflineBox();
    final ts = box.get('data_${key}_ts') as String?;
    if (ts == null) return null;
    final cached = DateTime.tryParse(ts);
    if (cached == null) return null;
    if (DateTime.now().difference(cached) > maxAge) return null;
    return box.get('data_$key') as T?;
  }

  /// Check if app has fresh offline data available
  static Future<bool> hasOfflineData(String key) async {
    final box = await _getOfflineBox();
    return box.containsKey('data_$key') && box.containsKey('data_${key}_ts');
  }

  // ─── Onboarding Status ───

  static Future<void> markOnboardingComplete() async {
    final box = await _getOfflineBox();
    await box.put('onboarding_complete', true);
  }

  static Future<bool> isOnboardingComplete() async {
    final box = await _getOfflineBox();
    return box.get('onboarding_complete', defaultValue: false) as bool;
  }

  // ─── Clear All ───

  static Future<void> clearAll() async {
    await _credentialsBoxInstance.clear();
    await _universitiesBoxInstance.clear();
    await _programsBoxInstance.clear();
    final box = await _getOfflineBox();
    await box.clear();
  }
}