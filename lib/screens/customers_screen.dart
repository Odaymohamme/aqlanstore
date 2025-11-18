import 'package:adminaqlanstore/screens/custmer_profile_screen.dart';
import 'package:adminaqlanstore/widgets/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final customersRef = FirebaseFirestore.instance.collection('customers');

    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'إدارة العملاء',
            style: TextStyle(
              fontFamily: 'NotoSansArabic',
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        endDrawer: const AdminDrawer(currentPage: 'CustomersScreen'),
        body: Column(
            children: [
              // 🔍 مربع البحث
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: '🔍 ابحث بالاسم أو رقم الهاتف...',
                    hintStyle: const TextStyle(fontFamily: 'NotoSansArabic'),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'NotoSansArabic'),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),

              // 📋 قائمة العملاء
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: customersRef.snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snap.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name =
                      (data['name'] ?? '').toString().toLowerCase();
                      final phone =
                      (data['phone'] ?? '').toString().toLowerCase();
                      return name.contains(_query.toLowerCase()) ||
                          phone.contains(_query.toLowerCase());
                    }).toList();

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'لا يوجد عملاء مطابقين',
                          style: TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final data = docs[i].data() as Map<String, dynamic>;

                        // ✅ التحقق من حالة is_verified بشكل آمن
                        bool isVerified = false;
                        final val = data['is_verified'];
                        if (val is bool) {
                          isVerified = val;
                        } else if (val is String) {
                          isVerified = val.toLowerCase() == 'true';
                        } else if (val is int) {
                          isVerified = val == 1;
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(8),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundImage:
                              (data['profile_image'] ?? '').toString().isNotEmpty
                                  ? NetworkImage(data['profile_image'])
                                  : null,
                              backgroundColor: Colors.teal.shade300,
                              child: (data['profile_image'] ?? '').toString().isEmpty
                                  ? const Icon(Icons.person,
                                  color: Colors.white, size: 28)
                                  : null,
                            ),
                            title: Text(
                              data['name'] ?? 'بدون اسم',
                              style: const TextStyle(
                                fontFamily: 'NotoSansArabic',
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📞 ${data['phone'] ?? '-'}',
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansArabic',
                                    fontSize: 14,
                                  ),
                                ),
                                if (data['email'] != null &&
                                    (data['email'] as String).isNotEmpty)
                                  Text(
                                    '📧 ${data['email']}',
                                    style: const TextStyle(
                                      fontFamily: 'NotoSansArabic',
                                      fontSize: 14,
                                    ),
                                  ),
                                Text(
                                  '📅 ${data['registration_date'] ?? 'غير محدد'}',
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansArabic',
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${data['balance'] ?? 0} ر.س',
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansArabic',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Icon(
                                  isVerified
                                      ? Icons.verified
                                      : Icons.error_outline,
                                  color:
                                  isVerified ? Colors.blue : Colors.grey,
                                  size: 22,
                                ),
                              ],
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CustomerProfileScreen(
                                  customerId: docs[i].id,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
            ),
        );
    }
}