import 'package:flutter_test/flutter_test.dart';
import 'package:germany_travel/core/utils/missing_doc_templates.dart';

void main() {
  group('MissingDocTemplates', () {
    test('returns all basic doc templates for student with language cert', () {
      final profile = {
        'has_ielts': true,
        'has_toefl': false,
        'has_moi': false,
      };
      final result = MissingDocTemplates.getSuggestions(profile);
      expect(result.length, greaterThanOrEqualTo(5));

      final docTypes = result.map((r) => r['doc_type']).toSet();
      expect(docTypes, contains('transcripts'));
      expect(docTypes, contains('bachelor_cert'));
      expect(docTypes, contains('sop'));
      expect(docTypes, contains('cv'));
      expect(docTypes, contains('language_cert'));

      for (final item in result) {
        expect(item.containsKey('doc_type'), isTrue);
        expect(item.containsKey('status'), isTrue);
        expect(item.containsKey('title'), isTrue);
        expect(item.containsKey('importance'), isTrue);
        expect(item.containsKey('tips'), isTrue);
        expect(item['importance'], anyOf('high', 'medium', 'low'));
        expect(item['status'], equals('missing'));
        expect(item['tips'], isA<List>());
        expect((item['tips'] as List).length, greaterThan(0));
      }
    });

    test('excludes language_cert when student has no certs', () {
      final profile = {
        'has_ielts': false,
        'has_toefl': false,
        'has_moi': false,
      };
      final result = MissingDocTemplates.getSuggestions(profile);
      final docTypes = result.map((r) => r['doc_type']).toSet();
      expect(docTypes, isNot(contains('language_cert')));
    });

    test('includes language_cert when student has MOI', () {
      final profile = {
        'has_ielts': false,
        'has_toefl': false,
        'has_moi': true,
      };
      final result = MissingDocTemplates.getSuggestions(profile);
      final docTypes = result.map((r) => r['doc_type']).toSet();
      expect(docTypes, contains('language_cert'));
    });

    test('sop tip mentions specific profile details', () {
      final profile = {
        'gpa': 3.5,
        'max_gpa': 4.0,
        'major': 'Computer Engineering',
      };
      final result = MissingDocTemplates.getSuggestions(profile);
      final sop = result.firstWhere((r) => r['doc_type'] == 'sop');
      final tips = sop['tips'] as List;
      expect(tips, isNotEmpty);
    });
  });
}
