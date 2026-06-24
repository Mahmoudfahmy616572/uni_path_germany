import 'package:supabase_flutter/supabase_flutter.dart';

class PremiumService {
  final SupabaseClient _supabase;

  PremiumService(this._supabase);

  Future<bool> isPremium() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('profiles')
          .select('premium_until, role')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return false;

      if (response['role'] == 'admin') return true;

      final premiumUntil = response['premium_until'] as String?;
      if (premiumUntil == null) return false;

      final until = DateTime.tryParse(premiumUntil);
      if (until == null) return false;

      return until.isAfter(DateTime.now());
    } on PostgrestException {
      return false;
    }
  }

  Future<DateTime?> getPremiumExpiry() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select('premium_until')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return null;

      final premiumUntil = response['premium_until'] as String?;
      if (premiumUntil == null) return null;

      return DateTime.tryParse(premiumUntil);
    } on PostgrestException {
      return null;
    }
  }

  Future<void> activatePremium(String plan) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final now = DateTime.now();
    DateTime premiumUntil;

    switch (plan) {
      case 'monthly':
        premiumUntil = DateTime(now.year, now.month + 1, now.day);
        break;
      case 'yearly':
        premiumUntil = DateTime(now.year + 1, now.month, now.day);
        break;
      case 'lifetime':
        premiumUntil = DateTime(now.year + 100, now.month, now.day);
        break;
      default:
        throw Exception('Unknown plan: $plan');
    }

    await _supabase.from('profiles').update({
      'premium_until': premiumUntil.toUtc().toIso8601String(),
      'premium_plan': plan,
    }).eq('id', user.id);
  }
}
