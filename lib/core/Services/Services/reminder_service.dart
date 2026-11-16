import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// The cart reminder (3 Nov): when the app goes to the background (or is closed) with something in the cart,
/// a local notification is scheduled for 10 minutes later: "Your cart is waiting". It is cancelled when the app
/// comes back first, or when the cart is emptied. Tapping it opens the cart.
///
/// Android: the app needs POST_NOTIFICATIONS (asked the first time a reminder is scheduled, Android 13+) and the
/// receivers flutter_local_notifications documents for scheduled notifications (see README › Android set-up).
/// The reminder uses an inexact alarm, so no exact-alarm permission is needed; it may arrive a little late.
class ReminderService {
  static const _id = 7001;
  static const _payload = 'cart';
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _asked = false;
  VoidCallback? onOpenCart;

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
        ),
        onDidReceiveNotificationResponse: (r) {
          if (r.payload == _payload) onOpenCart?.call();
        },
      );
      _ready = true;
      // opened from the reminder while the app was closed
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true && launch?.notificationResponse?.payload == _payload) {
        Future.delayed(const Duration(milliseconds: 400), () => onOpenCart?.call());
      }
    } catch (e) {
      debugPrint('Reminders off: $e'); // a platform without notifications: the app runs without them
    }
  }

  /// Schedule "Your cart is waiting" for [after] from now.
  Future<void> schedule({required String title, required String body, required Duration after}) async {
    if (!_ready) return;
    try {
      if (!_asked) {
        _asked = true;
        await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
        await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, sound: true);
      }
      await _plugin.zonedSchedule(
        id: _id,
        title: title,
        body: body,
        payload: _payload,
        scheduledDate: tz.TZDateTime.now(tz.UTC).add(after),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'cart_reminder',
            'Cart reminders',
            channelDescription: 'A reminder when there is something in the cart that has not been sent',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Reminder not scheduled: $e');
    }
  }

  Future<void> cancel() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _id);
    } catch (_) {}
  }
}
