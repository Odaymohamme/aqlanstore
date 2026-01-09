import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductFormScreen extends StatefulWidget {
  final String? productId;
  final Map<String, dynamic>? productData;

  const ProductFormScreen({Key? key, this.productId, this.productData})
      : super(key: key);

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController unitCtrl = TextEditingController(text: 'كيلو');
  final TextEditingController itemIdCtrl = TextEditingController();
  bool _removeBackground = false; // 🟢 REMOVE BG


  String? _categoryId;
  bool _loading = false;
  File? _pickedImage;
  Uint8List? _webImageBytes; // ✅ خاص بالويب
  String? _imageUrl;

  final supabase = Supabase.instance.client;
  final _itemsCollection = FirebaseFirestore.instance.collection('items');

  @override
  void initState() {
    super.initState();
    if (widget.productData != null) {
      final d = widget.productData!;
      nameCtrl.text = d['name']?.toString() ?? '';
      priceCtrl.text = d['price']?.toString() ?? '';
      descCtrl.text = d['description']?.toString() ?? '';
      unitCtrl.text = d['unit_name']?.toString() ?? 'كيلو';
      _categoryId = d['category_id']?.toString();
      _imageUrl = d['image_url']?.toString();
      itemIdCtrl.text = d['item_id']?.toString() ?? '';
    }
  }

  // 🟢 REMOVE BG
  Future<Uint8List> _removeImageBackground(Uint8List imageBytes) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.remove.bg/v1.0/removebg'),
    );

    request.headers['X-Api-Key'] = 'j7YETYfuibydTk9CirYXPNxL';
    request.files.add(
      http.MultipartFile.fromBytes(
        'image_file',
        imageBytes,
        filename: 'image.jpg',
      ),
    );
    request.fields['size'] = 'auto';

    final response = await request.send();

    if (response.statusCode == 200) {
      return await response.stream.toBytes();
    } else {
      throw Exception('فشل إزالة الخلفية');
    }
  }


  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text(
                'من الملفات',
                style: TextStyle(fontFamily: 'NotoSansArabic'),
              ),
              onTap: () async {
                final img = await picker.pickImage(source: ImageSource.gallery);
                Navigator.pop(context, img);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text(
                'كاميرا',
                style: TextStyle(fontFamily: 'NotoSansArabic'),
              ),
              onTap: () async {
                final img = await picker.pickImage(source: ImageSource.camera);
                Navigator.pop(context, img);
              },
            ),
          ],
        ),
      ),
    );

    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _pickedImage = null;
          _imageUrl = null;
        });
      } else {
        setState(() {
          _pickedImage = File(picked.path);
          _webImageBytes = null;
          _imageUrl = null;
        });
      }
    }
  }

  // ✅ دعم الويب والموبايل في رفع الصورة
  Future<String> _uploadImageToSupabase() async {
    final fileName = 'products/${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      if (kIsWeb && _webImageBytes != null) {
        await supabase.storage.from('products').uploadBinary(
          fileName,
          _webImageBytes!,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
      } else if (_pickedImage != null) {
        await supabase.storage.from('products').upload(fileName, _pickedImage!);
      }
      final signedUrl = await supabase.storage
          .from('products')
          .createSignedUrl(fileName, 60 * 60 * 24 * 365);
      return signedUrl;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoryId == null || _categoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر تصنيفاً')),
      );
      return;
    }

    String itemId = itemIdCtrl.text.trim();
    if (itemId.isEmpty) {
      itemId = 'item_${DateTime.now().millisecondsSinceEpoch}';
    } else {
      final existing = await _itemsCollection
          .where('item_id', isEqualTo: itemId)
          .get();
      if (existing.docs.isNotEmpty &&
          (widget.productId == null ||
              widget.productId!.isEmpty ||
              existing.docs.first.id != widget.productId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رقم الصنف موجود مسبقاً')),
        );
        return;
      }
    }

    setState(() => _loading = true);

    try {
      // ✅ رفع الصورة فقط إن وجدت
      // 🟢 REMOVE BG
      if ((_pickedImage != null && !kIsWeb) ||
          (kIsWeb && _webImageBytes != null)) {

        Uint8List imageBytes;

        if (kIsWeb && _webImageBytes != null) {
          imageBytes = _webImageBytes!;
        } else {
          imageBytes = await _pickedImage!.readAsBytes();
        }

        // 🟢 REMOVE BG (اختياري)
        if (_removeBackground) {
          imageBytes = await _removeImageBackground(imageBytes);
        }

        // 🟢 REMOVE BG – رفع النسخة النهائية
        final fileName = 'products/${DateTime.now().millisecondsSinceEpoch}.png';
        await supabase.storage.from('products').uploadBinary(
          fileName,
          imageBytes,
          fileOptions: const FileOptions(contentType: 'image/png'),
        );

        _imageUrl = await supabase.storage
            .from('products')
            .createSignedUrl(fileName, 60 * 60 * 24 * 365);
      }


      final payload = {
        'name': nameCtrl.text.trim(),
        'price': double.tryParse(priceCtrl.text.trim()) ?? 0.0,
        'description': descCtrl.text.trim(),
        'category_id': _categoryId,
        'unit_name': unitCtrl.text.trim(),
        'image_url': _imageUrl ?? '',
        'item_id': itemId,
        'updated_at': FieldValue.serverTimestamp(),
      };

      final isUpdate =
      (widget.productId != null && widget.productId!.isNotEmpty);
      if (!isUpdate) {
        await _itemsCollection.add({
          ...payload,
          'created_at': FieldValue.serverTimestamp(),
          'status': 'active',
        });
      } else {
        await _itemsCollection.doc(widget.productId).update(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم الحفظ بنجاح')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطأ أثناء الحفظ: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 🧮 زر تكوين الوحدات (لم يتم تغييره)
  Future<void> _generateUnits() async {
    if (itemIdCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رقم الصنف أولاً')),
      );
      return;
    }

    final basePrice = double.tryParse(priceCtrl.text.trim()) ?? 0;
    if (basePrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال سعر صحيح قبل إنشاء الوحدات')),
      );
      return;
    }

    final itemId = itemIdCtrl.text.trim();
    final itemUnitsRef = FirebaseFirestore.instance.collection('item_units');

    setState(() => _loading = true);

    try {
      // ✅ التحقق أولاً هل توجد وحدات سابقة لنفس الصنف
      final existingUnits =
      await itemUnitsRef.where('item_id', isEqualTo: itemId).get();

      if (existingUnits.docs.isNotEmpty) {
        // يوجد وحدات مسبقاً → لا نسمح بإضافة وحدات جديدة
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠ يوجد وحدات لهذا الصنف مسبقاً، لا يمكن إنشاء وحدات جديدة.'),
          ),
        );
        setState(() => _loading = false);
        return;
      }

      // ✅ لا يوجد وحدات → نتابع في إنشاءها
      final units = [
        {"name": "نص", "factor": 2.0},
        {"name": "ربع", "factor": 4.0},
        {"name": "ثمن", "factor": 8.0},
      ];

      for (var u in units) {
        final unitId = "unit_${DateTime.now().millisecondsSinceEpoch}_${u['name']}";
        final unitPrice = basePrice / (u['factor'] as double);

        await itemUnitsRef.add({
          "item_id": itemId,
          "unit_id": unitId,
          "unit_name": u['name'],
          "unit_price": unitPrice,
          "created_at": FieldValue.serverTimestamp(),
        });

        // تأخير بسيط لتفادي تضارب المعرفات في Firestore
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم إنشاء الوحدات بنجاح')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إنشاء الوحدات: $e')),
      );
    } finally {
      setState(() => _loading=false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.productId == null ? 'إضافة صنف' : 'تعديل صنف',
            style: const TextStyle(fontFamily: 'NotoSansArabic'),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // 🟢 التصنيفات
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('categories')
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final docs = snap.data!.docs;
                      return DropdownButtonFormField<String>(
                        value: _categoryId,
                        decoration: const InputDecoration(
                            labelText: 'التصنيف',
                            border: OutlineInputBorder()),
                        items: docs.map((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return DropdownMenuItem(
                            value: d.id,
                            child: Text(data['name'] ?? 'بدون اسم',
                                style: const TextStyle(
                                    fontFamily: 'NotoSansArabic')),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _categoryId = v),
                        validator: (v) => v == null ? 'اختر تصنيفاً' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // باقي الحقول ✅ كما كانت
                  TextFormField(
                    controller: itemIdCtrl,
                    decoration: const InputDecoration(
                        labelText: 'رقم الصنف (اختياري)',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'اسم الصنف', border: OutlineInputBorder()),
                    validator: (v) =>
                    v == null || v.isEmpty ? 'أدخل اسم الصنف' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(
                        labelText: 'السعر', border: OutlineInputBorder()),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) =>
                    v == null || v.isEmpty ? 'أدخل السعر' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: unitCtrl,
                    decoration: const InputDecoration(
                        labelText: 'الوحدة', border: OutlineInputBorder()),
                    validator: (v) =>
                    v == null || v.isEmpty ? 'أدخل الوحدة' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                        labelText: 'الوصف', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),

                  // ✅ عرض الصورة بشكل صحيح في الويب والموبايل
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Builder(
                        builder: (context) {
                          Widget imageWidget;

                          if (kIsWeb && _webImageBytes != null) {
                            imageWidget = Image.memory(
                              _webImageBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            );
                          } else if (!kIsWeb && _pickedImage != null) {
                            imageWidget = Image.file(
                              _pickedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            );
                          } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
                            imageWidget = Image.network(
                              _imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            );
                          } else {
                            return const Center(child: Text('لا توجد صورة'));
                          }

                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  backgroundColor: Colors.black,
                                  insetPadding: const EdgeInsets.all(10),
                                  child: InteractiveViewer(child: imageWidget),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: imageWidget,
                            ),
                          );
                        },
                      ),
                    ),

                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _removeBackground,
                    onChanged: (v) {
                      setState(() => _removeBackground = v);
                    },
                    title: const Text(
                      'إزالة خلفية الصورة',
                      style: TextStyle(fontFamily: 'NotoSansArabic'),
                    ),
                    subtitle: const Text(
                      'سيتم تطبيقها عند الحفظ',
                      style: TextStyle(fontFamily: 'NotoSansArabic'),
                    ),
                  ),




                  const SizedBox(height: 20),

                  // 🔹 زر تكوين الوحدات المستقل
                  ElevatedButton.icon(
                    icon: const Icon(Icons.widgets),
                    label: const Text('تكوين الوحدات التلقائي',
                        style: TextStyle(fontFamily: 'NotoSansArabic')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _generateUnits,
                  ),



                  const SizedBox(height: 12),

                  // 🔸 زر الحفظ
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('حفظ',
                        style: TextStyle(fontFamily: 'NotoSansArabic')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            ),
        );
    }
}