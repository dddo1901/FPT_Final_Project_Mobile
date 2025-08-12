import 'package:fpt_final_project_mobile/admin/entities/table_entity.dart';

class TableModel {
  final String id;
  final int number;
  final int capacity;
  final String? location;
  final String status; // API dùng string

  const TableModel({
    required this.id,
    required this.number,
    required this.capacity,
    this.location,
    required this.status,
  });

  factory TableModel.fromJson(Map<String, dynamic> j) {
    return TableModel(
      id: (j['id'] ?? '').toString(),
      number: j['number'] is String
          ? int.tryParse(j['number']) ?? 0
          : (j['number'] ?? 0) as int,
      capacity: j['capacity'] is String
          ? int.tryParse(j['capacity']) ?? 0
          : (j['capacity'] ?? 0) as int,
      location: j['location']?.toString(),
      status: (j['status'] ?? 'AVAILABLE').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'capacity': capacity,
    'location': location,
    'status': status,
  };

  TableEntity toEntity() => TableEntity(
    id: id,
    number: number,
    capacity: capacity,
    location: location,
    status: TableStatusApi.parse(status),
  );

  static TableModel fromEntity(TableEntity e) => TableModel(
    id: e.id,
    number: e.number,
    capacity: e.capacity,
    location: e.location,
    status: e.status.toApi(),
  );
}
