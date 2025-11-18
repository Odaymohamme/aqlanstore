import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeFormScreen extends StatefulWidget {
  final String? employeeId;
  final Map<String, dynamic>? data;

  const EmployeeFormScreen({super.key, this.employeeId, this.data});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  String _role = 'Administrator';
  String _status = 'active';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _name.text = widget.data!['name'] ?? '';
      _email.text = widget.data!['email'] ?? '';
      _phone.text = widget.data!['phone'] ?? '';
      _username.text = widget.data!['username'] ?? '';
      _password.text = widget.data!['password'] ?? '';
      _role = widget.data!['role'] ?? 'Administrator';
      _status = widget.data!['status'] ?? 'active';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final doc = FirebaseFirestore.instance.collection('employees');
    final data = {
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'username': _username.text.trim(),
      'password': _password.text.trim(),
      'role': _role,
      'status': _status,
      'created_at': DateTime.now(),
    };

    try {
      if (widget.employeeId == null) {
        await doc.add(data);
      } else {
        await doc.doc(widget.employeeId).update(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حفظ البيانات بنجاح ✅',
              style: const TextStyle(fontFamily: 'NotoSansArabic'),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء الحفظ ⚠',
              style: const TextStyle(fontFamily: 'NotoSansArabic'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تأكيد الحذف',
          style: TextStyle(fontFamily: 'NotoSansArabic'),
        ),
        content: const Text(
          'هل أنت متأكد أنك تريد حذف هذا الموظف؟',
          style: TextStyle(fontFamily: 'NotoSansArabic'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'NotoSansArabic'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'حذف',
              style: TextStyle(
                fontFamily: 'NotoSansArabic',
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && widget.employeeId != null) {
      await FirebaseFirestore.instance
          .collection('employees')
          .doc(widget.employeeId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حذف الموظف بنجاح 🗑',
              style: const TextStyle(fontFamily: 'NotoSansArabic'),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.employeeId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'تعديل الموظف' : 'إضافة موظف',
          style: const TextStyle(
            fontFamily: 'NotoSansArabic',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _delete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_name, 'الاسم', 'أدخل الاسم'),
              _buildTextField(_username, 'اسم المستخدم', 'أدخل اسم المستخدم'),
              _buildTextField(_email, 'البريد الإلكتروني', 'أدخل البريد الإلكتروني'),
              _buildTextField(_phone, 'رقم الهاتف', 'أدخل رقم الهاتف'),
              _buildTextField(_password, 'كلمة المرور', 'أدخل كلمة المرور',
                  obscure: true),

              const SizedBox(height: 10),

              _buildDropdown(
                label: 'الدور الوظيفي',
                value: _role,
                items: const [
                  DropdownMenuItem(value: 'Administrator', child: Text('مدير')),
                  DropdownMenuItem(value: 'Product Manager', child: Text('مسؤول منتجات')),
                  DropdownMenuItem(value: 'Fulfillment Agent', child: Text('مسؤول شحن')),
                  DropdownMenuItem(value: 'Content Editor', child: Text('محرر محتوى')),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),

              const SizedBox(height: 10),

              _buildDropdown(
                label: 'الحالة',
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('نشط')),
                  DropdownMenuItem(value: 'inactive', child: Text('موقوف')),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),

              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Icon(Icons.save),
                label: Text(
                  _saving ? 'جارٍ الحفظ...' : 'حفظ البيانات',
                  style: const TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String validatorMsg,
      {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: 'NotoSansArabic'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (v) => v!.isEmpty ? validatorMsg : null,
        style: const TextStyle(fontFamily: 'NotoSansArabic'),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: 'NotoSansArabic'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        style: const TextStyle(fontFamily: 'NotoSansArabic'),
        );
    }
}