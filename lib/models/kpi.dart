// models/kpi.dart
class Kpi {
  final int totalCustomers, totalOrders, todayOrders;
  final double totalRevenue;
  Kpi({required this.totalCustomers, required this.totalOrders, required this.totalRevenue, required this.todayOrders});
  factory Kpi.fromJson(Map<String,dynamic> j)=>Kpi(
      totalCustomers: j['total_customers']??0,
      totalOrders: j['total_orders']??0,
      totalRevenue: (j['total_revenue']??0).toDouble(),
      todayOrders: j['today_orders']??0
  );
}
