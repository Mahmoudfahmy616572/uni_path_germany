import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  static const String _actionCountKey = 'review_action_count';
  static const String _reviewedKey = 'review_already_done';
  static const String _lastPromptKey = 'review_last_prompt';
  static const int _requiredActions = 3;

  static final InAppReview _inAppReview = InAppReview.instance;

  /// Call this after a positive user action (save program, complete review, etc.)
  static Future<void> registerPositiveAction() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyReviewed = prefs.getBool(_reviewedKey) ?? false;
    if (alreadyReviewed) return;

    final count = (prefs.getInt(_actionCountKey) ?? 0) + 1;
    await prefs.setInt(_actionCountKey, count);

    // Check if enough time has passed since last prompt (7 days)
    final lastPrompt = prefs.getInt(_lastPromptKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (lastPrompt > 0 && (now - lastPrompt) < 7 * 24 * 60 * 60 * 1000) return;

    if (count >= _requiredActions) {
      await _tryShowReview(prefs);
    }
  }

  static Future<void> _tryShowReview(SharedPreferences prefs) async {
    try {
      final available = await _inAppReview.isAvailable();
      if (available) {
        await _inAppReview.requestReview();
        await prefs.setBool(_reviewedKey, true);
        await prefs.setInt(_lastPromptKey, DateTime.now().millisecondsSinceEpoch);
      }
    } catch (_) {
      // Silently fail - review dialog is optional
    }
  }

  /// For testing: reset all review state
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_actionCountKey);
    await prefs.remove(_reviewedKey);
    await prefs.remove(_lastPromptKey);
  }
}
