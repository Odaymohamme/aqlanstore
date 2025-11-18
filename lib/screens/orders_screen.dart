import 'package:adminaqlanstore/screens/order_details_screen.dart';
import 'package:adminaqlanstore/widgets/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = FirebaseFirestore.instance.collection('orders');

    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'إدارة الطلبات',
            style: TextStyle(fontFamily: 'NotoSansArabic'),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        endDrawer: const AdminDrawer(currentPage: 'OrdersScreen'),
        body: StreamBuilder<QuerySnapshot>(
            stream: orders.orderBy('order_date', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(
                  child: Text('لا توجد طلبات حتى الآن', style: TextStyle(fontFamily: 'NotoSansArabic')),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final d = doc.data() as Map<String, dynamic>;
                  final orderId = doc.id;
                  final status = (d['status'] ?? 'pending').toString();

                  // لون الكرت — أحمر عند pending، أخضر عند accepted/complete
                  final cardColor = status == 'pending' ? Colors.red.shade50 : Colors.green.shade50;

                  return Card(
                    margin: const EdgeInsets.all(8),
                    color: cardColor,
                    child: ListTile(
                      title: Text(
                        'طلب رقم: $orderId',
                        style: const TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('المجموع: ${d['total'] ?? '-'} ر.س', style: const TextStyle(fontFamily: 'NotoSansArabic')),
                          Text('طريقة الدفع: ${d['payment_method'] ?? '-'}', style: const TextStyle(fontFamily: 'NotoSansArabic')),
                          Text('العميل: ${d['customer_id'] ?? '-'}', style: const TextStyle(fontFamily: 'NotoSansArabic')),
                          Text(
                            'التاريخ: ${d['order_date'] is Timestamp ? (d['order_date'] as Timestamp).toDate().toString() : (d['order_date'] ?? '-')}',
                            style: const TextStyle(fontFamily: 'NotoSansArabic'),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.receipt_long, color: Colors.teal),
                        tooltip: 'عرض تفاصيل الطلب',
                        onPressed: () {
                          // نأخذ customerId إن وجد في المستند، وإلا نمرر null وسيحاول الـ Details جلبه من الـ order doc
                          final customerId = d['customer_id']?.toString();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailsScreen(orderId: orderId, customerId: customerId),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
            ),
        );
    }
}