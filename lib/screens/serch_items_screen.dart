import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchItemsScreen extends StatefulWidget {
  const SearchItemsScreen({super.key});

  @override
  State<SearchItemsScreen> createState() => _SearchItemsScreenState();
}

class _SearchItemsScreenState extends State<SearchItemsScreen> {
  final _controller = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('بحث عن صنف')),
        body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'اكتب اسم أو رقم الصنف...',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => setState(() => _query = _controller.text.trim()),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('items').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final allItems = snapshot.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();

                    final results = allItems.where((e) {
                      final id = e['item_id']?.toString() ?? '';
                      final name = (e['name'] ?? '').toString().toLowerCase();
                      return id.contains(_query) || name.contains(_query.toLowerCase());
                    }).toList();

                    return ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final item = results[i];
                        return ListTile(
                          leading: item['image'] != null && item['image'] != ''
                              ? Image.network(item['image'], width: 60, height: 60, fit: BoxFit.cover)
                              : const Icon(Icons.image_not_supported),
                          title: Text(item['name'] ?? ''),
                          subtitle: Text('رقم: ${item['item_id']}  |  السعر: ${item['price']} ر.س'),
                          onTap: () => Navigator.pop(context, item),
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