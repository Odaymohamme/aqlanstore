import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('employees')
          .where('email', isEqualTo: _emailCtrl.text.trim())
          .where('password', isEqualTo: _passwordCtrl.text.trim())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _showSnack('❌ البريد الإلكتروني أو كلمة المرور غير صحيحة', Colors.redAccent);
        setState(() => _loading = false);
        return;
      }

      final data = query.docs.first.data();
      final status = (data['status'] ?? '').toString().toLowerCase();

      if (status != 'active') {
        _showSnack('🚫 غير مصرح لك بالدخول. تواصل مع الإدارة.', Colors.orange);
        setState(() => _loading = false);
        return;
      }

      _showSnack('✅ تم تسجيل الدخول بنجاح', Colors.green);
      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      _showSnack('حدث خطأ أثناء تسجيل الدخول: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'NotoSansArabic', fontSize: 14),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.teal.shade700;

    return Scaffold(
        backgroundColor: Colors.teal.shade50,
        body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront, size: 72, color: Colors.teal),
                      const SizedBox(height: 10),
                      Text(
                        "تسجيل الدخول إلى لوحة التحكم",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // البريد الإلكتروني
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          labelStyle: const TextStyle(fontFamily: 'NotoSansArabic'),
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: themeColor, width: 0.5),
                          ),
                        ),
                        style: const TextStyle(fontFamily: 'NotoSansArabic'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                          if (!v.contains('@')) return 'البريد الإلكتروني غير صالح';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // كلمة المرور
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          labelStyle: const TextStyle(fontFamily: 'NotoSansArabic'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off : Icons.visibility,
                              color: Colors.teal,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: themeColor, width: 0.5),
                          ),
                        ),
                        style: const TextStyle(fontFamily: 'NotoSansArabic'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'يرجى إدخال كلمة المرور';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // زر الدخول
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _login,
                          icon: _loading
                              ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.login),
                          label: Text(
                            _loading ? 'جاري التحقق...' : 'تسجيل الدخول',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NotoSansArabic',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // تذييل بسيط
                      Text(
                        "© Aqlan Store Admin Panel",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ),
        );
    }
}