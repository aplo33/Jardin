import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import '../models/task.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    
    // Initialize timezone
    tz.initializeTimeZones();
    
    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        debugPrint('Notification tapped: ${response.payload}');
      },
    );
    
    _initialized = true;
  }

  Future<void> showTaskReminderNotification(Task task) async {
    if (!_initialized) {
      await initialize();
    }
    
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'task_reminders',
      'Rappels de tâches',
      channelDescription: 'Notifications pour les rappels de tâches du jardin',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    
    final iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      sound: 'default',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    // Schedule notification for task due date
    await _notificationsPlugin.zonedSchedule(
      task.id.hashCode,
      'Rappel: ${task.title}',
      _getTaskNotificationBody(task),
      tz.TZDateTime.from(task.dueDate, tz.local),
      platformChannelSpecifics,
      payload: 'task:${task.id}',
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'general',
      'Notifications générales',
      channelDescription: 'Notifications générales de l\'application',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
    );
    
    final iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      sound: 'default',
    );
    
    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> cancelTaskNotification(String taskId) async {
    await _notificationsPlugin.cancel(taskId.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  String _getTaskNotificationBody(Task task) {
    switch (task.type) {
      case TaskType.watering:
        return 'Il est temps d\'arroser vos plantes !';
      case TaskType.pruning:
        return 'Taillez vos plantes pour une meilleure croissance.';
      case TaskType.fertilizing:
        return 'Fertilisez vos plantes pour des récoltes abondantes.';
      case TaskType.harvesting:
        return 'Récoltez vos ${task.title} avant qu\'ils ne soient trop mûrs !';
      case TaskType.planting:
        return 'Plantez vos nouvelles graines ou plants.';
      case TaskType.weeding:
        return 'Désherbez votre jardin pour éviter la concurrence.';
      case TaskType.pestControl:
        return 'Protégez vos plantes contre les nuisibles.';
      default:
        return task.description ?? 'Rappel pour: ${task.title}';
    }
  }

  Future<void> scheduleDailyWateringReminder({
    required String gardenId,
    required TimeOfDay time,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    
    // If time is in the past, schedule for tomorrow
    final notificationTime = scheduledTime.isBefore(now) 
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;
    
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'daily_reminders',
      'Rappels quotidiens',
      channelDescription: 'Notifications quotidiennes pour l\'arrosage',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    
    final iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      sound: 'default',
    );
    
    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    await _notificationsPlugin.zonedSchedule(
      'daily_watering_$gardenId'.hashCode,
      'Rappel quotidien: Arrosage',
      'N\'oubliez pas d\'arroser vos plantes aujourd\'hui !',
      tz.TZDateTime.from(notificationTime, tz.local),
      platformChannelSpecifics,
      payload: 'daily_watering:$gardenId',
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyWateringReminder(String gardenId) async {
    await _notificationsPlugin.cancel('daily_watering_$gardenId'.hashCode);
  }
}
