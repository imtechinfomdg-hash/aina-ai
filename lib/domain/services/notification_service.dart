import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../data/models/medication_reminder_model.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) return; // Notifications not supported in simple web mock

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      androidImplementation?.requestNotificationsPermission();
      androidImplementation?.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleMedicationReminder(MedicationReminderModel reminder) async {
    if (kIsWeb) return;
    if (reminder.id == null) return;

    final id = reminder.id!;

    // Check if time is in the past, if so schedule for next day
    DateTime scheduledDate = reminder.time;
    if (scheduledDate.isBefore(DateTime.now())) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      'Rappel Médicament',
      'Il est l\\'heure de prendre : ${reminder.medName} (${reminder.dosage})',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Rappels de médicaments',
          channelDescription: 'Notifications pour les prises de médicaments',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at the same time
    );
  }

  Future<void> scheduleVaccinationReminder(dynamic vaccine, dynamic child) async {
    if (kIsWeb) return;
    if (vaccine.id == null) return;

    // Use an offset to avoid collisions with medication reminders
    final id = vaccine.id! + 100000;

    // Schedule for 8:00 AM on the planned date
    DateTime plannedDate = vaccine.datePlanned;
    DateTime scheduledDate = DateTime(
      plannedDate.year,
      plannedDate.month,
      plannedDate.day,
      8, 0, 0,
    );

    // If the planned date is already in the past, or it's past 8:00 AM today, don't schedule a new reminder
    // Instead maybe just ignore if it's past
    if (scheduledDate.isBefore(DateTime.now())) {
      // If it's today but later than 8am, we could schedule it for right now + 1 min, but maybe ignore
      return;
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      'Rappel de Vaccination',
      'Le vaccin de ${child.name} (${vaccine.vaccineName}) est prévu pour aujourd\\'hui.',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'vaccination_reminders',
          'Rappels de vaccinations',
          channelDescription: 'Notifications pour les dates prévues de vaccination',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      // No matchDateTimeComponents because it's a one-time event
    );
  }

  Future<void> cancelReminder(int id) async {
    if (kIsWeb) return;
    await _notificationsPlugin.cancel(id);
  }
}
