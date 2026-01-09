import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("سجل الإشعارات"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              // حذف كل الإشعارات
              final snap = await FirebaseFirestore.instance.collection('notifications').get();
              for (var doc in snap.docs) {
                await doc.reference.delete();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف جميع الإشعارات')),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("لا توجد إشعارات بعد"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final isRead = data['read'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: isRead
                      ? null
                      : const Icon(Icons.circle, color: Colors.blue, size: 10),
                  title: Text(data['title'] ?? '', style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Text(data['body'] ?? ''),
                  trailing: data['type'] == 'order'
                      ? const Icon(Icons.shopping_cart, color: Colors.orange)
                      : const Icon(Icons.person_add, color: Colors.green),
                  onTap: () async {
                    // عند الضغط، يتم وضع علامة قراءة
                    await docs[index].reference.update({'read': true});
                    setState(() {}); // تحديث الواجهة فورًا
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
