import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Badge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool Function(Map<String, int> stats) unlocked;
  final int progressTarget;
  final String? progressLabel;

  const Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
    this.progressTarget = 1,
    this.progressLabel,
  });
}

class GamificationService {
  static const _statsPrefix = 'badge_stat_';
  static SharedPreferences? _prefs;

  static List<Badge> get badges => _buildBadges();

  static List<Badge> _buildBadges() {
    return [
      Badge(
        id: 'first_save', title: 'First Steps', description: 'Save your first university',
        icon: Icons.star_border, unlocked: (s) => (s['universities_saved'] ?? 0) >= 1,
      ),
      Badge(
        id: 'app_starter', title: 'Application Starter', description: 'Submit your first application',
        icon: Icons.send, unlocked: (s) => (s['applications_submitted'] ?? 0) >= 1,
      ),
      Badge(
        id: 'doc_collector', title: 'Document Collector', description: 'Upload your first document',
        icon: Icons.description, unlocked: (s) => (s['documents_uploaded'] ?? 0) >= 1,
      ),
      Badge(
        id: 'deadline_watcher', title: 'Deadline Watcher', description: 'Check deadlines regularly',
        icon: Icons.notifications_active, unlocked: (s) => (s['deadlines_checked'] ?? 0) >= 3,
        progressTarget: 3,
      ),
      Badge(
        id: 'profile_complete', title: 'Profile Pro', description: 'Complete your profile',
        icon: Icons.person, unlocked: (s) => (s['profile_completed'] ?? 0) >= 1,
      ),
      Badge(
        id: 'super_saver', title: 'Super Saver', description: 'Save 5 universities',
        icon: Icons.bookmark, unlocked: (s) => (s['universities_saved'] ?? 0) >= 5,
        progressTarget: 5, progressLabel: 'saved',
      ),
      Badge(
        id: 'applicant_pro', title: 'Applicant Pro', description: 'Apply to 3 programs',
        icon: Icons.fact_check, unlocked: (s) => (s['applications_submitted'] ?? 0) >= 3,
        progressTarget: 3, progressLabel: 'submitted',
      ),
      Badge(
        id: 'explorer', title: 'Explorer', description: 'Explore the app features',
        icon: Icons.explore, unlocked: (s) => (s['screens_visited'] ?? 0) >= 5,
        progressTarget: 5, progressLabel: 'screens',
      ),
      Badge(
        id: 'cv_uploaded', title: 'CV Ready', description: 'Upload your CV',
        icon: Icons.article, unlocked: (s) => (s['cv_uploaded'] ?? 0) >= 1,
      ),
      Badge(
        id: 'ten_saved', title: 'University Collector', description: 'Save 10 universities',
        icon: Icons.collections_bookmark, unlocked: (s) => (s['universities_saved'] ?? 0) >= 10,
        progressTarget: 10, progressLabel: 'saved',
      ),
    ];
  }

  static void _ensurePrefs() {
    if (_prefs != null) return;
    throw StateError('GamificationService not initialized. Call GamificationService.init() first.');
  }

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> incrementStat(String stat) async {
    _prefs ??= await SharedPreferences.getInstance();
    final key = '$_statsPrefix$stat';
    final current = _prefs!.getInt(key) ?? 0;
    await _prefs!.setInt(key, current + 1);
  }

  static int getStat(String stat) {
    _ensurePrefs();
    return _prefs?.getInt('$_statsPrefix$stat') ?? 0;
  }

  static Map<String, int> get allStats {
    _ensurePrefs();
    final map = <String, int>{};
    for (final badge in badges) {
      final key = statKeyFor(badge.id);
      if (key != null && !map.containsKey(key)) map[key] = getStat(key);
    }
    // Ensure all possible stats are included
    const allPossible = [
      'universities_saved', 'applications_submitted', 'documents_uploaded',
      'deadlines_checked', 'profile_completed', 'screens_visited', 'cv_uploaded',
    ];
    for (final s in allPossible) {
      if (!map.containsKey(s)) map[s] = getStat(s);
    }
    return map;
  }

  static String? statKeyFor(String badgeId) {
    switch (badgeId) {
      case 'first_save': case 'super_saver': case 'ten_saved': return 'universities_saved';
      case 'app_starter': case 'applicant_pro': return 'applications_submitted';
      case 'doc_collector': return 'documents_uploaded';
      case 'deadline_watcher': return 'deadlines_checked';
      case 'profile_complete': return 'profile_completed';
      case 'explorer': return 'screens_visited';
      case 'cv_uploaded': return 'cv_uploaded';
      default: return null;
    }
  }

  static List<Badge> getEarnedBadges() {
    final stats = allStats;
    return badges.where((b) => b.unlocked(stats)).toList();
  }

  static double get overallProgress {
    final stats = allStats;
    final earned = badges.where((b) => b.unlocked(stats)).length;
    return badges.isEmpty ? 0 : earned / badges.length;
  }

  static int get earnedCount => getEarnedBadges().length;
  static int get totalCount => badges.length;
}
