import 'package:hive/hive.dart';

import '../../utils/logger.dart';

/// Caches AI review results locally using Hive so re-reviewing unchanged
/// files doesn't call the Gemini API again.
///
/// Each doc_type maps to {url, timestamp, reviews} inside the Hive box.
class ReviewCacheService {
  static const _boxName = 'ai_review_cache';
  Box? _box;

  Future<Box> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox(_boxName);
    return _box!;
  }

  Future<void> storeReview({
    required String docType,
    required String url,
    required List<Map<String, dynamic>> reviews,
  }) async {
    final box = await _getBox();
    await box.put(docType, {
      'url': url,
      'timestamp': DateTime.now().toIso8601String(),
      'reviews': reviews,
    });
  }

  Future<List<Map<String, dynamic>>?> getCachedReview({
    required String docType,
    required String currentUrl,
  }) async {
    final box = await _getBox();
    final entry = box.get(docType);
    if (entry == null) return null;
    try {
      final cachedUrl = entry['url']?.toString() ?? '';
      if (cachedUrl != currentUrl) return null;
      final reviews = entry['reviews'];
      if (reviews is! List) return null;
      return reviews.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      log.e('getCachedReview error: $e');
      return null;
    }
  }

  Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
  }
}
