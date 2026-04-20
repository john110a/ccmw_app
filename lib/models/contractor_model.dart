// lib/models/contractor_model.dart
import 'package:flutter/material.dart';

class Contractor {
  final String contractorId;
  final String companyName;
  final String? contactEmail;  // This is the actual field name
  final DateTime? contractStart;
  final DateTime? contractEnd;
  final double? slaComplianceRate;
  final double? performanceScore;
  final bool? isActive;
  final String? companyRegistrationNumber;
  final String? contactPersonName;
  final String? contactPersonPhone;
  final String? companyAddress;
  final double? contractValue;
  final double? performanceBond;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ✅ ADDED: Getter for contactPersonEmail (maps to contactEmail)
  String? get contactPersonEmail => contactEmail;

  Contractor({
    required this.contractorId,
    required this.companyName,
    this.contactEmail,
    this.contractStart,
    this.contractEnd,
    this.slaComplianceRate,
    this.performanceScore,
    this.isActive,
    this.companyRegistrationNumber,
    this.contactPersonName,
    this.contactPersonPhone,
    this.companyAddress,
    this.contractValue,
    this.performanceBond,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Contractor.fromJson(Map<String, dynamic> json) {
    return Contractor(
      contractorId: json['contractor_id']?.toString() ??
          json['contractorId']?.toString() ??
          json['ContractorId']?.toString() ?? '',

      companyName: json['company_name'] ??
          json['companyName'] ??
          json['CompanyName'] ?? '',

      contactEmail: json['contact_email'] ??
          json['contactEmail'] ??
          json['ContactEmail'] ??
          json['ContactPersonEmail'],

      contractStart: _parseDateFromAny(json,
          snakeCase: 'contract_start',
          camelCase: 'contractStart',
          pascalCase: 'ContractStart'),

      contractEnd: _parseDateFromAny(json,
          snakeCase: 'contract_end',
          camelCase: 'contractEnd',
          pascalCase: 'ContractEnd'),

      slaComplianceRate: _parseDoubleFromAny(json,
          snakeCase: 'sla_compliance_rate',
          camelCase: 'slaComplianceRate',
          pascalCase: 'SLAComplianceRate'),

      performanceScore: _parseDoubleFromAny(json,
          snakeCase: 'performance_score',
          camelCase: 'performanceScore',
          pascalCase: 'PerformanceScore'),

      isActive: json['is_active'] ??
          json['isActive'] ??
          json['IsActive'] ??
          true,

      companyRegistrationNumber: json['company_registration_number'] ??
          json['companyRegistrationNumber'] ??
          json['CompanyRegistrationNumber'],

      contactPersonName: json['contact_person_name'] ??
          json['contactPersonName'] ??
          json['ContactPersonName'],

      contactPersonPhone: json['contact_person_phone'] ??
          json['contactPersonPhone'] ??
          json['ContactPersonPhone'],

      companyAddress: json['company_address'] ??
          json['companyAddress'] ??
          json['CompanyAddress'],

      contractValue: _parseDoubleFromAny(json,
          snakeCase: 'contract_value',
          camelCase: 'contractValue',
          pascalCase: 'ContractValue'),

      performanceBond: _parseDoubleFromAny(json,
          snakeCase: 'performance_bond',
          camelCase: 'performanceBond',
          pascalCase: 'PerformanceBond'),

      createdAt: _parseDateFromAny(json,
          snakeCase: 'created_at',
          camelCase: 'createdAt',
          pascalCase: 'CreatedAt') ?? DateTime.now(),

      updatedAt: _parseDateFromAny(json,
          snakeCase: 'updated_at',
          camelCase: 'updatedAt',
          pascalCase: 'UpdatedAt') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contractor_id': contractorId,
      'company_name': companyName,
      'contact_email': contactEmail,
      'contract_start': contractStart?.toIso8601String(),
      'contract_end': contractEnd?.toIso8601String(),
      'sla_compliance_rate': slaComplianceRate,
      'performance_score': performanceScore,
      'is_active': isActive,
      'company_registration_number': companyRegistrationNumber,
      'contact_person_name': contactPersonName,
      'contact_person_phone': contactPersonPhone,
      'company_address': companyAddress,
      'contract_value': contractValue,
      'performance_bond': performanceBond,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ========== HELPER METHODS ==========

  static DateTime? _parseDateFromAny(Map<String, dynamic> json, {
    required String snakeCase,
    required String camelCase,
    required String pascalCase,
  }) {
    // Try all possible key formats
    final value = json[snakeCase] ?? json[camelCase] ?? json[pascalCase];

    if (value == null) return null;

    try {
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
    } catch (e) {
      print('Error parsing date for $snakeCase: $e');
    }
    return null;
  }

  static double? _parseDoubleFromAny(Map<String, dynamic> json, {
    required String snakeCase,
    required String camelCase,
    required String pascalCase,
  }) {
    // Try all possible key formats
    final value = json[snakeCase] ?? json[camelCase] ?? json[pascalCase];

    if (value == null) return null;

    try {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    } catch (e) {
      print('Error parsing double for $snakeCase: $e');
    }
    return null;
  }

  // Keep original methods for backward compatibility
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  // ========== UTILITY METHODS ==========

  /// Returns contract status as readable string
  String getContractStatus() {
    if (isActive == false) return 'Inactive';
    if (contractEnd == null) return 'Active';
    if (contractEnd!.isBefore(DateTime.now())) return 'Expired';
    return 'Active';
  }

  /// Returns color for contract status
  Color getStatusColor() {
    if (isActive == false) return Colors.grey;
    if (contractEnd == null) return Colors.green;
    if (contractEnd!.isBefore(DateTime.now())) return Colors.red;

    // Warning if contract ends within 30 days
    final daysUntilExpiry = contractEnd!.difference(DateTime.now()).inDays;
    if (daysUntilExpiry < 30) return Colors.orange;

    return Colors.green;
  }

  /// Returns performance rating as string
  String getPerformanceRating() {
    if (performanceScore == null) return 'Not Rated';
    if (performanceScore! >= 90) return 'Excellent';
    if (performanceScore! >= 80) return 'Good';
    if (performanceScore! >= 70) return 'Average';
    return 'Needs Improvement';
  }

  /// Returns color for performance
  Color getPerformanceColor() {
    if (performanceScore == null) return Colors.grey;
    if (performanceScore! >= 90) return Colors.green;
    if (performanceScore! >= 80) return Colors.lightGreen;
    if (performanceScore! >= 70) return Colors.orange;
    return Colors.red;
  }
}