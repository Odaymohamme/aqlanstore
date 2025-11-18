// services/admin_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminApi {
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  static get _fire => null;

  /// حفظ التوكن محليًا (اختياري)
  static Future<void> saveToken(String token) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('admin_token', token);
  }

  static Future<String?> token() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString('admin_token');
  }

  // ────────────────────────────────
  // 🧩 تسجيل دخول الأدمن
  // ────────────────────────────────
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final snap = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        return {'success': false, 'message': 'الحساب غير موجود'};
      }

      final doc = snap.docs.first;
      final data = doc.data();

      if (data['password'] != password) {
        return {'success': false, 'message': 'كلمة المرور غير صحيحة'};
      }

      await saveToken(doc.id);
      return {
        'success': true,
        'token': doc.id,
        'message': 'تم تسجيل الدخول بنجاح'
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ أثناء تسجيل الدخول: $e'};
    }
  }

  // ────────────────────────────────
// 📊 إحصائيات لوحة التحكم (KPIs)
// ────────────────────────────────
  static Future<Map<String, dynamic>> fetchKpis() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // جلب عدد العملاء
      final customersSnapshot = await firestore.collection('customers').get();
      final int totalCustomers = customersSnapshot.size;

      // جلب الطلبات
      final ordersSnapshot = await firestore.collection('orders').get();
      final int totalOrders = ordersSnapshot.size;

      // جلب الأصناف
      final itemsSnapshot = await firestore.collection('items').get();
      final int totalItems = itemsSnapshot.size;

      // حساب إجمالي الإيرادات
      double totalRevenue = 0;
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        // إذا كان لديك حقل المجموع الكلي للطلب (total أو grand_total)
        if (data.containsKey('total')) {
          totalRevenue += double.tryParse(data['total'].toString()) ?? 0.0;
        } else if (data.containsKey('grand_total')) {
          totalRevenue += double.tryParse(data['grand_total'].toString()) ?? 0.0;
        }
      }

      // حساب طلبات اليوم
      int todayOrders = 0;
      final today = DateTime.now();
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('created_at')) {
          final ts = data['created_at'];
          if (ts is Timestamp) {
            final date = ts.toDate();
            if (date.year == today.year && date.month == today.month && date.day == today.day) {
              todayOrders++;
            }
          } else if (ts is String) {
            // إذا التاريخ محفوظ كنص
            final date = DateTime.tryParse(ts);
            if (date != null &&
                date.year == today.year &&
                date.month == today.month &&
                date.day == today.day) {
              todayOrders++;
            }
          }
        }
      }

      return {
        'success': true,
        'data': {
          'total_customers': totalCustomers,
          'today_orders': todayOrders,
          'total_orders': totalOrders,
          'total_revenue': totalRevenue,
          'total_items': totalItems,
        },
      };
    } catch (e, st) {
      debugPrint('fetchKpis error: $e\n$st');
      return {'success': false, 'message': e.toString()};
    }
  }
  // ────────────────────────────────
  // 🛍 إدارة الأصناف (Items)
  // ────────────────────────────────

  static Future<List<Map<String, dynamic>>> fetchItems() async {
    final snap = await _fire.collection('items').orderBy('created_at', descending: true).get();
    return snap.docs.map((d) => d.data()..['id'] = d.id).toList();
  }

  static Future<void> addOrUpdateItem({
    String? itemId,
    required String name,
    required String description,
    required double price,
    required String categoryId,
    required String unit,
    required String imageUrl,
    bool isActive = true,
  }) async {
    final data = {
      'name': name,
      'description': description,
      'price': price,
      'category_id': categoryId,
      'unit': unit,
      'image': imageUrl,
      'is_active': isActive,
      'created_at': FieldValue.serverTimestamp(),
    };

    if (itemId == null || itemId.isEmpty) {
      final doc = await _fire.collection('items').add(data);
      await doc.update({'item_id': doc.id});
    } else {
      await _fire.collection('items').doc(itemId).update(data);
    }
  }

  static Future<void> toggleItemActive(String itemId, bool currentStatus) async {
    await _fire.collection('items').doc(itemId).update({'is_active': !currentStatus});
  }

  static Future<void> deleteItem(String itemId) async {
    await _fire.collection('items').doc(itemId).delete();
  }

  static Future<String?> uploadToCloudinary(File file) async {
    const cloudName = 'YOUR_CLOUD_NAME';
    const uploadPreset = 'YOUR_UPLOAD_PRESET';
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/auto/upload');
    final req = http.MultipartRequest('POST', uri);
    req.fields['upload_preset'] = uploadPreset;
    req.files.add(await http.MultipartFile.fromPath('file', file.path));
    final res = await req.send();
    final body = await res.stream.bytesToString();
    if (res.statusCode == 200) {
      final jsonData = jsonDecode(body);
      return jsonData['secure_url'];
    }
    return null;
  }

  // ────────────────────────────────
  // 📦 إدارة الطلبات (Orders)
  // ────────────────────────────────

  static Stream<List<Map<String, dynamic>>> watchOrders() {
    return _fire.collection('orders').orderBy('created_at', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => d.data()..['id'] = d.id).toList(),
    );
  }

  static Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _fire.collection('orders').doc(orderId).update({
    'status': newStatus,
    'updated_at': FieldValue.serverTimestamp(),
    });
    }
}