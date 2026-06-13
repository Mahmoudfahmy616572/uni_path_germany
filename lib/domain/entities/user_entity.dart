// ====================
// FILE: lib/domain/entities/user_entity.dart
// ====================
//
// التغييرات:
//  ✅ أضفنا hasMoi كـ field — كان موجود في الـ DB (has_moi) بس مش في الـ Entity
//  ✅ degreeLevel default صحّحناه يبقى "Bachelor's Degree" بدل Master's
//     لأن الأغلبية بيبدأوا بالـ Bachelor
//  ✅ أضفنا NotificationPreferences للإشعارات

import 'package:flutter/material.dart';

class NotificationPreferences {
  final bool notificationsEnabled;
  final bool deadlineReminders;
  final bool applicationUpdates;
  final bool generalNotifications;
  final List<int> reminderDaysBefore;

  const NotificationPreferences({
    this.notificationsEnabled = true,
    this.deadlineReminders = true,
    this.applicationUpdates = true,
    this.generalNotifications = true,
    this.reminderDaysBefore = const [7, 3, 1],
  });

  NotificationPreferences copyWith({
    bool? notificationsEnabled,
    bool? deadlineReminders,
    bool? applicationUpdates,
    bool? generalNotifications,
    List<int>? reminderDaysBefore,
  }) {
    return NotificationPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      deadlineReminders: deadlineReminders ?? this.deadlineReminders,
      applicationUpdates: applicationUpdates ?? this.applicationUpdates,
      generalNotifications: generalNotifications ?? this.generalNotifications,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
    );
  }
}

class UserEntity {
  final String id;
  final String email;
  final String name;
  final String intake;
  final String targetMajor;
  final String languagePreference;
  final String degreeLevel;
  final double gpa;
  final double maxGpa;
  final double minGpa;
  final bool hasIelts;
  final double ieltsScore;
  final bool hasMoi; 
  final String budgetRange;
  final List<String> goals;
  final NotificationPreferences notificationPreferences; 
  final TimeOfDay? quietStart;
  final TimeOfDay? quietEnd;
  final String role;

  UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.intake = 'Both Semesters',
    this.targetMajor = '',
    this.languagePreference = 'English',
    this.degreeLevel = "Bachelor's Degree", // ✅ صحّحنا الـ default
    this.gpa = 0.0,
    this.maxGpa = 4.0,
    this.minGpa = 1.0,
    this.hasIelts = false,
    this.ieltsScore = 0.0,
    this.hasMoi = false, // ✅ جديد
    this.budgetRange = '',
    this.goals = const [],
    this.notificationPreferences = const NotificationPreferences(), // ✅ جديد
    this.quietStart,
    this.quietEnd,
    this.role = 'user',
  });
}
