enum TableStatus { available, occupied, reserved, cleaning }

extension TableStatusApi on TableStatus {
  String toApi() {
    switch (this) {
      case TableStatus.available:
        return 'AVAILABLE';
      case TableStatus.occupied:
        return 'OCCUPIED';
      case TableStatus.reserved:
        return 'RESERVED';
      case TableStatus.cleaning:
        return 'CLEANING';
    }
  }

  static TableStatus parse(String raw) {
    switch (raw.toUpperCase()) {
      case 'AVAILABLE':
        return TableStatus.available;
      case 'OCCUPIED':
        return TableStatus.occupied;
      case 'RESERVED':
        return TableStatus.reserved;
      case 'CLEANING':
        return TableStatus.cleaning;
      default:
        return TableStatus.available;
    }
  }

  String get label => toApi();
}

class TableEntity {
  final String id;
  final int number;
  final int capacity;
  final String? location;
  final TableStatus status;

  const TableEntity({
    required this.id,
    required this.number,
    required this.capacity,
    this.location,
    required this.status,
  });

  TableEntity copyWith({
    String? id,
    int? number,
    int? capacity,
    String? location,
    TableStatus? status,
  }) {
    return TableEntity(
      id: id ?? this.id,
      number: number ?? this.number,
      capacity: capacity ?? this.capacity,
      location: location ?? this.location,
      status: status ?? this.status,
    );
  }
}
