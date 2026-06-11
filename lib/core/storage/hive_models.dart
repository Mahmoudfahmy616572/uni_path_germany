// lib/core/storage/hive_models.dart
import 'package:hive/hive.dart';

part 'hive_models.g.dart';

@HiveType(typeId: 0)
class CachedUserCredentials extends HiveObject {
  @HiveField(0)
  String email;

  @HiveField(1)
  String password;

  @HiveField(2)
  bool rememberMe;

  @HiveField(3)
  DateTime lastUpdated;

  CachedUserCredentials({
    required this.email,
    required this.password,
    required this.rememberMe,
    required this.lastUpdated,
  });
}

@HiveType(typeId: 1)
class CachedUniversity extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int matchPercentage;

  @HiveField(3)
  String logoText;

  @HiveField(4)
  String country;

  @HiveField(5)
  String logoUrl;

  @HiveField(6)
  String imageUrl;

  @HiveField(7)
  String location;

  @HiveField(8)
  DateTime cachedAt;

  CachedUniversity({
    required this.id,
    required this.name,
    required this.matchPercentage,
    required this.logoText,
    required this.country,
    this.logoUrl = '',
    this.imageUrl = '',
    this.location = '',
    required this.cachedAt,
  });
}

@HiveType(typeId: 2)
class CachedProgram extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String universityId;

  @HiveField(2)
  String programName;

  @HiveField(3)
  String major;

  @HiveField(4)
  double requiredGpa;

  @HiveField(5)
  bool requiresIelts;

  @HiveField(6)
  double minIeltsScore;

  @HiveField(7)
  bool acceptsMoi;

  @HiveField(8)
  String instructionLanguage;

  @HiveField(9)
  String degreeType;

  @HiveField(10)
  String intakeType;

  @HiveField(11)
  int matchScore;

  @HiveField(12)
  bool isRecommended;

  @HiveField(13)
  DateTime cachedAt;

  CachedProgram({
    required this.id,
    required this.universityId,
    required this.programName,
    required this.major,
    required this.requiredGpa,
    required this.requiresIelts,
    required this.minIeltsScore,
    required this.acceptsMoi,
    required this.instructionLanguage,
    required this.degreeType,
    required this.intakeType,
    required this.matchScore,
    required this.isRecommended,
    required this.cachedAt,
  });
}