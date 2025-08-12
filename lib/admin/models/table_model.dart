import '../entities/table_entity.dart';

class TableModel {
  final String id;
  final int? number; // ✅ số bàn (web)
  final int? capacity;
  final String status; // luôn upper-case
  final String? location;
  final String? description;

  /// Dùng để render ảnh QR (http/https | data-url | base64 trần | null)
  final String? qrUrl;

  /// Text đã format sẵn cho UI list
  String get title => 'Table #${number ?? id}';
  String get capacityText => 'Capacity: ${capacity ?? "—"}';

  const TableModel({
    required this.id,
    required this.number,
    required this.capacity,
    required this.status,
    this.location,
    this.description,
    this.qrUrl,
  });

  /// Map từ Entity (backend) sang View Model (UI)
  factory TableModel.fromEntity(TableEntity e, {String? qrFromApi}) {
    return TableModel(
      id: e.id,
      number: e.number, // fallback nhẹ nếu BE cũ
      capacity: e.capacity,
      status: (e.status ?? 'UNKNOWN').toUpperCase(),
      location: e.location,
      description: e.description,
      qrUrl: qrFromApi ?? e.qrCode,
    );
  }

  TableModel copyWith({
    String? id,
    int? number,
    int? capacity,
    String? status,
    String? location,
    String? description,
    String? qrUrl,
  }) {
    return TableModel(
      id: id ?? this.id,
      number: number ?? this.number,
      capacity: capacity ?? this.capacity,
      status: (status ?? this.status).toUpperCase(),
      location: location ?? this.location,
      description: description ?? this.description,
      qrUrl: qrUrl ?? this.qrUrl,
    );
  }
}
