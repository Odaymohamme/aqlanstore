import 'package:adminaqlanstore/widgets/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerAddressesScreen extends StatelessWidget {
  final String customerId;

  const CustomerAddressesScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    final addresses = FirebaseFirestore.instance
        .collection('customer_addresses')
        .where('customer_id', isEqualTo: customerId);

    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'عناوين العميل',
            style: TextStyle(
              fontFamily: 'NotoSansArabic',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        endDrawer: const AdminDrawer(currentPage: 'CustomerAddressesScreen'),
        body: StreamBuilder<QuerySnapshot>(
            stream: addresses.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    'لا توجد عناوين محفوظة',
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
                  final d = docs[i].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.teal),
                      title: Text(
                        d['title'] ?? 'بدون عنوان',
                        style: const TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        d['full_address'] ?? '',
                        style: const TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 14,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.map_outlined),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'رابط الخريطة: ${d['map_link'] ?? 'غير متوفر'}',
                                style: const TextStyle(
                                  fontFamily: 'NotoSansArabic',
                                ),
                              ),
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