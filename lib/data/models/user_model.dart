// ====================
// FILE: lib/data/models/user_model.dart
// ====================
//
// التغييرات:
//  ✅ أضفنا hasMoi في fromJson — بيقرأ has_moi من الـ DB
//  ✅ أضفنا hasMoi في toJson — عشان لو احتجنا نحدثه
//  ✅ أضفنا notificationPreferences في fromJson و toJson

import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.intake,
    required super.targetMajor,
    required super.languagePreference,
    required super.degreeLevel,
    required super.gpa,
    required super.maxGpa,
    required super.minGpa,
    required super.hasIelts,
    required super.ieltsScore,
    required super.hasMoi, // ✅ جديد
    required super.budgetRange,
    required super.goals,
    required super.notificationPreferences, // ✅ جديد
    required super.quietStart,
    required super.quietEnd,
    required super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final reminderDays = json['reminder_days_before'] as List<dynamic>?;
    final quietStartStr = json['quiet_start'] as String?;
    final quietEndStr = json['quiet_end'] as String?;
    
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['username']?.toString() ?? 'User',
      intake: json['intake']?.toString() ?? 'Both Semesters',
      targetMajor: json['target_major']?.toString() ?? '',
      languagePreference: json['language_preference']?.toString() ?? 'English',
      degreeLevel: json['degree_level']?.toString() ?? "Bachelor's Degree",
      gpa: (json['gpa'] as num?)?.toDouble() ?? 0.0,
      maxGpa: (json['max_gpa'] as num?)?.toDouble() ?? 4.0,
      minGpa: (json['min_gpa'] as num?)?.toDouble() ?? 1.0,
      hasIelts: json['has_ielts'] as bool? ?? false,
      ieltsScore: (json['ielts_score'] as num?)?.toDouble() ?? 0.0,
      hasMoi: json['has_moi'] as bool? ?? false, // ✅ جديد
      budgetRange: json['budget_range']?.toString() ?? '',
      goals: List<String>.from(json['goals'] ?? []),
      notificationPreferences: NotificationPreferences(
        notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
        deadlineReminders: json['deadline_reminders'] as bool? ?? true,
        applicationUpdates: json['application_updates'] as bool? ?? true,
        generalNotifications: json['general_notifications'] as bool? ?? true,
        reminderDaysBefore: reminderDays?.map((e) => e as int).toList() ?? [7, 3, 1],
      ),
      quietStart: quietStartStr != null
          ? TimeOfDay(hour: int.parse(quietStartStr.split(':')[0]), minute: int.parse(quietStartStr.split(':')[1]))
          : null,
      quietEnd: quietEndStr != null
          ? TimeOfDay(hour: int.parse(quietEndStr.split(':')[0]), minute: int.parse(quietEndStr.split(':')[1]))
          : null,
      role: json['role']?.toString() ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'intake': intake,
      'target_major': targetMajor,
      'language_preference': languagePreference,
      'degree_level': degreeLevel,
      'gpa': gpa,
      'max_gpa': maxGpa,
      'min_gpa': minGpa,
      'has_ielts': hasIelts,
      'ielts_score': ieltsScore,
      'has_moi': hasMoi, // ✅ جديد
      'budget_range': budgetRange,
      'goals': goals,
      'notifications_enabled': notificationPreferences.notificationsEnabled,
      'deadline_reminders': notificationPreferences.deadlineReminders,
      'application_updates': notificationPreferences.applicationUpdates,
      'general_notifications': notificationPreferences.generalNotifications,
      'reminder_days_before': notificationPreferences.reminderDaysBefore,
      'quiet_start': quietStart != null
          ? '${quietStart!.hour.toString().padLeft(2, '0')}:${quietStart!.minute.toString().padLeft(2, '0')}'
          : null,
      'quiet_end': quietEnd != null
          ? '${quietEnd!.hour.toString().padLeft(2, '0')}:${quietEnd!.minute.toString().padLeft(2, '0')}'
          : null,
      'role': role,
    };
  }
}
