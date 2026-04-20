// lib/models/settings_model.dart
class SystemSettings {
  final bool notificationsEnabled;
  final bool autoAssignmentEnabled;
  final bool maintenanceMode;
  final int escalationHours;
  final String defaultPriority;
  final Map<String, dynamic>? additionalSettings;

  SystemSettings({
    required this.notificationsEnabled,
    required this.autoAssignmentEnabled,
    required this.maintenanceMode,
    required this.escalationHours,
    required this.defaultPriority,
    this.additionalSettings,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      notificationsEnabled: json['notificationsEnabled'] ??
          json['notifications_enabled'] ?? true,
      autoAssignmentEnabled: json['autoAssignmentEnabled'] ??
          json['auto_assignment_enabled'] ?? false,
      maintenanceMode: json['maintenanceMode'] ??
          json['maintenance_mode'] ?? false,
      escalationHours: json['escalationHours'] ??
          json['escalation_hours'] ?? 48,
      defaultPriority: json['defaultPriority'] ??
          json['default_priority'] ?? 'Medium',
      additionalSettings: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'autoAssignmentEnabled': autoAssignmentEnabled,
      'maintenanceMode': maintenanceMode,
      'escalationHours': escalationHours,
      'defaultPriority': defaultPriority,
    };
  }
}