import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  final String? customerId; // قد يمرر من الشاشة السابقة أو يترك null

  const OrderDetailsScreen({super.key, required this.orderId, this.customerId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _loading = true;
  Map<String, dynamic>? _orderData;
  Map<String, dynamic>? _customerData;
  List<Map<String, dynamic>> _items = []; // كل عنصر يحتوي: order_item fields + itemName + imageUrl
  String? _customerPhone;

  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  Future<void> _loadEverything() async {
    setState(() => _loading = true);

    try {
      final orderSnap = await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).get();
      if (!orderSnap.exists) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الطلب غير موجود')));
        setState(() => _loading = false);
        return;
      }

      final orderData = orderSnap.data()!;
      _orderData = orderData;

      // 1) customerId: من widget أو من حقل order
      String? customerId = widget.customerId ?? orderData['customer_id']?.toString();

      // 2) جلب بيانات العميل (إن وُجد معرف)
      if (customerId != null && customerId.isNotEmpty) {
        final custSnap = await FirebaseFirestore.instance.collection('customers').doc(customerId).get();
        if (custSnap.exists) {
          _customerData = custSnap.data();
          _customerPhone = _customerData?['phone ']?.toString();
        } else {
          // قد يكون customerId not doc id but a numeric/id stored in field; نبحث أيضاً عن document الذي يمتلك customer_id == customerId
          final q = await FirebaseFirestore.instance.collection('customers').where('customer_id', isEqualTo: customerId).limit(1).get();
          if (q.docs.isNotEmpty) {
            _customerData = q.docs.first.data();
            _customerPhone = _customerData?['phone']?.toString();
          }
        }
      }

      // 3) جلب عناصر الطلب من order_items حيث order_id == widget.orderId
      final orderItemsQ = await FirebaseFirestore.instance
          .collection('order_items')
          .where('order_id', isEqualTo: widget.orderId)
          .get();

      final List<Map<String, dynamic>> itemsList = [];

      for (var doc in orderItemsQ.docs) {
        final data = doc.data();
        // محاولة جلب اسم/صورة الصنف من مجموعة items
        String? itemId = data['item_id']?.toString();
        String? imageUrl;
        String? itemName = data['item_name']?.toString() ?? data['custom_name']?.toString();

        if (itemId != null && itemId.isNotEmpty) {
          // نحاول أولاً البحث عن مستند في items حيث item_id == هذا الـ itemId
          final q = await FirebaseFirestore.instance.collection('items').where('item_id', isEqualTo: itemId).limit(1).get();
          if (q.docs.isNotEmpty) {
            final itemDoc = q.docs.first.data();
            imageUrl = itemDoc['image_url']?.toString();
            itemName ??= itemDoc['name']?.toString();
          } else {
            // محاولة استدعاء المستند بالـ doc id (fallback)
            try {
              final fallback = await FirebaseFirestore.instance.collection('items').doc(itemId).get();
              if (fallback.exists) {
                final d = fallback.data()!;
                imageUrl = d['image_url']?.toString();
                itemName ??= d['name']?.toString();
              }
            } catch (_) {
              // تجاهل الخطأ
            }
          }
        }

        itemsList.add({
          'order_item_doc_id': doc.id,
          ...data,
          'resolved_item_name': itemName ?? '',
          'resolved_image_url': imageUrl ?? '',
        });
      }

      setState(() {
        _items = itemsList;
      });
    } catch (e, st) {
      debugPrint('Error loading order details: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء جلب بيانات الطلب: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _acceptOrderAndSendWhatsApp() async {
    // تحقق من وجود رقم الهاتف
    String? phone = _customerPhone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رقم الهاتف غير متوفر للعميل')));
      return;
    }

    // تحديث حالة الطلب إلى accepted (أو أي قيمة تريدها)
    try {
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
        'status': 'accepted',
        'accepted_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating order status: $e');
    }

    // بناء رسالة واتساب
    final total = _orderData?['total']?.toString() ?? '-';
    final message = 'تم استلام طلبك بنجاح بمبلغ $total ر.س. سوف يتم توصيله لك في أسرع وقت ممكن. '
        'في حال لم يسبق وأن تم توصيل لكم، سنتواصل معكم قريباً.';

    // تأكد من صيغة الرقم: wa.me يتطلب رقمًا بصيغة دولية بدون + أو صفر بادئ.
    // المستخدم يجب أن يخزن رقم العميل بصيغة دولية (مثال: 9677XXXXXXXX) وإلا عليك تحويله هنا.
    final phoneForUrl = phone.replaceAll(RegExp(r'[\s\+\-]'), ''); // إزالة مسافات وعلامات
    final url = Uri.parse('https://wa.me/$phoneForUrl?text=${Uri.encodeComponent(message)}');

    // افتح الرابط
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم فتح واتساب')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن فتح واتساب')));
    }

    // بعد الإرسال — نعيد تحميل لعرض اللون الجديد
    await _loadEverything();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل الطلب', style: TextStyle(fontFamily: 'NotoSansArabic')),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
            onRefresh: _loadEverything,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('رقم الطلب: ${widget.orderId}', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic')),
                          const SizedBox(height: 6),
                          Text('رقم العميل: ${_customerData?['customer_id'] ?? _orderData?['customer_id'] ?? 'غير متوفر'}', style: const TextStyle(fontFamily: 'NotoSansArabic')),
                          const SizedBox(height: 6),
                          Text('رقم الهاتف: ${_customerPhone ?? 'غير متوفر'}', style: const TextStyle(fontFamily: 'NotoSansArabic', color: Colors.teal)),
                          const SizedBox(height: 6),
                          Text('إجمالي الطلب: ${_orderData?['total'] ?? '-'} ر.س', style: const TextStyle(fontFamily: 'NotoSansArabic')),
                          const SizedBox(height: 6),
                          Text('طريقة الدفع: ${_orderData?['payment_method'] ?? '-'}', style: const TextStyle(fontFamily: 'NotoSansArabic')),
                          const SizedBox(height: 6),
                          Text('العنوان: ${_orderData?['address'] ?? '-'}', style: const TextStyle(fontFamily: 'NotoSansArabic')),
                          const SizedBox(height: 6),
                          Text('التاريخ: ${_orderData?['order_date'] is Timestamp ? (_orderData!['order_date'] as Timestamp).toDate().toString() : (_orderData?['order_date'] ?? '-')}', style: const TextStyle(fontFamily: 'NotoSansArabic')),
                        ],
                      ),
                    ),
                  ),

                  // زر اعتماد وواتساب
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text('اعتماد الطلب وإرسال واتساب', style: TextStyle(fontFamily: 'NotoSansArabic')),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: _acceptOrderAndSendWhatsApp,
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Text('المنتجات في الطلب:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'NotoSansArabic')),
                  const SizedBox(height: 8),

                  // قائمة العناصر
                  ..._items.map((it) {
                    final img = (it['resolved_image_url'] ?? '').toString();
                    final name = (it['resolved_item_name'] ?? it['item_name'] ?? it['custom_name'] ?? '').toString();
                    final qty = it['quantity']?.toString() ?? '1';
                    final price = it['price']?.toString() ?? '-';
                    final unit = it['unit']?.toString() ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: img.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            img,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, st) => const Icon(Icons.broken_image),
                          ),
                        )
                            : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported),
                        ),
                        title: Text(name, style: const TextStyle(fontFamily: 'NotoSansArabic')),
                        subtitle: Text('الكمية: $qty • السعر: $price ر.س • الوحدة: $unit', style: const TextStyle(fontFamily: 'NotoSansArabic')),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            ),
        );
    }
}