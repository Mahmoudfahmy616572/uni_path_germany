// lib/core/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart'; // for TimeOfDay
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import '../utils/deadline_parser.dart';

final _logger = Logger();

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static GoRouter? _router;
  // ignore: unused_field
  static RealtimeChannel? _applicationChannel;

  static void setRouter(GoRouter router) => _router = router;

  // ──────────────────────────────────────────────
  // INIT
  // ──────────────────────────────────────────────
  static Future<void> init() async {
    // Initialize timezone database
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));

    // 1. Initialize FCM (but don't request permission yet — done after onboarding)
    // Call requestPermission() later after user completes onboarding

    // 2. إعداد الإشعارات المحلية
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 3. التعامل مع إشعارات Firebase في الخلفية
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. الإشعارات في المقدمة (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(
        title: message.notification?.title ?? 'UniPath',
        body: message.notification?.body ?? 'لديك تحديث جديد',
        payload: message.data.toString(),
      );
    });

    // 5. عند النقر على الإشعار (التطبيق مفتوح أو في الخلفية)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data);
    });

    // 6. إذا فُتح التطبيق من إشعار وهو مغلق تماماً
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data);
    }

    // 7. حفظ FCM Token في Supabase
    await _saveFCMToken();

    // 8. استمع لتحديث التوكن
    _messaging.onTokenRefresh.listen(_saveFCMToken);

    // 9. Initialize WorkManager for background tasks (MUST be before scheduling)
    await Workmanager().initialize(callbackDispatcher);

    // 10. جدولة فحص المواعيد (WorkManager للـ background)
    await _scheduleDeadlineChecks();

    // 11. جدولة الإشعارات المحلية (تعمل offline)
    await _scheduleLocalDeadlineNotifications();

    // 12. React to auth changes to manage realtime subscription
    Supabase.instance.client.auth.onAuthStateChange.listen((authState) async {
      if (authState.session != null) {
        if (_applicationChannel == null) {
          try {
            _applicationChannel = await _subscribeToApplicationChanges();
          } catch (e) {
            _logger.e('❌ Error subscribing to application changes: $e');
          }
        }
      } else {
        await _applicationChannel?.unsubscribe();
        _applicationChannel = null;
      }
    });
  }

  /// Request notification permission — call after onboarding/registration
  static Future<bool> requestNotificationPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (granted) {
        await _saveFCMToken();
      }
      return granted;
    } catch (e) {
      _logger.e('Failed to request notification permission: $e');
      return false;
    }
  }

  // ──────────────────────────────────────────────
  // SUBSCRIBE TO APPLICATION CHANGES (Realtime)
  // ──────────────────────────────────────────────
  static Future<RealtimeChannel> _subscribeToApplicationChanges() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('Cannot subscribe without authenticated user');
    }

    final channel = Supabase.instance.client.channel('application-changes');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'my_applications',
      callback: (payload) async {
        try {
          final newRecord = payload.newRecord;
          final oldRecord = payload.oldRecord;

          // Only process changes for the current user
          if (newRecord['user_id'] != user.id) return;

          final oldPortalStatus = oldRecord['portal_status'] as String?;
          final newPortalStatus = newRecord['portal_status'] as String?;
          final oldStatus = oldRecord['status'] as String?;
          final newStatus = newRecord['status'] as String?;

          // Check if portal_status changed
          if (oldPortalStatus != null &&
              newPortalStatus != null &&
              oldPortalStatus != newPortalStatus) {
            final appData = await Supabase.instance.client
                .from('my_applications')
                .select(
                    '*, universities(name), university_programs(program_name)')
                .eq('id', newRecord['id'])
                .single()
                .timeout(const Duration(seconds: 10));

            final universityName =
                (appData['universities'] as Map?)?['name'] as String? ??
                    'Unknown';
            final programName =
                (appData['university_programs'] as Map?)?['program_name']
                    as String? ??
                    'Unknown';

            await notifyPortalStatusChange(
              oldStatus: oldPortalStatus,
              newStatus: newPortalStatus,
              programName: programName,
              universityName: universityName,
            );
          }

          // Check if status changed
          if (oldStatus != null &&
              newStatus != null &&
              oldStatus != newStatus) {
            final appData = await Supabase.instance.client
                .from('my_applications')
                .select(
                    '*, universities(name), university_programs(program_name)')
                .eq('id', newRecord['id'])
                .single()
                .timeout(const Duration(seconds: 10));

            final universityName =
                (appData['universities'] as Map?)?['name'] as String? ??
                    'Unknown';
            final programName =
                (appData['university_programs'] as Map?)?['program_name']
                    as String? ??
                    'Unknown';

            await notifyApplicationStatusChange(
              oldStatus: oldStatus,
              newStatus: newStatus,
              programName: programName,
              universityName: universityName,
            );
          }
        } catch (e) {
          _logger.e('❌ Error in Realtime subscription callback: $e');
        }
      },
    );

    channel.subscribe();
    return channel;
  }

  // ──────────────────────────────────────────────
  // BACKGROUND HANDLER (top-level function required)
  // ──────────────────────────────────────────────
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await _showLocalNotification(
      title: message.notification?.title ?? 'UniPath',
      body: message.notification?.body ?? 'لديك تحديث جديد',
      payload: message.data.toString(),
    );
  }

  // ──────────────────────────────────────────────
  // SAVE FCM TOKEN TO SUPABASE
  // ──────────────────────────────────────────────
  static Future<void> _saveFCMToken([String? token]) async {
    try {
      final fcmToken = token ?? await _messaging.getToken();
      final user = Supabase.instance.client.auth.currentUser;
      if (fcmToken != null && user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': fcmToken}).eq('id', user.id);
        _logger.i('✅ FCM Token saved: ${fcmToken.substring(0, 20)}...');
      }
    } catch (e) {
      _logger.e('❌ Error saving FCM token: $e');
    }
  }

  // ──────────────────────────────────────────────
  // SCHEDULE DEADLINE CHECKS (WorkManager - for background sync)
  // ──────────────────────────────────────────────
  static Future<void> _scheduleDeadlineChecks() async {
    await Workmanager().registerPeriodicTask(
      'deadline_check_task',
      'checkDeadlines',
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(minutes: 1),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  // ──────────────────────────────────────────────
  // SCHEDULE LOCAL NOTIFICATIONS (offline, using timezone)
  // ──────────────────────────────────────────────
  static Future<void> _scheduleLocalDeadlineNotifications() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Fetch user preferences - only select columns that exist
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('notifications_enabled, deadline_reminders, reminder_days_before')
          .eq('id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (profile == null) return;

      final bool notificationsEnabled = profile['notifications_enabled'] ?? true;
      final bool deadlineReminders = profile['deadline_reminders'] ?? true;
      final List<dynamic> reminderDaysRaw =
          profile['reminder_days_before'] ?? [7, 3, 1];
      final List<int> reminderDays = reminderDaysRaw.map((e) => e as int).toList();

      // Quiet hours - not available in DB yet, use defaults
      TimeOfDay? quietStart = null;
      TimeOfDay? quietEnd = null;

      if (!notificationsEnabled || !deadlineReminders) return;

      // Cancel existing scheduled notifications for deadlines
      await _localNotifications.cancelAll();

      // Fetch applications with deadlines
      final apps = await Supabase.instance.client
          .from('my_applications')
          .select(
              '*, universities(*, university_programs(deadline, program_name))')
          .eq('user_id', user.id)
          .inFilter('status', ['saved', 'applied']);

      for (final app in apps) {
        final programs = (app['universities']['university_programs'] as List);
        for (final prog in programs) {
          final deadlineStr = prog['deadline'];
          if (deadlineStr == null) continue;
          if (deadlineStr is! String) continue;

          final deadline = DeadlineParser.parse(deadlineStr);
          if (deadline == null) continue;
          final programName = prog['program_name'] as String;

          for (final daysBefore in reminderDays) {
            final notificationTime = deadline.subtract(Duration(days: daysBefore));
            
            // Skip if notification time is in the past
            if (notificationTime.isBefore(DateTime.now())) continue;

            // Check quiet hours
            if (_isInQuietHours(notificationTime, quietStart, quietEnd)) continue;

            // Schedule notification
            await _localNotifications.zonedSchedule(
              deadline.hashCode + daysBefore.hashCode,
              '⏰ موعد تقديم قريب',
              '$programName - المتبقي: $daysBefore أيام (${_formatDate(deadlineStr)})',
              tz.TZDateTime.from(notificationTime, tz.local),
              NotificationDetails(
                android: AndroidNotificationDetails(
                  'deadline_channel',
                  'Deadline Reminders',
                  channelDescription: 'إشعارات مواعيد التقديم',
                  importance: Importance.high,
                  priority: Priority.high,
                ),
                iOS: const DarwinNotificationDetails(),
              ),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              payload: 'deadline:$programName',
            );
          }
        }
      }
    } catch (e) {
      _logger.e('❌ Error scheduling local notifications: $e');
    }
  }

  static bool _isInQuietHours(
    DateTime dateTime,
    TimeOfDay? quietStart,
    TimeOfDay? quietEnd,
  ) {
    if (quietStart == null || quietEnd == null) return false;
    
    final currentMinutes = dateTime.hour * 60 + dateTime.minute;
    final startMinutes = quietStart.hour * 60 + quietStart.minute;
    final endMinutes = quietEnd.hour * 60 + quietEnd.minute;

    // Overnight quiet hours (e.g., 22:00 - 08:00)
    if (startMinutes > endMinutes) {
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
    // Same day quiet hours
    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  // ──────────────────────────────────────────────
  // CHECK DEADLINES & NOTIFY (called by WorkManager)
  // ──────────────────────────────────────────────
  static Future<void> _checkAndNotifyDeadlines() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Fetch user notification preferences
      final profile = await Supabase.instance.client
          .from('profiles')
          .select(
              'notifications_enabled, deadline_reminders, reminder_days_before')
          .eq('id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (profile == null) return;

      final bool notificationsEnabled = profile['notifications_enabled'] ?? true;
      final bool deadlineReminders = profile['deadline_reminders'] ?? true;
      final List<dynamic> reminderDaysRaw =
          profile['reminder_days_before'] ?? [7, 3, 1];
      final List<int> reminderDays = reminderDaysRaw.map((e) => e as int).toList();

      // Check master toggle and deadline reminders toggle
      if (!notificationsEnabled || !deadlineReminders) return;

      final apps = await Supabase.instance.client
          .from('my_applications')
          .select(
              '*, universities(*, university_programs(deadline, program_name))')
          .eq('user_id', user.id)
          .inFilter('status', ['saved', 'applied']);

      for (final app in apps) {
        final programs = (app['universities']['university_programs'] as List);
        for (final prog in programs) {
          final deadlineStr = prog['deadline'];
          if (deadlineStr == null) continue;

          final deadline = DeadlineParser.parse(deadlineStr);
          if (deadline == null) continue;
          final diff = deadline.difference(DateTime.now()).inDays;
          // Only notify if diff matches one of the user's reminder days
          if (diff >= 0 && reminderDays.contains(diff)) {
            await notifyUpcomingDeadline(
              prog['program_name'],
              deadlineStr,
              diff,
            );
          }
        }
      }
    } catch (e) {
      _logger.e('❌ Error checking deadlines: $e');
    }
  }

  // ──────────────────────────────────────────────
  // SHOW LOCAL NOTIFICATION
  // ──────────────────────────────────────────────
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'unipath_channel',
      'UniPath Notifications',
      channelDescription: 'إشعارات مواعيد التقديم والتحديثات',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  // ──────────────────────────────────────────────
  // SMART NOTIFICATIONS — Personalized Reminders
  // ──────────────────────────────────────────────

  /// Schedule per-application reminders for missing documents
  static Future<void> scheduleDocumentReminder({
    required String applicationId,
    required String programName,
    required String universityName,
    required List<String> missingDocuments,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('notifications_enabled, document_reminders')
          .eq('id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      if (profile == null) return;
      final bool enabled = profile['notifications_enabled'] ?? true;
      final bool docReminders = profile['document_reminders'] ?? true;
      if (!enabled || !docReminders) return;

      await _localNotifications.show(
        applicationId.hashCode,
        '📄 Missing Documents: $programName',
        '${missingDocuments.length} document(s) needed for $universityName:\n${missingDocuments.join(', ')}',
        const NotificationDetails(
          android: AndroidNotificationDetails('deadline_channel', 'Deadline Reminders',
              importance: Importance.defaultImportance, priority: Priority.defaultPriority),
          iOS: DarwinNotificationDetails(),
        ),
        payload: 'application_status:needs_documents:$applicationId',
      );
    } catch (e) {
      _logger.e('scheduleDocumentReminder error: $e');
    }
  }

  /// Weekly digest of upcoming deadlines
  static Future<void> sendWeeklyDigest() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('notifications_enabled')
          .eq('id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      if (profile == null) return;
      if (profile['notifications_enabled'] != true) return;

      final apps = await Supabase.instance.client
          .from('my_applications')
          .select('*, universities(name), university_programs(program_name, deadline)')
          .eq('user_id', user.id)
          .inFilter('status', ['saved', 'applied']);

      if (apps.isEmpty) return;

      final now = DateTime.now();
      final List<String> upcoming = [];
      for (final app in apps) {
        final uniName = (app['universities'] as Map?)?['name'] as String? ?? '';
        final progs = (app['universities']['university_programs'] as List?) ?? [];
        for (final prog in progs) {
          final deadline = DeadlineParser.parse(prog['deadline'] as String? ?? '');
          if (deadline != null && deadline.difference(now).inDays <= 14 && deadline.isAfter(now)) {
            upcoming.add('• ${prog['program_name']} @ $uniName — ${_formatDate(prog['deadline'])}');
          }
        }
      }

      if (upcoming.isNotEmpty) {
        await _localNotifications.show(
          DateTime.now().millisecond,
          '📅 Your Coming Week at a Glance',
          '${upcoming.length} deadline(s) within 14 days:\n${upcoming.join('\n')}',
          const NotificationDetails(
            android: AndroidNotificationDetails('deadline_channel', 'Deadline Reminders',
                importance: Importance.defaultImportance, priority: Priority.defaultPriority),
            iOS: DarwinNotificationDetails(),
          ),
          payload: 'digest:weekly',
        );
      }
    } catch (e) {
      _logger.e('sendWeeklyDigest error: $e');
    }
  }

  // ──────────────────────────────────────────────
  // PUBLIC: NOTIFY UPCOMING DEADLINE
  // ──────────────────────────────────────────────
  static Future<void> notifyUpcomingDeadline(
    String programName,
    String deadline,
    int daysLeft,
  ) async {
    await _showLocalNotification(
      title: '⏰ موعد تقديم قريب',
      body: '$programName - المتبقي: $daysLeft أيام (${_formatDate(deadline)})',
      payload: 'deadline:$programName',
    );
  }

  // ──────────────────────────────────────────────
  // PUBLIC: NOTIFY APPLICATION STATUS CHANGE
  // ──────────────────────────────────────────────
  static Future<void> notifyApplicationStatusChange({
    required String programName,
    required String universityName,
    required String oldStatus,
    required String newStatus,
  }) async {
    // Check user preferences first
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('notifications_enabled, application_updates')
          .eq('id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (profile == null) return;

      final bool notificationsEnabled = profile['notifications_enabled'] ?? true;
      final bool applicationUpdates = profile['application_updates'] ?? true;

      if (!notificationsEnabled || !applicationUpdates) return;
    } catch (e) {
      _logger.e('notifyApplicationStatusChange profile fetch error: $e');
      return;
    }

    String title;
    String body;
    String payload;

    switch (newStatus) {
      case 'applied':
        title = '📝 تم التقديم';
        body = 'تم تقديم طلبك لـ $programName في $universityName';
        payload = 'application_status:applied:$programName';
        break;
      case 'under_review':
        title = '🔍 تحت المراجعة';
        body = 'طلبك لـ $programName في $universityName قيد المراجعة';
        payload = 'application_status:under_review:$programName';
        break;
      case 'accepted':
        title = '🎉 تم القبول!';
        body = 'مبارك! تم قبولك في $programName في $universityName';
        payload = 'application_status:accepted:$programName';
        break;
      case 'rejected':
        title = '❌ تم الرفض';
        body = 'للأسف، تم رفض طلبك لـ $programName في $universityName';
        payload = 'application_status:rejected:$programName';
        break;
      case 'waitlisted':
        title = '⏳ قائمة الانتظار';
        body = 'تم وضع طلبك لـ $programName في $universityName في قائمة الانتظار';
        payload = 'application_status:waitlisted:$programName';
        break;
      default:
        title = '📋 تحديث حالة الطلب';
        body = 'تغيرت حالة طلبك لـ $programName إلى $newStatus';
        payload = 'application_status:$newStatus:$programName';
    }

    await _showLocalNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  // ──────────────────────────────────────────────
  // PUBLIC: NOTIFY PORTAL STATUS CHANGE
  // ──────────────────────────────────────────────
  static Future<void> notifyPortalStatusChange({
    required String programName,
    required String universityName,
    required String oldStatus,
    required String newStatus,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('notifications_enabled, application_updates')
          .eq('id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (profile == null) return;

      final bool notificationsEnabled = profile['notifications_enabled'] ?? true;
      final bool applicationUpdates = profile['application_updates'] ?? true;

      if (!notificationsEnabled || !applicationUpdates) return;
    } catch (e) {
      _logger.e('notifyPortalStatusChange profile fetch error: $e');
      return;
    }

    String title;
    String body;

    switch (newStatus) {
      case 'submitted':
        title = '📤 تم إرسال الطلب';
        body = 'تم إرسال طلبك لـ $programName في $universityName إلى بوابة التقديم';
        break;
      case 'acknowledged':
        title = '✅ تم تأكيد الاستلام';
        body = 'تم تأكيد استلام طلبك لـ $programName من $universityName';
        break;
      case 'accepted':
        title = '🎉 تم القبول!';
        body = 'مبارك! تم قبولك في $programName في $universityName';
        break;
      case 'rejected':
        title = '❌ تم الرفض';
        body = 'للأسف، تم رفض طلبك لـ $programName في $universityName';
        break;
      default:
        title = '📋 تحديث حالة البوابة';
        body = 'تغيرت حالة بوابة $programName إلى $newStatus';
    }

    await _showLocalNotification(
      title: title,
      body: body,
      payload: 'portal_status:$newStatus:$programName',
    );
  }

  static String _formatDate(String dateStr) {
    return DeadlineParser.format(dateStr);
  }

  // ──────────────────────────────────────────────
  // HANDLE NOTIFICATION TAP
  // ──────────────────────────────────────────────
  static void _onNotificationTapped(NotificationResponse response) {
    _handleNotificationTap({'payload': response.payload});
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    final payload = data['payload'] as String? ?? '';
    if (payload.startsWith('deadline:')) {
      _router?.go('/applications');
    } else if (payload.startsWith('application_status:')) {
      _router?.go('/applications');
    }
  }
}

// ──────────────────────────────────────────────
// WORKMANAGER CALLBACK (top-level function required by WorkManager)
// ──────────────────────────────────────────────
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'checkDeadlines') {
      await NotificationService._checkAndNotifyDeadlines();
    }
    return Future.value(true);
  });
}
