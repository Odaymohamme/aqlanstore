// lib/models/product.dart
class AdminProduct {
  final String itemId;
  final String name;
  final String image; // رابط الصورة (Firebase Storage URL أو رابط مباشر)
  final String description;
  final String categoryId;
  final String price; // نحتفظ كنص لأن بياناتك القديمة نصية؛ عند الحاجة نحول إلى double

  AdminProduct({
    required this.itemId,
    required this.name,
    required this.image,
    required this.description,
    required this.categoryId,
    required this.price,
  });

  factory AdminProduct.fromJson(Map<String, dynamic> json) {
    return AdminProduct(
      itemId: (json['item_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      categoryId: (json['category_id'] ?? '').toString(),
      price: (json['price'] ?? '0').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
    'item_id': itemId,
    'name': name,
    'image': image,
    'description': description,
    'category_id': categoryId,
    'price': price,
    };
    }
}