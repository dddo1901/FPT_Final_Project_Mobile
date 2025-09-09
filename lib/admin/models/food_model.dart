import '../entities/food_entity.dart';

class FoodModel {
  final String id;
  final String name;
  final double price;
  final String status;
  final String type;
  final String? description;
  final String? imageUrl;

  const FoodModel({
    required this.id,
    required this.name,
    required this.price,
    required this.status,
    required this.type,
    this.description,
    this.imageUrl,
  });

  String get priceText => '\$${price.toStringAsFixed(2)}';
  bool get isAvailable => status == 'AVAILABLE';

  factory FoodModel.fromEntity(FoodEntity e, {required String baseUrl}) {
    String? normalize(String? raw) {
      if (raw == null || raw.isEmpty || raw == 'null' || raw == 'undefined') {
        return null;
      }
      if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
      final b = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
      final p = raw.startsWith('/') ? raw : '/$raw';
      return '$b$p';
    }

    return FoodModel(
      id: e.id,
      name: e.name,
      price: e.price,
      status: e.status.toUpperCase(),
      type: e.type.toUpperCase(),
      description: e.description,
      imageUrl: normalize(e.imageUrl),
    );
  }
}
