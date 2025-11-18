import 'package:adminaqlanstore/widgets/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_form_screen.dart';
import 'item_units_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _items = FirebaseFirestore.instance.collection('items');
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'إدارة الأصناف',
            style: TextStyle(fontFamily: 'NotoSansArabic'),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        endDrawer: const AdminDrawer(currentPage: 'ProductsScreen'),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProductFormScreen(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
        body: Column(
            children: [
              // 🔍 مربع البحث
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'ابحث عن صنف بالاسم أو الرقم...',
                    hintStyle: const TextStyle(fontFamily: 'NotoSansArabic'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'NotoSansArabic'),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _items.orderBy('created_at', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator()
                      );
                    }

                    final docs = snapshot.data!.docs;

                    // 🔍 فلترة محلية حسب البحث
                    final filtered = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '').toString().toLowerCase();
                      final id = doc.id.toLowerCase();
                      final query = _searchQuery.toLowerCase();
                      return query.isEmpty || name.contains(query) || id.contains(query);
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          'لم يتم العثور على أصناف',
                          style: TextStyle(fontFamily: 'NotoSansArabic'),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final d = filtered[i].data() as Map<String, dynamic>;
                        final id = filtered[i].id;
                        final imageUrl = (d['image_url'] ?? '').toString();

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                    imageUrl,
                                    width: 65,
                                    height: 65,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 50),
                                  )
                                      : Container(
                                    width: 65,
                                    height: 65,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image_not_supported,
                                        size: 45, color: Colors.grey),
                                  ),
                                ),
                                title: Text(
                                  d['name'] ?? 'بدون اسم',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      fontFamily: 'NotoSansArabic'),
                                ),
                                subtitle: Text(
                                  'السعر: ${d['price']}  •  الوحدة: ${d['unit_name']}',
                                  style: const TextStyle(fontFamily: 'NotoSansArabic'),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        (d['status_id'] == "0" || d['status'] == "inactive")
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.orange,
                                      ),
                                      tooltip: 'إظهار / إخفاء الصنف',
                                      onPressed: () {
                                        _items.doc(id).update({
                                          'status_id': d['status_id'] == "0" ? "1" : "0",
                                          'status': d['status'] == "inactive" ? "active" : "inactive",
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                      tooltip: 'تعديل الصنف',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProductFormScreen(
                                              productId: id,
                                              productData: d,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'حذف الصنف',
                                      onPressed: () async {
                                        final ok = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text(
                                              'تأكيد الحذف',
                                              style: TextStyle(fontFamily: 'NotoSansArabic'),
                                            ),
                                            content: const Text(
                                              'هل تريد حذف هذا الصنف؟',
                                              style: TextStyle(fontFamily: 'NotoSansArabic'),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context, false),
                                                child: const Text(
                                                  'إلغاء',
                                                  style: TextStyle(fontFamily: 'NotoSansArabic'),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context, true),
                                                child: const Text(
                                                  'حذف',
                                                  style: TextStyle(fontFamily: 'NotoSansArabic'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ) ??
                                            false;

                                        if (ok) {
                                          await _items.doc(id).delete();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                  'تم حذف الصنف بنجاح',
                                                  style: TextStyle(fontFamily: 'NotoSansArabic'),
                                                )),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              // 🔘 زر الوحدات
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10, left: 8, right: 8),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ItemUnitsScreen(
                                          itemId: d['item_id'] ?? '',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.category),
                                  label: const Text(
                                    "الوحدات",
                                    style: TextStyle(fontFamily: 'NotoSansArabic'),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal.shade600,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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