import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';
import 'services/firestore_notifications_service.dart';


/// 🔔 Background handler (Android / iOS فقط)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('🔔 Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler);
  }

  runApp(const AdminApp());
}

/// 🔔 إعداد الإشعارات (Web + Mobile)
Future<void> _setupNotifications() async {
  final messaging = FirebaseMessaging.instance;

  /// طلب الإذن
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus != AuthorizationStatus.authorized) {
    debugPrint('❌ Notification permission denied');
    return;
  }

  /// جلب الـ Token
  String? token;
  if (kIsWeb) {
    token = await messaging.getToken(
      vapidKey:
      'BDGITGdiQvRKEkWbWwoYcolzEz3GS9dWVYM1KrZgjLRAGQMkzYs8EQJGFf3j1B4XdmsFUcEqvgbYLKxN3sYPgVs',
    );
  } else {
    token = await messaging.getToken();
  }

  if (token == null) {
    debugPrint('❌ FCM token is null');
    return;
  }

  /// حفظ التوكن في Firestore لمجموعة الأدمن
  await FirebaseFirestore.instance.collection('admin_fcm_tokens').doc(token).set({
    'platform': kIsWeb ? 'web' : 'mobile',
    'created_at': FieldValue.serverTimestamp(),
  });

  debugPrint('✅ Admin FCM Token saved: $token');

  /// تحديث التوكن عند تغييره
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    await FirebaseFirestore.instance
        .collection('admin_fcm_tokens')
        .doc(newToken)
        .set({
      'platform': kIsWeb ? 'web' : 'mobile',
      'created_at': FieldValue.serverTimestamp(),
    });
  });
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'لوحة إدارة بن عقلان',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        fontFamily: 'NotoSansArabic',
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: AdminLoginScreen(),
      ),
    );
  }
}
