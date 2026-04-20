class ContractorZone {
  final String assignmentId;
  final String contractorId;
  final String zoneId;
  final String zoneName;
  final int zoneNumber;
  final String? city;
  final String? province;
  final String serviceType;
  final DateTime contractStart;
  final DateTime contractEnd;
  final double contractValue;
  final double performanceBond;
  final DateTime assignedDate;
  final int activeComplaints;
  final bool isActive;

  ContractorZone({
    required this.assignmentId,
    required this.contractorId,
    required this.zoneId,
    required this.zoneName,
    required this.zoneNumber,
    this.city,
    this.province,
    required this.serviceType,
    required this.contractStart,
    required this.contractEnd,
    required this.contractValue,
    required this.performanceBond,
    required this.assignedDate,
    required this.activeComplaints,
    required this.isActive,
  });

  factory ContractorZone.fromJson(Map<String, dynamic> json) {
    return ContractorZone(
      assignmentId: json['assignmentId']?.toString() ?? '',
      contractorId: json['contractorId']?.toString() ?? '',
      zoneId: json['zone']?['zoneId']?.toString() ??
          json['zoneId']?.toString() ?? '',
      zoneName: json['zone']?['zoneName'] ??
          json['zoneName'] ?? '',
      zoneNumber: json['zone']?['zoneNumber'] ??
          json['zoneNumber'] ?? 0,
      city: json['zone']?['city'] ??
          json['city'],
      province: json['zone']?['province'] ??
          json['province'],
      serviceType: json['serviceType'] ?? '',
      contractStart: DateTime.parse(json['contractStart'] ??
          json['contract_start'] ??
          DateTime.now().toIso8601String()),
      contractEnd: DateTime.parse(json['contractEnd'] ??
          json['contract_end'] ??
          DateTime.now().toIso8601String()),
      contractValue: (json['contractValue'] ?? json['contract_value'] ?? 0).toDouble(),
      performanceBond: (json['performanceBond'] ?? json['performance_bond'] ?? 0).toDouble(),
      assignedDate: DateTime.parse(json['assignedDate'] ??
          json['assigned_date'] ??
          DateTime.now().toIso8601String()),
      activeComplaints: json['activeComplaints'] ?? 0,
      isActive: json['isActive'] ?? json['is_active'] ?? false,
    );
  }
}