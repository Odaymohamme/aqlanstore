import 'package:flutter/material.dart';
import '../services/admin_api_service.dart';
import '../widgets/admin_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _kpi;
  bool _loading = true;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      setState(() => _loading = true);
      final res = await AdminApi.fetchKpis();

      if (!mounted) return;

      if (res['success'] == true) {
        setState(() {
          _kpi = res['data'];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      debugPrint('❌ خطأ أثناء جلب البيانات: $e');
    } finally {
      _isFetching = false;
    }
  }

  @override
  void dispose() {
    _isFetching = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'لوحة التحكم',
          style: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      endDrawer: const AdminDrawer(currentPage: 'DashboardScreen'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetch,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _statCard(
                title: 'إجمالي العملاء',
                value: '${_kpi?['total_customers'] ?? 0}',
                icon: Icons.people,
                color: Colors.teal,
              ),
              _statCard(
                title: 'طلبات اليوم',
                value: '${_kpi?['today_orders'] ?? 0}',
                icon: Icons.today,
                color: Colors.orange,
              ),
              _statCard(
                title: 'إجمالي الطلبات',
                value: '${_kpi?['total_orders'] ?? 0}',
                icon: Icons.shopping_bag,
                color: Colors.blue,
              ),
              _statCard(
                title: 'إيراد مؤكد',
                value:
                '${_kpi?['total_revenue']?.toStringAsFixed(2) ?? '0'} ر.س',
                icon: Icons.attach_money,
                color: Colors.green,
              ),
              // ✅ البطاقة الجديدة لعدد الأصناف
              _statCard(
                title: 'عدد الأصناف',
                value: '${_kpi?['total_items'] ?? 0}',
                icon: Icons.inventory_2,
                color: Colors.deepPurple,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            ),
        );
    }
}