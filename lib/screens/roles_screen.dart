import 'package:adminaqlanstore/widgets/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  final _roleCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final roles = FirebaseFirestore.instance.collection('roles');
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأدوار والصلاحيات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      endDrawer: const AdminDrawer(currentPage: 'RolesScreen'),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRole,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: roles.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(d['name'] ?? 'غير معروف'),
                subtitle: Text('الوصف: ${d['description'] ?? '-'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('تأكيد الحذف'),
                        content: Text('هل تريد حذف الدور "${d['name']}"؟'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('إلغاء')),
                          TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('حذف')),
                        ],
                      ),
                    ) ??
                        false;
                    if (ok) await roles.doc(docs[i].id).delete();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addRole() async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: const Text('إضافة دور جديد'),
            content: TextField(
              controller: _roleCtrl,
              decoration: const InputDecoration(hintText: 'اسم الدور'),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (_roleCtrl.text.trim().isNotEmpty) {
                    await FirebaseFirestore.instance.collection('roles').add({
                      'name': _roleCtrl.text.trim(),
                      'description': 'تمت إضافته يدويًا',
                    });
                  }
                  _roleCtrl.clear();
                  Navigator.pop(context);
                },
                child: const Text('إضافة'),
              ),
            ],
            ),
        );
    }
}