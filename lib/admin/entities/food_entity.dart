class FoodEntity {
  final String id;
  final String name;
  final double price;
  final String? description;
  final String status; // AVAILABLE | UNAVAILABLE (hoặc khác tuỳ BE)
  final String type; // PIZZA | APPETIZER | SALAD | DRINK | ...
  final String? imageUrl; // có thể là path tương đối

  const FoodEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.status,
    required this.type,
    this.description,
    this.imageUrl,
  });

  factory FoodEntity.fromJson(Map<String, dynamic> json) {
    return FoodEntity(
      id: (json['id'] ?? json['_id']).toString(),
      name: (json['name'] ?? '').toString(),
      price: double.tryParse((json['price'] ?? '0').toString()) ?? 0,
      description: json['description']?.toString(),
      status: (json['status'] ?? 'AVAILABLE').toString(),
      type: (json['type'] ?? 'OTHER').toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'description': description,
    'status': status,
    'type': type,
    'imageUrl': imageUrl,
  };
}
