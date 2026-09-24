class SlaInfo {
  final String level;
  final String label;
  final double hoursLeft;
  final String badgeClass;

  SlaInfo({
    required this.level,
    required this.label,
    required this.hoursLeft,
    required this.badgeClass,
  });

  factory SlaInfo.fromJson(Map<String, dynamic> json) {
    return SlaInfo(
      level: json['level']?.toString() ?? 'green',
      label: json['label']?.toString() ?? 'On Track',
      hoursLeft: (json['hours_left'] is num) ? (json['hours_left'] as num).toDouble() : 0.0,
      badgeClass: json['badge_class']?.toString() ?? 'sla-green',
    );
  }
}

class AssignmentModel {
  final String assignmentId;
  final String studentId;
  final String title;
  final String subject;
  final String assignmentType;
  final String deadline;
  final int wordCount;
  final String currency;
  final double price;
  final double finalPrice;
  final String status;
  final String allocatorId;
  final String expertId;
  final double paidAmount;
  final double remainingBalance;
  final String instructions;
  final String priority;
  final String country;
  final String paymentStatus;
  final SlaInfo? sla;

  AssignmentModel({
    required this.assignmentId,
    required this.studentId,
    required this.title,
    required this.subject,
    required this.assignmentType,
    required this.deadline,
    required this.wordCount,
    required this.currency,
    required this.price,
    required this.finalPrice,
    required this.status,
    this.allocatorId = '',
    this.expertId = '',
    this.paidAmount = 0.0,
    this.remainingBalance = 0.0,
    this.instructions = '',
    this.priority = 'Standard',
    this.country = 'United Kingdom',
    this.paymentStatus = 'Pending',
    this.sla,
  });

  String get deadlineFormatted => deadline.isNotEmpty ? deadline.split(' ').first : 'Flexible';

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      assignmentId: json['assignment_id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Assignment',
      subject: json['subject']?.toString() ?? 'General',
      assignmentType: json['assignment_type']?.toString() ?? 'Essay',
      deadline: json['deadline']?.toString() ?? '',
      wordCount: (json['word_count'] is num) ? (json['word_count'] as num).toInt() : int.tryParse(json['word_count']?.toString() ?? '0') ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      finalPrice: (json['final_price'] is num) ? (json['final_price'] as num).toDouble() : double.tryParse(json['final_price']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'Pending',
      allocatorId: json['allocator_id']?.toString() ?? '',
      expertId: json['expert_id']?.toString() ?? '',
      paidAmount: (json['paid_amount'] is num) ? (json['paid_amount'] as num).toDouble() : double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0.0,
      remainingBalance: (json['remaining_balance'] is num) ? (json['remaining_balance'] as num).toDouble() : double.tryParse(json['remaining_balance']?.toString() ?? '0') ?? 0.0,
      instructions: json['instructions']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'Standard',
      country: json['country']?.toString() ?? 'United Kingdom',
      paymentStatus: json['payment_status']?.toString() ?? 'Pending',
      sla: json['sla'] != null && json['sla'] is Map<String, dynamic>
          ? SlaInfo.fromJson(json['sla'])
          : null,
    );
  }
}
