import 'package:flutter_test/flutter_test.dart';
import 'package:germany_travel/core/services/ai/gemini_service.dart';

void main() {
  group('GeminiService.hasValidFeedback', () {
    test('returns false for empty list', () {
      expect(GeminiService.hasValidFeedback([]), isFalse);
    });

    test('returns false when all suggestions are empty', () {
      final reviews = [
        {'issue': 'Test', 'suggestion': '', 'severity': 'medium'},
        {'issue': 'Test', 'suggestion': '', 'severity': 'low'},
      ];
      expect(GeminiService.hasValidFeedback(reviews), isFalse);
    });

    test('returns false when first item issue indicates no document', () {
      final reviews = [
        {'issue': 'I cannot see any document in this file', 'suggestion': 'Re-upload', 'severity': 'medium'},
      ];
      expect(GeminiService.hasValidFeedback(reviews), isFalse);
    });

    test('returns false for "no document" issue even with suggestion', () {
      final reviews = [
        {'issue': 'No document found', 'suggestion': 'Upload a valid file', 'severity': 'high'},
      ];
      expect(GeminiService.hasValidFeedback(reviews), isFalse);
    });

    test('returns true when issue is about document content, not visibility', () {
      final reviews = [
        {'issue': 'GPA is missing the grading scale', 'suggestion': 'Add the scale', 'severity': 'high'},
      ];
      expect(GeminiService.hasValidFeedback(reviews), isTrue);
    });

    test('returns true for multiple real feedback items', () {
      final reviews = [
        {'issue': 'CV lacks structure', 'suggestion': 'Use tabular format', 'severity': 'medium'},
        {'issue': 'SOP is too generic', 'suggestion': 'Name specific professors', 'severity': 'high'},
      ];
      expect(GeminiService.hasValidFeedback(reviews), isTrue);
    });

    test('returns false for list with empty map', () {
      expect(GeminiService.hasValidFeedback([<String, dynamic>{}]), isFalse);
    });
  });
}
