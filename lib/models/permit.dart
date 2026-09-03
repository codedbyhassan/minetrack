class Permit {
  const Permit({
    required this.id,
    required this.fileNumber,
    required this.proponentName,
    required this.region,
    required this.sectorId,
    required this.undertakingTypeId,
    required this.permitFee,
    required this.processingFee,
    required this.totalCost,
    required this.revoked,
    required this.createdAt,
    required this.updatedAt,
    this.contactPerson,
    this.contactPhone,
    this.district,
    this.townSite,
    this.capacity,
    this.capacityUnit,
    this.effectiveDate,
    this.validityMonths,
    this.expiryDate,
    this.latitude,
    this.longitude,
    this.createdBy,
    this.organizationId,
    this.sector,
    this.undertakingType,
  });

  final String id;
  final String fileNumber;
  final String proponentName;
  final String? contactPerson;
  final String? contactPhone;
  final String region;
  final String? district;
  final String? townSite;
  final String sectorId;
  final String undertakingTypeId;
  final num? capacity;
  final String? capacityUnit;
  final DateTime? effectiveDate;
  final int? validityMonths;
  final DateTime? expiryDate;
  final num permitFee;
  final num processingFee;
  final num totalCost;
  final num? latitude;
  final num? longitude;
  final bool revoked;
  final String? createdBy;
  final String? organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Sector? sector;
  final UndertakingType? undertakingType;

  factory Permit.fromJson(Map<String, dynamic> json) {
    return Permit(
      id: json['id'] as String,
      fileNumber: json['file_number'] as String,
      proponentName: json['proponent_name'] as String,
      contactPerson: json['contact_person'] as String?,
      contactPhone: json['contact_phone'] as String?,
      region: json['region'] as String,
      district: json['district'] as String?,
      townSite: json['town_site'] as String?,
      sectorId: json['sector_id'] as String,
      undertakingTypeId: json['undertaking_type_id'] as String,
      capacity: json['capacity'] as num?,
      capacityUnit: json['capacity_unit'] as String?,
      effectiveDate: _date(json['effective_date']),
      validityMonths: (json['validity_months'] as num?)?.toInt(),
      expiryDate: _date(json['expiry_date']),
      permitFee: (json['permit_fee'] as num?) ?? 0,
      processingFee: (json['processing_fee'] as num?) ?? 0,
      totalCost: (json['total_cost'] as num?) ?? 0,
      latitude: json['latitude'] as num?,
      longitude: json['longitude'] as num?,
      revoked: json['revoked'] as bool? ?? false,
      createdBy: json['created_by'] as String?,
      organizationId: json['organization_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      sector: json['sector'] is Map<String, dynamic>
          ? Sector.fromJson(json['sector'] as Map<String, dynamic>)
          : null,
      undertakingType: json['undertaking_type'] is Map<String, dynamic>
          ? UndertakingType.fromJson(json['undertaking_type'] as Map<String, dynamic>)
          : null,
    );
  }

  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.parse(value as String);
}

class Sector {
  const Sector({
    required this.id,
    required this.name,
    required this.icon,
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String icon;
  final int sortOrder;
  final DateTime createdAt;

  factory Sector.fromJson(Map<String, dynamic> json) => Sector(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String? ?? '',
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class UndertakingType {
  const UndertakingType({
    required this.id,
    required this.sectorId,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String sectorId;
  final String name;
  final int sortOrder;
  final DateTime createdAt;

  factory UndertakingType.fromJson(Map<String, dynamic> json) => UndertakingType(
        id: json['id'] as String,
        sectorId: json['sector_id'] as String,
        name: json['name'] as String,
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
