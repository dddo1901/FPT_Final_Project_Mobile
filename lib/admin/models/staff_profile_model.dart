import 'package:fpt_final_project_mobile/admin/entities/staff_profile_entity.dart';

class StaffProfileModel extends StaffProfileEntity {
  StaffProfileModel({
    super.staffCode,
    super.status,
    super.position,
    super.shiftType,
    super.workLocation,
    super.address,
    super.gender,
    super.dob,
    super.joinDate,
  });

  factory StaffProfileModel.fromJson(Map<String, dynamic> json) {
    return StaffProfileModel(
      staffCode: json['staffCode'],
      status: json['status'],
      position: json['position'],
      shiftType: json['shiftType'],
      workLocation: json['workLocation'],
      address: json['address'],
      gender: json['gender'],
      dob: json['dob'],
      joinDate: json['joinDate'],
    );
  }

  // Add this new factory constructor
  factory StaffProfileModel.fromEntity(StaffProfileEntity entity) {
    return StaffProfileModel(
      staffCode: entity.staffCode,
      status: entity.status,
      position: entity.position,
      shiftType: entity.shiftType,
      workLocation: entity.workLocation,
      address: entity.address,
      gender: entity.gender,
      dob: entity.dob,
      joinDate: entity.joinDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staffCode': staffCode,
      'status': status,
      'position': position,
      'shiftType': shiftType,
      'workLocation': workLocation,
      'address': address,
      'gender': gender,
      'dob': dob,
      'joinDate': joinDate,
    };
  }
}
