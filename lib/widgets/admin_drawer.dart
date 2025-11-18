import 'package:flutter/material.dart';
import '../screens/categories_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/offers_edit_screen.dart';
import '../screens/products_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/customers_screen.dart';
import '../screens/employees_screen.dart';
import '../screens/roles_screen.dart';
// import '../screens/banners_screen.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key, required String currentPage});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            child: Text(
              'إدارة بن عقلان',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansArabic',
              ),
            ),
          ),
          _tile(context, Icons.dashboard, 'لوحة التحكم', const DashboardScreen()),
          _tile(context, Icons.category, 'المنتجات', const ProductsScreen()),
          _tile(context, Icons.category, 'التصنيفات', const CategoriesScreen()),
          _tile(context, Icons.local_offer, 'العروض', const SpecialOffersListScreen()),
          _tile(context, Icons.shopping_cart, 'الطلبات', const OrdersScreen()),
          _tile(context, Icons.people, 'العملاء', const CustomersScreen()),
          _protectedTile(context, Icons.people_outline_rounded, 'الموظفين', const EmployeesScreen()),
          _tile(context, Icons.settings, 'الصلاحيات', const RolesScreen()),
        ],
      ),
    );
  }

  // 🔹 التبويبات العادية
  ListTile _tile(BuildContext ctx, IconData icon, String title, Widget screen) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontFamily: 'NotoSansArabic')),
      onTap: () {
        Navigator.pop(ctx); // يغلق الـ Drawer
        Future.delayed(const Duration(milliseconds: 150), () {
          Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => screen));
        });
      },
    );
  }

  // 🔐 تبويب محمي بكلمة مرور
  ListTile _protectedTile(BuildContext ctx, IconData icon, String title, Widget screen) {
    return ListTile(
        leading: Icon(icon, color: Colors.redAccent),
        title: Text(title, style: const TextStyle(fontFamily: 'NotoSansArabic')),
        onTap: () async {
          // 🔹 حفظ context صالح قبل إغلاق الـ Drawer
          final rootContext = Navigator.of(ctx).context;

          // إغلاق الـ Drawer أولاً
          Navigator.pop(ctx);

          // ننتظر لحين غلقه فعليًا
          await Future.delayed(const Duration(milliseconds: 200));

          final passwordCtrl = TextEditingController();
          final result = await showDialog<bool>(
            context: rootContext,
            builder: (dialogCtx) {
              return AlertDialog(
                title: const Text(
                  'إدخال كلمة المرور',
                  style: TextStyle(fontFamily: 'NotoSansArabic'),
                ),
                content: TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    border: OutlineInputBorder(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx, false),
                    child: const Text('إلغاء', style: TextStyle(fontFamily: 'NotoSansArabic')),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (passwordCtrl.text.trim() == 'odayoday') {
                        Navigator.pop(dialogCtx, true);
                      } else {
                        ScaffoldMessenger.of(rootContext).showSnackBar(
                          const SnackBar(
                            content: Text('كلمة المرور غير صحيحة'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    child: const Text('دخول', style: TextStyle(fontFamily: 'NotoSansArabic')),
                  ),
                ],
              );
            },
          );

          if (result == true) {
            // ✅ فتح الشاشة بعد التأكد من كلمة المرور
            Navigator.of(rootContext).push(MaterialPageRoute(builder: (_) => screen));
          }
          },
        );
    }
}