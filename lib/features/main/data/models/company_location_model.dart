import 'package:alma_desktop/features/main/domain/entities/company_location.dart';

class CompanyWorkingHourModel extends CompanyWorkingHour {
  const CompanyWorkingHourModel({
    required super.day,
    required super.from,
    required super.to,
    required super.isClosed,
  }) : super();

  factory CompanyWorkingHourModel.fromJson(Map<String, dynamic> json) {
    return CompanyWorkingHourModel(
      day: (json['day'] as String?) ?? '',
      from: json['from'] as String?,
      to: json['to'] as String?,
      isClosed: json['is_closed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'from': from,
        'to': to,
        'is_closed': isClosed,
      };
}

class CompanyLocationModel extends CompanyLocation {
  const CompanyLocationModel({
    required super.id,
    required super.name,
    super.description,
    super.address,
    super.latitude,
    super.longitude,
    super.managerId,
    super.managerName,
    required super.isActive,
    required super.isOpenNow,
    required super.workingHours,
    super.createdAt,
    super.updatedAt,
  }) : super();

  factory CompanyLocationModel.fromJson(Map<String, dynamic> json) {
    return CompanyLocationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      address: json['address'] as String?,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      managerId: (json['manager_id'] as num?)?.toInt(),
      managerName: json['manager_name'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      isOpenNow: json['is_open_now'] as bool? ?? false,
      workingHours: _parseWorkingHours(json['working_hours']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'manager_id': managerId,
        'manager_name': managerName,
        'is_active': isActive,
        'is_open_now': isOpenNow,
        'working_hours': workingHours
            .map(
              (h) => h is CompanyWorkingHourModel ? h.toJson() : null,
            )
            .whereType<Map<String, dynamic>>()
            .toList(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static List<CompanyWorkingHour> _parseWorkingHours(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map(
            (m) => CompanyWorkingHourModel.fromJson(
              Map<String, dynamic>.from(m),
            ),
          )
          .toList();
    }

    if (raw is Map) {
      return raw.entries.map((entry) {
        final day = entry.key.toString();
        final value = entry.value;

        if (value is String) {
          final normalized = value.trim();
          if (normalized.isEmpty || normalized.toLowerCase() == 'closed') {
            return CompanyWorkingHourModel(
              day: day,
              from: null,
              to: null,
              isClosed: true,
            );
          }

          final parts = normalized
              .split('-')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

          return CompanyWorkingHourModel(
            day: day,
            from: parts.isNotEmpty ? parts.first : null,
            to: parts.length > 1 ? parts[1] : null,
            isClosed: false,
          );
        }

        if (value is Map) {
          final map = Map<String, dynamic>.from(value);
          return CompanyWorkingHourModel.fromJson({
            'day': day,
            'from': map['from'],
            'to': map['to'],
            'is_closed': map['is_closed'] ?? false,
          });
        }

        return CompanyWorkingHourModel(
          day: day,
          from: null,
          to: null,
          isClosed: false,
        );
      }).toList();
    }

    return const <CompanyWorkingHour>[];
  }
}

