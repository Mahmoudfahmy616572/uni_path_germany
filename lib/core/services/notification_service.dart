// lib/core/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static GoRouter? _router;

  static void setRouter(GoRouter router) => _router = router;

  // ──────────────────────────────────────────────
  // INIT
  // ──────────────────────────────────────────────
  static Future<void> init() async {
    // 1. طلب الإذن
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

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

    // 9. جدولة فحص المواعيد
    await _scheduleDeadlineChecks();
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
        print('✅ FCM Token saved: ${fcmToken.substring(0, 20)}...');
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  // ──────────────────────────────────────────────
  // SCHEDULE DEADLINE CHECKS (WorkManager)
  // ──────────────────────────────────────────────
  static Future<void> _scheduleDeadlineChecks() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      'deadline_check_task',
      'checkDeadlines',
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(minutes: 1),
      constraints: Constraints(networkType: NetworkType.connected),
    );
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
          .maybeSingle();

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
          final deadline = prog['deadline'];
          if (deadline == null) continue;

          final diff =
              DateTime.parse(deadline).difference(DateTime.now()).inDays;
          // Only notify if diff matches one of the user's reminder days
          if (diff >= 0 && reminderDays.contains(diff)) {
            await notifyUpcomingDeadline(
              prog['program_name'],
              deadline,
              diff,
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error checking deadlines: $e');
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
          .maybeSingle();

      if (profile == null) return;

      final bool notificationsEnabled = profile['notifications_enabled'] ?? true;
      final bool applicationUpdates = profile['application_updates'] ?? true;

      if (!notificationsEnabled || !applicationUpdates) return;
    } catch (_) {
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

  static String _formatDate(String dateStr) {
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
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
      _router?.go('/my-applications');
    } else if (payload.startsWith('application_status:')) {
      _router?.go('/my-applications');
    }
  }

  // ──────────────────────────────────────────────
  // WORKMANAGER CALLBACK (top-level)
  // ──────────────────────────────────────────────
  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      if (task == 'checkDeadlines') {
        await _checkAndNotifyDeadlines();
      }
      return Future.value(true);
    });
  }
}

// ──────────────────────────────────────────────
// WORKMANAGER CALLBACK (خارج الكلاس - مطلوب)
// ──────────────────────────────────────────────
@pragma('vm:entry-point')
void callbackDispatcher() {
  NotificationService.callbackDispatcher();
}
