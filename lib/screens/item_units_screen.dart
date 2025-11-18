import 'package:adminaqlanstore/widgets/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemUnitsScreen extends StatelessWidget {
  final String itemId;

  const ItemUnitsScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final unitsRef = FirebaseFirestore.instance
        .collection('item_units')
        .where('item_id', isEqualTo: itemId);

    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'الوحدات',
            style: TextStyle(fontFamily: 'NotoSansArabic'),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        endDrawer: const AdminDrawer(currentPage: 'ItemUnitsScreen'),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () async {
            nameCtrl.clear();
            priceCtrl.clear();

            await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text(
                  'إضافة وحدة جديدة',
                  style: TextStyle(fontFamily: 'NotoSansArabic'),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(fontFamily: 'NotoSansArabic'),
                      decoration: const InputDecoration(
                        labelText: 'اسم الوحدة',
                        labelStyle: TextStyle(fontFamily: 'NotoSansArabic'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceCtrl,
                      style: const TextStyle(fontFamily: 'NotoSansArabic'),
                      decoration: const InputDecoration(
                        labelText: 'السعر',
                        labelStyle: TextStyle(fontFamily: 'NotoSansArabic'),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(fontFamily: 'NotoSansArabic'),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty ||
                          priceCtrl.text.trim().isEmpty) return;

                      await FirebaseFirestore.instance
                          .collection('item_units')
                          .add({
                        'item_id': itemId,
                        'unit_id':
                        DateTime.now().millisecondsSinceEpoch.toString(),
                        'unit_name': nameCtrl.text.trim(),
                        'unit_price': double.tryParse(priceCtrl.text.trim()) ?? 0,
                        'created_at': FieldValue.serverTimestamp(),
                      });
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'حفظ',
                      style: TextStyle(fontFamily: 'NotoSansArabic'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        body: StreamBuilder<QuerySnapshot>(
            stream: unitsRef.snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'لا توجد وحدات بعد',
                    style: TextStyle(fontFamily: 'NotoSansArabic'),
                  ),
                );
              }

              final docs = snap.data!.docs;

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final d = doc.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(
                        d['unit_name'] ?? '',
                        style: const TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'السعر: ${d['unit_price']}',
                        style: const TextStyle(fontFamily: 'NotoSansArabic'),
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          // 🔹 زر تعديل الوحدة
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blueAccent),
                            onPressed: () async {
                              nameCtrl.text = d['unit_name'] ?? '';
                              priceCtrl.text = d['unit_price'].toString();

                              await showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text(
                                    'تعديل الوحدة',
                                    style: TextStyle(fontFamily: 'NotoSansArabic'),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: nameCtrl,
                                        style: const TextStyle(
                                            fontFamily: 'NotoSansArabic'),
                                        decoration: const InputDecoration(
                                          labelText: 'اسم الوحدة',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: priceCtrl,
                                        style: const TextStyle(
                                            fontFamily: 'NotoSansArabic'),
                                        decoration: const InputDecoration(
                                          labelText: 'السعر',
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('إلغاء'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await doc.reference.update({
                                          'unit_name': nameCtrl.text.trim(),
                                          'unit_price': double.tryParse(
                                              priceCtrl.text.trim()) ??
                                              0,
                                        });
                                        Navigator.pop(context);
                                      },
                                      child: const Text('حفظ'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // 🔹 زر الحذف
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('تأكيد الحذف'),
                                  content: const Text(
                                      'هل تريد حذف هذه الوحدة؟'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('إلغاء')),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('حذف')),
                                  ],
                                ),
                              ) ??
                                  false;

                              if (confirm) {
                                await doc.reference.delete();
                              }
                            },
                          ),
                        ],
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