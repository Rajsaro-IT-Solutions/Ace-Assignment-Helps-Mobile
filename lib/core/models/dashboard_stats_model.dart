class DashboardData {
  final String role;
  final Map<String, dynamic> stats;
  final List<dynamic> recentAssignments;

  DashboardData({
    required this.role,
    required this.stats,
    required this.recentAssignments,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      role: json['role']?.toString() ?? '',
      stats: json['stats'] is Map<String, dynamic> ? json['stats'] : {},
      recentAssignments: json['recent_assignments'] is List ? json['recent_assignments'] : [],
    );
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['notification_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] == 1 || json['is_read'] == true || json['is_read'] == '1',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
