class TableEntity {
  final String id;
  final int? number; // ✅ số bàn: trùng với web
  final int? capacity;
  final String?
  status; // AVAILABLE / OCCUPIED / RESERVED / CLEANING / INACTIVE...
  final String? location;
  final String? description;

  // tuỳ backend có trả sẵn không; còn QR chi tiết lấy API riêng
  final String? qrCode;

  const TableEntity({
    required this.id,
    this.number,
    this.capacity,
    this.status,
    this.location,
    this.description,
    this.qrCode,
  });

  factory TableEntity.fromJson(Map<String, dynamic> json) {
    return TableEntity(
      id: (json['id'] ?? json['_id']).toString(),
      number:
          json['number'] ?? json['tableNumber'], // 👈 map fallback nếu BE cũ
      capacity: json['capacity'],
      status: json['status'],
      location: json['location'],
      description: json['description'],
      qrCode: json['qrCode'], // nếu BE có nhét cùng detail luôn
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'capacity': capacity,
    'status': status,
    'location': location,
    'description': description,
    'qrCode': qrCode,
  };

  TableEntity copyWith({
    String? id,
    int? number,
    int? capacity,
    String? status,
    String? location,
    String? description,
    String? qrCode,
  }) {
    return TableEntity(
      id: id ?? this.id,
      number: number ?? this.number,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      location: location ?? this.location,
      description: description ?? this.description,
      qrCode: qrCode ?? this.qrCode,
    );
  }
}
