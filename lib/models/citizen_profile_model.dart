class CitizenProfile {
  final String citizenId;
  final String userId;
  final int totalComplaintsFiled;
  final int approvedComplaintsCount;
  final int resolvedComplaintsCount;    // ADD THIS
  final int rejectedComplaintsCount;    // ADD THIS
  final int contributionScore;
  final int leaderboardRank;
  final String? badgeLevel;
  final int totalUpvotesReceived;
  final DateTime createdAt;              // ADD THIS
  final DateTime updatedAt;              // ADD THIS

  CitizenProfile({
    required this.citizenId,
    required this.userId,
    required this.totalComplaintsFiled,
    required this.approvedComplaintsCount,
    required this.resolvedComplaintsCount,    // ADD
    required this.rejectedComplaintsCount,    // ADD
    required this.contributionScore,
    required this.leaderboardRank,
    this.badgeLevel,
    required this.totalUpvotesReceived,
    required this.createdAt,                   // ADD
    required this.updatedAt,                   // ADD
  });

  factory CitizenProfile.fromJson(Map<String, dynamic> json) {
    return CitizenProfile(
      citizenId: json['citizen_id']?.toString() ?? json['citizenId']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      totalComplaintsFiled: json['total_complaints'] ?? json['totalComplaintsFiled'] ?? 0,
      approvedComplaintsCount: json['approved_complaints'] ?? json['approvedComplaintsCount'] ?? 0,
      resolvedComplaintsCount: json['resolved_complaints'] ?? json['ResolvedComplaintsCount'] ?? 0,
      rejectedComplaintsCount: json['rejected_complaints'] ?? json['RejectedComplaintsCount'] ?? 0,
      contributionScore: json['contribution_score'] ?? json['contributionScore'] ?? 0,
      leaderboardRank: json['leaderboard_rank'] ?? json['leaderboardRank'] ?? 0,
      badgeLevel: json['badge_level'] ?? json['badgeLevel'],
      totalUpvotesReceived: json['total_upvotes'] ?? json['totalUpvotesReceived'] ?? 0,
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}