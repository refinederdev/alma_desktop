import 'package:equatable/equatable.dart';

class CompanyWorkingHour extends Equatable {
  final String day;
  final String? from;
  final String? to;
  final bool isClosed;

  const CompanyWorkingHour({
    required this.day,
    required this.from,
    required this.to,
    required this.isClosed,
  });

  @override
  List<Object?> get props => [day, from, to, isClosed];
}

class CompanyLocation extends Equatable {
  final int id;
  final String name;
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int? managerId;
  final String? managerName;
  final bool isActive;
  final bool isOpenNow;
  final List<CompanyWorkingHour> workingHours;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CompanyLocation({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    this.managerId,
    this.managerName,
    required this.isActive,
    required this.isOpenNow,
    required this.workingHours,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        address,
        latitude,
        longitude,
        managerId,
        managerName,
        isActive,
        isOpenNow,
        workingHours,
        createdAt,
        updatedAt,
      ];
}

