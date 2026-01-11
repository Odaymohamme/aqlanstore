import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// خدمة لإدارة FCM + عرض إشعارات محلية داخل التطبيق (foreground)
/// وأيضاً حفظ إشعار كوثيقة في Firestore داخل collection: admin_notifications
class NotificationService {
  NotificationService._();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  static const String notificationsCollection = 'admin_notifications';
  static const String tokensCollection = 'admin_tokens';

  /// استدعِ هذه الدالة مرة في بداية التطبيق (بعد Firebase.initializeApp)
  static Future<void> initialize() async {
    // إعداد local notifications
    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings iosInit = const DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    await _local.initialize(
      InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('onDidReceiveNotificationResponse payload: ${response.payload}');
        // يمكنك هنا التعامل مع payload وفتحه
      },
      onDidReceiveBackgroundNotificationResponse: (NotificationResponse response) {
        debugPrint('onDidReceiveBackgroundNotificationResponse payload: ${response.payload}');
      },
    );

    // طلب أذونات iOS
    if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }

    // حفظ التوكن في Firestore
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await saveTokenToFirestore(token);
        debugPrint('FCM token: $token');
      }
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }

    // التعامل مع الرسائل أثناء foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('onMessage: ${message.notification?.title} / ${message.notification?.body}');
      final n = message.notification;
      String title = n?.title ?? message.data['title'] ?? 'تنبيه';
      String body = n?.body ?? message.data['body'] ?? '';

      // 1) إظهار إشعار محلي
      await showLocalNotification(title, body, payload: message.data.isNotEmpty ? message.data.toString() : null);

      // 2) حفظ الإشعار في Firestore
      await saveNotificationToFirestore(
        title: title,
        body: body,
        data: message.data,
        source: 'fcm',
      );
    });

    // فتح التطبيق من الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('onMessageOpenedApp: ${message.data}');
      // هنا يمكنك التنقّل لصفحة الطلب/العميل استناداً إلى message.data
    });
  }

  /// حفظ توكن الجهاز في مجموعة admin_tokens (مستند id == token)
  static Future<void> saveTokenToFirestore(String token) async {
    try {
      final ref = FirebaseFirestore.instance.collection(tokensCollection).doc(token);
      await ref.set({
        'token': token,
        'platform': Platform.operatingSystem,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveTokenToFirestore error: $e');
    }
  }

  /// يحفظ إشعارًا في Firestore داخل collection admin_notifications
  /// data (Map) اختياري ويُستخدم لحفظ معلومات عن الطلب/العميل (مثلاً {type: 'new_order', id: '...'})
  static Future<void> saveNotificationToFirestore({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String source = 'local', // 'local' | 'fcm' | 'firestore_listener' | 'server'
  }) async {
    try {
      final col = FirebaseFirestore.instance.collection(notificationsCollection);
      final payload = <String, dynamic>{
        'title': title,
        'body': body,
        'data': data ?? {},
        'read': false,
        'source': source,
        'created_at': FieldValue.serverTimestamp(),
      };
      await col.add(payload);
    } catch (e) {
      debugPrint('saveNotificationToFirestore error: $e');
    }
  }

  /// عرض إشعار محلي بسيط
  static Future<void> showLocalNotification(String title, String body, {String? payload}) async {
    const androidDetails = AndroidNotificationDetails(
      'aqlan_admin_channel',
      'Admin Notifications',
      channelDescription: 'اشعارات لوحة الإدارة',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }
}