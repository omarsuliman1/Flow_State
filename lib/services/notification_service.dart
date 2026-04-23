import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('icon'); 
    
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
      const AndroidNotificationChannel(
        'flow_channel', 
        'Flow Notifications', 
        importance: Importance.max,
        description: 'Main channel for app notifications'
      )
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    tz.initializeTimeZones();
  }

  // ميثود لجدولة إشعارات متكررة لكل بلان (كل ساعتين) باللغة الإنجليزية
  Future<void> schedulePlanReminders({
    required int planId,
    required String userName,
    required String planName,
    required DateTime planEndTime,
  }) async {
    try {
      // جدولة الإشعارات كل ساعتين (6 إشعارات كمثال لتغطية 12 ساعة)
      for (int i = 1; i <= 6; i++) {
        final scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(hours: i * 2));

        // التأكد أن وقت الإشعار قبل وقت انتهاء البلان
        if (scheduledTime.isBefore(tz.TZDateTime.from(planEndTime, tz.local))) {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            planId + i, // ID فريد لكل بلان ولكل إشعار
            'Flow State • $planName',
            'Hey $userName, don\'t forget to track your plan: $planName 🚀',
            scheduledTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'flow_channel',
                'Flow Notifications',
                importance: Importance.max,
                priority: Priority.high,
                icon: 'icon',
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    } catch (e) {
      print("Error scheduling reminders: $e");
    }
  }

  // ميثود لإيقاف إشعارات بلان معينة
  Future<void> cancelPlanReminders(int planId) async {
    for (int i = 1; i <= 6; i++) {
      await flutterLocalNotificationsPlugin.cancel(planId + i);
    }
  }

  // --- الميثودز الأساسية ---

  Future<void> showInstantNotification(String title, String body) async {
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title, 
      body, 
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'flow_channel', 
          'Flow Notifications', 
          importance: Importance.max, 
          priority: Priority.high,
          icon: 'icon',
        ),
      ),
    );
  }

  Future<void> showNotification(int id, String title, String body) async {
    await flutterLocalNotificationsPlugin.show(
      id, 
      title, 
      body, 
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'flow_channel', 
          'Flow Notifications', 
          importance: Importance.max, 
          priority: Priority.high,
          showWhen: true,
          icon: 'icon',
        ),
      ),
    );
  }

  Future<void> scheduleDaily8AM(int id, String name) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Flow State • Daily Goal',
        'Dear $name, Your daily goal is waiting. Focus for 50 mins and get it done.',
        _nextInstanceOf8AM(),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'flow_channel', 
            'Flow Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'icon',
          )
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print("Notification Error: $e");
    }
  }

  tz.TZDateTime _nextInstanceOf8AM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}