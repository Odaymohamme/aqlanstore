import 'package:adminaqlanstore/widgets/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SpecialOffersScreen extends StatefulWidget {
  const SpecialOffersScreen({Key? key}) : super(key: key);

  @override
  State<SpecialOffersScreen> createState() => _SpecialOffersScreenState();
}

class _SpecialOffersScreenState extends State<SpecialOffersScreen> {
  final _itemsRef = FirebaseFirestore.instance.collection('items');
  final _offersRef = FirebaseFirestore.instance.collection('special_offers');
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _newPriceCtrl = TextEditingController();
  final TextEditingController _offerTypeCtrl = TextEditingController();

  Map<String, dynamic>? _selectedItem;
  bool _saving = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _newPriceCtrl.dispose();
    _offerTypeCtrl.dispose();
    super.dispose();
  }

  Future<bool> _hasDuplicateOffer(String itemId) async {
    final q = await _offersRef.where('item_id', isEqualTo: itemId).get();
    return q.docs.isNotEmpty;
  }

  Future<void> _saveOffer() async {
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار منتج أولاً', style: TextStyle(fontFamily: 'NotoSansArabic'))),
      );
      return;
    }
    if (_newPriceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال السعر الجديد', style: TextStyle(fontFamily: 'NotoSansArabic'))),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final item = _selectedItem!;
      final itemId = item['item_id']?.toString() ?? '';

      if (itemId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠ لا يمكن حفظ العرض بدون item_id', style: TextStyle(fontFamily: 'NotoSansArabic'))),
        );
        setState(() => _saving = false);
        return;
      }

      final exists = await _hasDuplicateOffer(itemId);
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠ يوجد عرض مسبق لهذا المنتج', style: TextStyle(fontFamily: 'NotoSansArabic'))),
        );
        setState(() => _saving = false);
        return;
      }

      final offerData = {
        'item_id': itemId,
        'old_price': item['price'].toString(),
        'new_price': _newPriceCtrl.text.trim(),
        'offer_type': _offerTypeCtrl.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      };

      await _offersRef.add(offerData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم إضافة العرض بنجاح', style: TextStyle(fontFamily: 'NotoSansArabic'))),
        );
        setState(() {
          _selectedItem = null;
          _newPriceCtrl.clear();
          _offerTypeCtrl.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e', style: const TextStyle(fontFamily: 'NotoSansArabic'))),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = const TextStyle(fontFamily: 'NotoSansArabic');

    return Scaffold(
        appBar: AppBar(
          title: Text('إضافة عرض جديد', style: textStyle.copyWith(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        endDrawer: const AdminDrawer(currentPage: 'SpecialOffersScreen'),
        body: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  style: textStyle,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن صنف بالاسم أو الرقم...',
                    hintStyle: textStyle,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _itemsRef.snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final items = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? '').toString().toLowerCase();
                        final itemId = (data['item_id'] ?? '').toString().toLowerCase();
                        final query = _searchQuery.toLowerCase();
                        return query.isEmpty || name.contains(query) || itemId.contains(query);
                      }).toList();

                      if (items.isEmpty) {
                        return Center(child: Text('لا توجد نتائج مطابقة', style: textStyle));
                      }

                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final data = items[i].data() as Map<String, dynamic>;
                          final img = data['image_url'] ?? '';
                          final isSelected = _selectedItem != null && _selectedItem!['item_id'] == data['item_id'];

                          return Card(
                            color: isSelected ? Colors.teal.shade50 : null,
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            child: ListTile(
                              onTap: () => setState(() => _selectedItem = data),
                              leading: img.isNotEmpty
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(img, width: 70, height: 70, fit: BoxFit.cover),
                              )
                                  : const Icon(Icons.image_not_supported, size: 50),
                              title: Text(
                                data['name'] ?? 'منتج بدون اسم',
                                style: textStyle.copyWith(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'السعر الحالي: ${data['price'] ?? 'غير محدد'} ر.س',
                                style: textStyle,
                              ),
                              trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.teal) : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                if (_selectedItem != null) ...[
                  const Divider(thickness: 1.2),
                  Text(
                    'المنتج المحدد: ${_selectedItem!['name']}',
                    style: textStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('السعر القديم: ${_selectedItem!['price']} ر.س', style: textStyle),
                  const SizedBox(height: 8),
                  Text('item_id : ${_selectedItem!['item_id'] ?? 'no item_id'}', style: textStyle),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newPriceCtrl,
                    style: textStyle,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'السعر الجديد',
                      labelStyle: textStyle,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _offerTypeCtrl,
                    style: textStyle,
                    decoration: InputDecoration(
                      labelText: 'نوع العرض (مثلاً: تخفيض، عرض خاص...)',
                      labelStyle: textStyle,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _saveOffer,
                      icon: const Icon(Icons.save),
                      label: _saving
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : Text('حفظ العرض', style: textStyle.copyWith(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            ),
        );
    }
}