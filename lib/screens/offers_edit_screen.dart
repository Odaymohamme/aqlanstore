import 'package:adminaqlanstore/screens/banners_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SpecialOffersListScreen extends StatefulWidget {
  const SpecialOffersListScreen({Key? key}) : super(key: key);

  @override
  State<SpecialOffersListScreen> createState() =>
      _SpecialOffersListScreenState();
}

class _SpecialOffersListScreenState extends State<SpecialOffersListScreen> {
  final _offersRef = FirebaseFirestore.instance.collection('special_offers');
  final _itemsRef = FirebaseFirestore.instance.collection('items');

  /// 🧩 دالة لجلب بيانات المنتج من مجموعة items
  Future<Map<String, dynamic>?> _fetchItem(String itemId) async {
    try {
      final snap =
      await _itemsRef.where('item_id', isEqualTo: itemId).limit(1).get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.first.data();
      }
      return null;
    } catch (e) {
      debugPrint('⚠ خطأ في جلب بيانات الصنف: $e');
      return null;
    }
  }

  /// ✏ تعديل العرض
  Future<void> _editOffer(String offerId, Map<String, dynamic> offerData) async {
    final newPriceCtrl =
    TextEditingController(text: offerData['new_price']?.toString() ?? '');
    final offerTypeCtrl =
    TextEditingController(text: offerData['offer_type']?.toString() ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل العرض'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPriceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'السعر الجديد',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: offerTypeCtrl,
              decoration: const InputDecoration(
                labelText: 'نوع العرض',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    ) ??
        false;

    if (ok) {
      await _offersRef.doc(offerId).update({
        'new_price': newPriceCtrl.text.trim(),
        'offer_type': offerTypeCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم تحديث العرض بنجاح')),
        );
      }
    }
  }

  /// 🚀 التحقق من وجود عرض سابق لنفس الصنف
  Future<bool> _hasDuplicateOffer(String itemId) async {
    final q = await _offersRef.where('item_id', isEqualTo: itemId).get();
    return q.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('العروض الخاصة'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text('إضافة عرض'),
          onPressed: () async {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SpecialOffersScreen()),
            );
          },
        ),
        body: StreamBuilder<QuerySnapshot>(
            stream: _offersRef.orderBy('offer_id', descending: true).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final offers = snap.data!.docs;
              if (offers.isEmpty) {
                return const Center(child: Text('لا توجد عروض حالياً'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: offers.length,
                itemBuilder: (context, index) {
                  final offer = offers[index].data() as Map<String, dynamic>;
                  final offerId = offers[index].id;
                  final itemId = offer['item_id']?.toString() ?? '';

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: _fetchItem(itemId),
                    builder: (context, itemSnap) {
                      if (!itemSnap.hasData) {
                        return const ListTile(
                          title: Text('جاري تحميل بيانات الصنف...'),
                          leading: CircularProgressIndicator(),
                        );
                      }

                      final item = itemSnap.data;
                      final name = item?['name'] ?? 'منتج غير معروف';
                      final image = item?['image_url'] ?? '';

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        elevation: 3,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: image.isNotEmpty
                                ? Image.network(image,
                                width: 60, height: 60, fit: BoxFit.cover)
                                : const Icon(Icons.image_not_supported,
                                size: 50, color: Colors.grey),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('نوع العرض: ${offer['offer_type'] ?? ''}'),
                              Text('السعر القديم: ${offer['old_price']} ر.س'),
                              Text(
                                'السعر الجديد: ${offer['new_price']} ر.س',
                                style: const TextStyle(
                                  color: Colors.teal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                const Icon(Icons.edit, color: Colors.blueAccent),
                                onPressed: () =>
                                    _editOffer(offerId, offer),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('تأكيد الحذف'),
                                      content: const Text(
                                          'هل تريد حذف هذا العرض نهائياً؟'),
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
                                  );
                                  if (ok == true) {
                                    await _offersRef.doc(offerId).delete();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('تم حذف العرض')),
                                      );
                                    }
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
              );
            },
            ),
        );
    }
}