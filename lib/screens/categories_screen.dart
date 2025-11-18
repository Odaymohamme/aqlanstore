import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/admin_drawer.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _categoriesRef = FirebaseFirestore.instance.collection('categories');
  final supabase = Supabase.instance.client;

  bool _loading = false;

  /// 🧩 اختيار ورفع الصورة إلى Supabase
  Future<String?> _pickAndUploadImage(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    try {
      final fileName = 'categories/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // عرض التحميل المؤقت أثناء الرفع
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        await supabase.storage.from('products').uploadBinary(fileName, bytes);
      } else {
        final file = File(picked.path);
        await supabase.storage.from('products').upload(fileName, file);
      }

      // الحصول على رابط الصورة
      final publicUrl = supabase.storage.from('products').getPublicUrl(fileName);

      if (context.mounted) Navigator.pop(context); // إغلاق التحميل بعد الرفع
      return publicUrl;
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء رفع الصورة: $e')),
      );
      return null;
    }
  }

  /// 🧩 عرض نافذة الإضافة أو التعديل
  Future<void> _showFormDialog({String? docId, Map<String, dynamic>? data}) async {
    final _formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: data?['name'] ?? '');
    final descCtrl = TextEditingController(text: data?['description'] ?? '');
    String? imageUrl = data?['image'] ?? '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              docId == null ? 'إضافة تصنيف جديد' : 'تعديل التصنيف',
              style: const TextStyle(fontFamily: 'NotoSansArabic'),
            ),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'اسم التصنيف'),
                      validator: (v) => v!.isEmpty ? 'الرجاء إدخال الاسم' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'الوصف'),
                    ),
                    const SizedBox(height: 12),

                    // 🖼 مربع عرض / اختيار الصورة
                    GestureDetector(
                      onTap: () async {
                        final newUrl = await _pickAndUploadImage(context);
                        if (newUrl != null) {
                          setDialogState(() => imageUrl = newUrl);
                        }
                      },
                      child: Container(
                        height: 130,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: imageUrl != null && imageUrl!.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                            : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 36, color: Colors.grey),
                              SizedBox(height: 6),
                              Text('اضغط لاختيار صورة'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('حفظ'),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  setDialogState(() => _loading = true);

                  // عرض شاشة التحميل أثناء الحفظ
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  final payload = {
                    'name': nameCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'image': imageUrl ?? '',
                    'category_id': data?['category_id'] ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                  };

                  try {
                    if (docId == null) {
                      await _categoriesRef.add(payload);
                    } else {
                      await _categoriesRef.doc(docId).update(payload);
                    }

                    if (context.mounted) Navigator.pop(context); // إغلاق شاشة التحميل
                    if (context.mounted) Navigator.pop(context); // إغلاق نافذة الإدخال

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.green.shade600,
                        content: const Text(
                          '✅ تم الحفظ بنجاح',
                          style: TextStyle(fontFamily: 'NotoSansArabic'),
                        ),
                      ),
                    );
                  } catch (e) {
                    if (context.mounted) Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')),
                    );
                  } finally {
                    setDialogState(() => _loading = false);
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

  /// 🗑 حذف التصنيف
  Future<void> _deleteCategory(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذا التصنيف؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    ) ??
        false;

    if (confirm) {
      await _categoriesRef.doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('🗑 تم حذف التصنيف بنجاح')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'إدارة التصنيفات',
            style: TextStyle(fontFamily: 'NotoSansArabic'),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        endDrawer: const AdminDrawer(currentPage: 'CategoriesScreen'),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showFormDialog(),
          child: const Icon(Icons.add),
        ),
        body: StreamBuilder<QuerySnapshot>(
            stream: _categoriesRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(child: Text('لا توجد تصنيفات بعد'));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final imageUrl = data['image'];

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 3,
                    child: ListTile(
                      leading: (imageUrl != null && imageUrl.toString().isNotEmpty)
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image, size: 40),
                        ),
                      )
                          : const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                      title: Text(
                        data['name'] ?? '',
                        style: const TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(data['description'] ?? '',
                          style: const TextStyle(fontFamily: 'NotoSansArabic')),
                      trailing: Wrap(
                        spacing: 6,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showFormDialog(docId: docs[index].id, data: data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteCategory(docs[index].id),
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