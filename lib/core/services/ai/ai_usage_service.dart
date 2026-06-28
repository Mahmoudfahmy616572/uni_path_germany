import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/logger.dart';
import '../auth/auth_service.dart';
import '../premium_service.dart';

class AiUsageService {
  final AuthService _authService;
  final PremiumService _premiumService;

  AiUsageService(this._authService, this._premiumService);

  Future<bool> get _isAdmin async {
    if (_authService.cachedIsAdmin) return true;
    // fallback: check from DB directly
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;
      final data = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle().timeout(const Duration(seconds: 10));
      final isAdmin = data?['role'] == 'admin';
      if (isAdmin) _authService.cachedIsAdmin = true;
      return isAdmin;
    } catch (e) {
      log.e('_isAdmin check error: $e');
      return false;
    }
  }

  static const int _freeLimit = 10;

  String _userId() =>
      Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';

  String _countKey(String uid) => '${uid}_ai_usage_count';
  String _monthKey(String uid) => '${uid}_ai_usage_month';

  int _currentMonthKey() => DateTime.now().year * 100 + DateTime.now().month;

  /// For CV/SOP generation — premium required from first use
  Future<bool> canUseGenerator() async {
    if (await _isAdmin) return true;
    return _premiumService.isPremium();
  }

  /// For document review — 10 free uses per month, then pay
  Future<bool> canUseReview() async {
    if (await _isAdmin) return true;
    if (await _premiumService.isPremium()) return true;

    final prefs = await SharedPreferences.getInstance();
    final uid = _userId();
    final currentMonth = _currentMonthKey();
    final savedMonth = prefs.getInt(_monthKey(uid)) ?? 0;

    if (currentMonth != savedMonth) {
      await prefs.setInt(_monthKey(uid), currentMonth);
      await prefs.setInt(_countKey(uid), 0);
      return true;
    }

    final count = prefs.getInt(_countKey(uid)) ?? 0;
    return count < _freeLimit;
  }

  Future<int> getRemainingUses() async {
    if (await _isAdmin) return 999;

    final prefs = await SharedPreferences.getInstance();
    final uid = _userId();
    final currentMonth = _currentMonthKey();
    final savedMonth = prefs.getInt(_monthKey(uid)) ?? 0;

    if (currentMonth != savedMonth) {
      await prefs.setInt(_monthKey(uid), currentMonth);
      await prefs.setInt(_countKey(uid), 0);
      return _freeLimit;
    }

    final count = prefs.getInt(_countKey(uid)) ?? 0;
    return (_freeLimit - count).clamp(0, _freeLimit);
  }

  Future<void> recordUsage() async {
    if (await _isAdmin) return;

    final prefs = await SharedPreferences.getInstance();
    final uid = _userId();
    final currentMonth = _currentMonthKey();
    final savedMonth = prefs.getInt(_monthKey(uid)) ?? currentMonth;

    if (currentMonth != savedMonth) {
      await prefs.setInt(_monthKey(uid), currentMonth);
      await prefs.setInt(_countKey(uid), 1);
    } else {
      final count = prefs.getInt(_countKey(uid)) ?? 0;
      await prefs.setInt(_countKey(uid), count + 1);
    }
  }

  /// Show remaining uses snackbar before AI action
  Future<void> showRemainingUses(BuildContext context) async {
    final remaining = await getRemainingUses();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You have $remaining AI uses remaining this month'),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
