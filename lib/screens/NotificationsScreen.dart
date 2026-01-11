import 'package:adminaqlanstore/screens/order_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'custmer_profile_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  Future<void> _markRead(String docId) async {
    await FirebaseFirestore.instance.collection('admin_notifications').doc(docId).update({'read': true});
  }

  Future<void> _delete(String docId) async {
    await FirebaseFirestore.instance.collection('admin_notifications').doc(docId).delete();
  }

  void _openNotification(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final d = (data['data'] is Map) ? Map<String, dynamic>.from(data['data']) : <String, dynamic>{};

    // مثال: التنقّل إلى شاشة تفاصيل الطلب إن كان type == new_order
    final type = d['type'] ?? d['notification_type'] ?? data['type'] ?? '';

    if (type == 'new_order' || d['order_id'] != null) {
      final orderId = d['order_id']?.toString() ?? doc.id;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: orderId)),
      );
    } else if (type == 'new_customer' || d['customer_id'] != null) {
      final custId = d['customer_id']?.toString() ?? '';
      if (custId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CustomerProfileScreen(customerId: custId)),
        );
      }
    }
    // علم الإشعار كمقروء
    _markRead(doc.id);
  }

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance.collection('admin_notifications').orderBy('created_at', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'حذف المقروء',
            onPressed: () async {
              final q = await FirebaseFirestore.instance.collection('admin_notifications').where('read', isEqualTo: true).get();
              for (final d in q.docs) {
                await d.reference.delete();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الإشعارات المقروءة')));
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: col.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('خطأ: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('لا توجد إشعارات بعد'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? '';
              final body = data['body'] ?? '';
              final read = data['read'] ?? false;
              final createdAt = data['created_at'] is Timestamp ? (data['created_at'] as Timestamp).toDate() : null;

              return ListTile(
                leading: Icon(read ? Icons.notifications_none : Icons.notifications_active, color: read ? Colors.grey : Colors.teal),
                title: Text(title, style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(body),
                    if (createdAt != null) Text(createdAt.toString(), style: const TextStyle(fontSize: 11)),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'read') await _markRead(doc.id);
                    if (v == 'delete') await _delete(doc.id);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'read', child: const Text('تمييز كمقروء')),
                    PopupMenuItem(value: 'delete', child: const Text('حذف')),
                  ],
                ),
                onTap: () => _openNotification(context, doc),
              );
            },
          );
        },
      ),
    );
  }
}