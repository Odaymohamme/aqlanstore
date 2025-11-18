import 'package:adminaqlanstore/screens/employees_form_screen.dart';
import 'package:adminaqlanstore/widgets/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final employees = FirebaseFirestore.instance.collection('employees');

    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'إدارة المستخدمين والصلاحيات',
            style: TextStyle(fontFamily: 'NotoSansArabic'),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        endDrawer: const AdminDrawer(currentPage: 'EmployeesScreen'),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmployeeFormScreen()),
            );
          },
        ),
        body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(fontFamily: 'NotoSansArabic'),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'ابحث بالاسم أو البريد أو رقم الهاتف...',
                    hintStyle: const TextStyle(fontFamily: 'NotoSansArabic'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: employees.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '').toString().toLowerCase();
                      final email = (data['email'] ?? '').toString().toLowerCase();
                      final phone = (data['phone'] ?? '').toString().toLowerCase();
                      return name.contains(_query.toLowerCase()) ||
                          email.contains(_query.toLowerCase()) ||
                          phone.contains(_query.toLowerCase());
                    }).toList();

                    if (docs.isEmpty) {
                      return const Center(
                          child: Text(
                            'لا يوجد موظفون مطابقون.',
                            style: TextStyle(fontFamily: 'NotoSansArabic'),
                          ));
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: data['status'] == "active"
                                  ? Colors.green
                                  : Colors.grey,
                              child: const Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(
                              data['name'] ?? '',
                              style: const TextStyle(fontFamily: 'NotoSansArabic'),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📧 ${data['email'] ?? '-'}',
                                  style:
                                  const TextStyle(fontFamily: 'NotoSansArabic'),
                                ),
                                Text(
                                  '📞 ${data['phone'] ?? '-'}',
                                  style:
                                  const TextStyle(fontFamily: 'NotoSansArabic'),
                                ),
                                Text(
                                  '🎭 الدور: ${data['role'] ?? 'غير محدد'}',
                                  style:
                                  const TextStyle(fontFamily: 'NotoSansArabic'),
                                ),
                              ],
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blueAccent),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EmployeeFormScreen(
                                          employeeId: docs[i].id,
                                          data: data,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    data['status'] == "active"
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () async {
                                    await employees.doc(docs[i].id).update({
                                      'status': data['status'] == "active"
                                          ? "inactive"
                                          : "active",
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text(
                                          'تأكيد الحذف',
                                          style: TextStyle(
                                              fontFamily: 'NotoSansArabic'),
                                        ),
                                        content: Text(
                                          'هل تريد حذف ${data['name']}؟',
                                          style: const TextStyle(
                                              fontFamily: 'NotoSansArabic'),
                                        ),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text(
                                                'إلغاء',
                                                style: TextStyle(
                                                    fontFamily: 'NotoSansArabic'),
                                              )),
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text(
                                                'حذف',
                                                style: TextStyle(
                                                    fontFamily: 'NotoSansArabic'),
                                              )),
                                        ],
                                      ),
                                    ) ??
                                        false;
                                    if (ok) await employees.doc(docs[i].id).delete();
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
              ),
            ],
            ),
        );
    }
}