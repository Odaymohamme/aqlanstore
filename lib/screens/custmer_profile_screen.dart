import 'package:adminaqlanstore/widgets/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerProfileScreen extends StatelessWidget {
  final String customerId;

  const CustomerProfileScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    final doc = FirebaseFirestore.instance.collection('customers').doc(customerId);

    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'ملف العميل',
            style: TextStyle(
              fontFamily: 'NotoSansArabic',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        endDrawer: const AdminDrawer(currentPage: 'CustomerProfileScreen'),
        body: FutureBuilder<DocumentSnapshot>(
            future: doc.get(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snap.data!.data() as Map<String, dynamic>? ?? {};
              final imageUrl = data['profile_image'] ?? '';

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 🖼 صورة العميل من Supabase أو أي رابط خارجي
                  Center(
                    child: CircleAvatar(
                      radius: 45,
                      backgroundImage: imageUrl.isNotEmpty
                          ? NetworkImage(imageUrl)
                          : null,
                      child: imageUrl.isEmpty
                          ? const Icon(Icons.person, size: 45)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 👤 الاسم
                  Center(
                    child: Text(
                      data['name'] ?? 'بدون اسم',
                      style: const TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const Divider(height: 32, thickness: 1.2),

                  // 🧾 معلومات العميل
                  Text(
                    '📱 رقم الهاتف: ${data['phone'] ?? '-'}',
                    style: const TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '📧 البريد: ${data['email'] ?? '-'}',
                    style: const TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '📅 التسجيل: ${data['registration_date'] ?? '-'}',
                    style: const TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '💰 الرصيد: ${data['balance'] ?? 0} ر.س',
                    style: const TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '🎯 المستوى: ${data['level'] ?? 'عادي'}',
                    style: const TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 16,
                    ),
                  ),

                  const Divider(height: 32, thickness: 1.2),

                  // ✅ زر التحقق
                  ElevatedButton.icon(
                    onPressed: () async {
                      await doc.update({
                        'is_verified': !(data['is_verified'] ?? false),
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'تم تحديث حالة التحقق بنجاح ✅',
                            style: TextStyle(fontFamily: 'NotoSansArabic'),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.verified),
                    label: Text(
                      data['is_verified'] == true
                          ? 'إلغاء التحقق'
                          : 'تفعيل التحقق',
                      style: const TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: data['is_verified'] == true
                          ? Colors.grey
                          : Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              );
            },
            ),
        );
    }
}