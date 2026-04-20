// lib/models/assignment_stats_model.dart
class AssignmentStats {
  final int totalAssignments;
  final int pendingAssignments;
  final int completedToday;
  final int completedThisWeek;
  final int completedThisMonth;
  final double averageCompletionTime;

  AssignmentStats({
    required this.totalAssignments,
    required this.pendingAssignments,
    required this.completedToday,
    required this.completedThisWeek,
    required this.completedThisMonth,
    required this.averageCompletionTime,
  });

  factory AssignmentStats.fromJson(Map<String, dynamic> json) {
    return AssignmentStats(
      totalAssignments: json['totalAssignments'] ??
          json['total_assignments'] ?? 0,
      pendingAssignments: json['pendingAssignments'] ??
          json['pending_assignments'] ?? 0,
      completedToday: json['completedToday'] ??
          json['completed_today'] ?? 0,
      completedThisWeek: json['completedThisWeek'] ??
          json['completed_this_week'] ?? 0,
      completedThisMonth: json['completedThisMonth'] ??
          json['completed_this_month'] ?? 0,
      averageCompletionTime: (json['averageCompletionTime'] ??
          json['average_completion_time'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAssignments': totalAssignments,
      'pendingAssignments': pendingAssignments,
      'completedToday': completedToday,
      'completedThisWeek': completedThisWeek,
      'completedThisMonth': completedThisMonth,
      'averageCompletionTime': averageCompletionTime,
    };
  }
} 