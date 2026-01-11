import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

/// هذه الخدمة تراقب مجموعات customers و orders وتصدر إشعارات محلية
/// وتقوم بحفظ إشعار في Firestore كي يظهر في شاشة الإشعارات.
class FirestoreNotificationsService {
  FirestoreNotificationsService._();

  static StreamSubscription? _customersSub;
  static StreamSubscription? _ordersSub;

  static void startListening() {
    final firestore = FirebaseFirestore.instance;

    // مراقبة العملاء الجدد
    _customersSub = firestore.collection('customers').snapshots().listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          final name = (data?['name'] ?? 'مستخدم جديد').toString();
          final title = 'مستخدم جديد';
          final body = 'انضم: $name';

          // عرض محلي
          NotificationService.showLocalNotification(title, body);

          // حفظ في Firestore (source = firestore_listener)
          NotificationService.saveNotificationToFirestore(
            title: title,
            body: body,
            data: {
              'type': 'new_customer',
              'customer_id': change.doc.id,
              ...? (data is Map ? Map<String, dynamic>.from(data!) : null),
            },
            source: 'firestore_listener',
          );
        }
      }
    }, onError: (e) {
      print('customers listen error: $e');
    });

    // مراقبة الطلبات الجديدة
    _ordersSub = firestore.collection('orders').snapshots().listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          final orderId = change.doc.id;
          final total = (data?['total'] ?? '-').toString();
          final title = 'طلب جديد';
          final body = 'طلب #$orderId — المجموع: $total ر.س';

          NotificationService.showLocalNotification(title, body);

          NotificationService.saveNotificationToFirestore(
            title: title,
            body: body,
            data: {
              'type': 'new_order',
              'order_id': orderId,
              ...? (data is Map ? Map<String, dynamic>.from(data!) : null),
            },
            source: 'firestore_listener',
          );
        }
      }
    }, onError: (e) {
      print('orders listen error: $e');
    });
  }

  static Future<void> stopListening() async {
    await _customersSub?.cancel();
    await _ordersSub?.cancel();
    _customersSub = null;
    _ordersSub = null;
  }
}