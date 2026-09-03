class Renewal {
  const Renewal({
    required this.id,
    required this.permitId,
    required this.newEffectiveDate,
    required this.newValidityMonths,
    required this.newExpiryDate,
    required this.renewalFee,
    required this.processingFee,
    required this.totalCost,
    required this.renewedAt,
    this.previousExpiryDate,
    this.renewedBy,
    this.organizationId,
  });

  final String id;
  final String permitId;
  final DateTime? previousExpiryDate;
  final DateTime newEffectiveDate;
  final int newValidityMonths;
  final DateTime newExpiryDate;
  final num renewalFee;
  final num processingFee;
  final num totalCost;
  final String? renewedBy;
  final DateTime renewedAt;
  final String? organizationId;

  factory Renewal.fromJson(Map<String, dynamic> json) => Renewal(
        id: json['id'] as String,
        permitId: json['permit_id'] as String,
        previousExpiryDate: _date(json['previous_expiry_date']),
        newEffectiveDate: DateTime.parse(json['new_effective_date'] as String),
        newValidityMonths: (json['new_validity_months'] as num).toInt(),
        newExpiryDate: DateTime.parse(json['new_expiry_date'] as String),
        renewalFee: (json['renewal_fee'] as num?) ?? 0,
        processingFee: (json['processing_fee'] as num?) ?? 0,
        totalCost: (json['total_cost'] as num?) ?? 0,
        renewedBy: json['renewed_by'] as String?,
        renewedAt: DateTime.parse(json['renewed_at'] as String),
        organizationId: json['organization_id'] as String?,
      );

  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.parse(value as String);
}
