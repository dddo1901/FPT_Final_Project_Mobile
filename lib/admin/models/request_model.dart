enum RequestType {
  leave('LEAVE', 'Leave'),
  swap('SWAP', 'Shift Swap'),
  overtime('OVERTIME', 'Overtime');

  const RequestType(this.value, this.label);

  final String value;
  final String label;

  static RequestType fromValue(String value) {
    return RequestType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => RequestType.leave,
    );
  }
}

enum RequestStatus {
  pending('PENDING', 'Pending'),
  approved('APPROVED', 'Approved'),
  denied('DENIED', 'Denied');

  const RequestStatus(this.value, this.label);

  final String value;
  final String label;

  static RequestStatus fromValue(String value) {
    return RequestStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RequestStatus.pending,
    );
  }
}

class StaffRequest {
  final String id;
  final String staffCode;
  final String staffName;
  final RequestType type;
  final String reason;
  final DateTime requestDate;
  final DateTime targetDate;
  final RequestStatus status;
  final String? adminNote;
  final String? additionalInfo;

  StaffRequest({
    required this.id,
    required this.staffCode,
    required this.staffName,
    required this.type,
    required this.reason,
    required this.requestDate,
    required this.targetDate,
    required this.status,
    this.adminNote,
    this.additionalInfo,
  });

  factory StaffRequest.fromJson(Map<String, dynamic> json) {
    return StaffRequest(
      id: json['id']?.toString() ?? '',
      staffCode: json['staffCode'] ?? '',
      staffName: json['staffName'] ?? '',
      type: RequestType.fromValue(json['type'] ?? 'LEAVE'),
      reason: json['reason'] ?? '',
      requestDate: _parseDate(json['requestDate']),
      targetDate: _parseDate(json['targetDate']),
      status: RequestStatus.fromValue(json['status'] ?? 'PENDING'),
      adminNote: json['adminNote'],
      additionalInfo: json['additionalInfo'],
    );
  }

  // Helper method to parse date from various formats
  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();

    if (dateValue is String) {
      // Handle LocalDate format (YYYY-MM-DD) or ISO DateTime
      if (dateValue.length == 10) {
        // LocalDate format: "2023-12-25"
        return DateTime.parse('${dateValue}T00:00:00');
      } else {
        // ISO DateTime format
        return DateTime.parse(dateValue);
      }
    }

    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staffCode': staffCode,
      'staffName': staffName,
      'type': type.value,
      'reason': reason,
      'requestDate': requestDate.toIso8601String(),
      'targetDate': targetDate.toIso8601String(),
      'status': status.value,
      'adminNote': adminNote,
      'additionalInfo': additionalInfo,
    };
  }

  String get formattedRequestDate {
    return '${requestDate.day}/${requestDate.month}/${requestDate.year}';
  }

  String get formattedTargetDate {
    return '${targetDate.day}/${targetDate.month}/${targetDate.year}';
  }

  bool get isPending => status == RequestStatus.pending;
  bool get isApproved => status == RequestStatus.approved;
  bool get isDenied => status == RequestStatus.denied;
}

class CreateRequestModel {
  final RequestType type;
  final String reason;
  final DateTime targetDate;
  final String? additionalInfo;

  CreateRequestModel({
    required this.type,
    required this.reason,
    required this.targetDate,
    this.additionalInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'reason': reason,
      'targetDate': targetDate.toIso8601String(),
      'requestDate': DateTime.now().toIso8601String(),
      if (additionalInfo != null && additionalInfo!.isNotEmpty)
        'additionalInfo': additionalInfo,
    };
  }
}
