class PaymentModel {
  final String paymentId;
  final String assignmentId;
  final String studentId;
  final double amount;
  final String currency;
  final String status;
  final String paymentMethod;
  final String transactionId;
  final String paymentDate;
  final String assignmentTitle;
  final String assignmentSubject;
  final String? studentName;

  PaymentModel({
    required this.paymentId,
    required this.assignmentId,
    required this.studentId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.transactionId,
    required this.paymentDate,
    required this.assignmentTitle,
    required this.assignmentSubject,
    this.studentName,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      paymentId: json['payment_id']?.toString() ?? '',
      assignmentId: json['assignment_id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      currency: json['currency']?.toString() ?? 'USD',
      status: json['status']?.toString() ?? 'Pending',
      paymentMethod: json['payment_method']?.toString() ?? 'Credit Card',
      transactionId: json['transaction_id']?.toString() ?? '',
      paymentDate: json['payment_date']?.toString() ?? '',
      assignmentTitle: json['assignment_title']?.toString() ?? 'Assignment Order',
      assignmentSubject: json['assignment_subject']?.toString() ?? 'General',
      studentName: json['student_name']?.toString(),
    );
  }
}

class ExpertModel {
  final String expertId;
  final String name;
  final String email;
  final String phone;
  final String subjects;
  final double rating;
  final int completedCount;
  final String status;
  final int activeTasks;

  ExpertModel({
    required this.expertId,
    required this.name,
    required this.email,
    required this.phone,
    required this.subjects,
    required this.rating,
    required this.completedCount,
    required this.status,
    required this.activeTasks,
  });

  factory ExpertModel.fromJson(Map<String, dynamic> json) {
    return ExpertModel(
      expertId: json['expert_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      subjects: json['subjects']?.toString() ?? '[]',
      rating: double.tryParse(json['rating']?.toString() ?? '5.0') ?? 5.0,
      completedCount: int.tryParse(json['completed_count']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'Available',
      activeTasks: int.tryParse(json['active_tasks']?.toString() ?? '0') ?? 0,
    );
  }
}

class StudentDirectoryModel {
  final String studentId;
  final String name;
  final String email;
  final String phone;
  final String country;
  final String university;
  final String course;
  final String status;
  final int totalOrders;
  final double totalSpent;

  StudentDirectoryModel({
    required this.studentId,
    required this.name,
    required this.email,
    required this.phone,
    required this.country,
    required this.university,
    this.course = '',
    required this.status,
    required this.totalOrders,
    required this.totalSpent,
  });

  factory StudentDirectoryModel.fromJson(Map<String, dynamic> json) {
    return StudentDirectoryModel(
      studentId: json['student_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      university: json['university']?.toString() ?? '',
      course: json['course']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Active',
      totalOrders: int.tryParse(json['total_orders']?.toString() ?? '0') ?? 0,
      totalSpent: double.tryParse(json['total_spent']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class SupportTicketModel {
  final String ticketId;
  final String studentId;
  final String assignmentId;
  final String subject;
  final String message;
  final String priority;
  final String status;
  final String createdAt;

  SupportTicketModel({
    required this.ticketId,
    required this.studentId,
    required this.assignmentId,
    required this.subject,
    required this.message,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      ticketId: json['ticket_id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      assignmentId: json['assignment_id']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'Medium',
      status: json['status']?.toString() ?? 'Open',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class CouponModel {
  final String couponId;
  final String code;
  final int discountPercent;
  final int maxUses;
  final int currentUses;
  final String expiresAt;
  final String status;

  CouponModel({
    required this.couponId,
    required this.code,
    required this.discountPercent,
    required this.maxUses,
    required this.currentUses,
    required this.expiresAt,
    required this.status,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      couponId: json['coupon_id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      discountPercent: int.tryParse(json['discount_percent']?.toString() ?? '10') ?? 10,
      maxUses: int.tryParse(json['max_uses']?.toString() ?? '100') ?? 100,
      currentUses: int.tryParse(json['current_uses']?.toString() ?? '0') ?? 0,
      expiresAt: json['expires_at']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Active',
    );
  }
}

class CourseModel {
  final String courseId;
  final String title;
  final String category;
  final String status;
  final String icon;
  final String description;
  final String topics;

  CourseModel({
    required this.courseId,
    required this.title,
    required this.category,
    required this.status,
    this.icon = 'fa-book-open',
    this.description = '',
    this.topics = '',
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      courseId: json['course_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      status: json['status']?.toString() ?? 'Active',
      icon: json['icon']?.toString() ?? 'fa-book-open',
      description: json['description']?.toString() ?? '',
      topics: json['topics']?.toString() ?? '',
    );
  }
}

class ChatMessageModel {
  final String msgId;
  final String assignmentId;
  final String studentId;
  final String senderId;
  final String senderRole;
  final String senderName;
  final String message;
  final bool isRead;
  final String timestamp;

  ChatMessageModel({
    required this.msgId,
    required this.assignmentId,
    required this.studentId,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.message,
    required this.isRead,
    required this.timestamp,
  });

  String get createdAt => timestamp;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      msgId: json['msg_id']?.toString() ?? '',
      assignmentId: json['assignment_id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderRole: json['sender_role']?.toString() ?? 'Student',
      senderName: json['sender_name']?.toString() ?? 'User',
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] == 1 || json['is_read'] == true || json['is_read'] == '1',
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }
}

class AuditLogModel {
  final int id;
  final String logId;
  final String userRole;
  final String userId;
  final String action;
  final String details;
  final String timestamp;

  AuditLogModel({
    required this.id,
    required this.logId,
    required this.userRole,
    required this.userId,
    required this.action,
    required this.details,
    required this.timestamp,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      logId: json['log_id']?.toString() ?? '',
      userRole: json['user_role']?.toString() ?? 'System',
      userId: json['user_id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }
}

class BlogModel {
  final int id;
  final String title;
  final String excerpt;
  final String category;
  final String author;
  final String publishedAt;
  final String image;
  final String content;

  BlogModel({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.category,
    required this.author,
    required this.publishedAt,
    required this.image,
    this.content = '',
  });

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    return BlogModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      excerpt: json['excerpt']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Academic Writing',
      author: json['author']?.toString() ?? 'Editorial Team',
      publishedAt: json['published_at']?.toString() ?? '',
      image: json['image']?.toString() ?? 'assets/images/blog1.jpg',
      content: json['content']?.toString() ?? '',
    );
  }
}

class AdminStaffModel {
  final int id;
  final String adminId;
  final String name;
  final String email;
  final String phone;
  final String status;

  AdminStaffModel({
    required this.id,
    required this.adminId,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
  });

  factory AdminStaffModel.fromJson(Map<String, dynamic> json) {
    return AdminStaffModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      adminId: json['admin_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Active',
    );
  }
}

class AllocatorStaffModel {
  final int id;
  final String allocatorId;
  final String name;
  final String email;
  final String phone;
  final String status;
  final double performanceScore;

  AllocatorStaffModel({
    required this.id,
    required this.allocatorId,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.performanceScore,
  });

  factory AllocatorStaffModel.fromJson(Map<String, dynamic> json) {
    return AllocatorStaffModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      allocatorId: json['allocator_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Active',
      performanceScore: double.tryParse(json['performance_score']?.toString() ?? '100.0') ?? 100.0,
    );
  }
}

class AssignmentFileModel {
  final int id;
  final String fileId;
  final String assignmentId;
  final String fileName;
  final String path;
  final String fileType;
  final String fileStage;
  final String uploadedBy;
  final String uploadDate;
  final bool isInternal;

  AssignmentFileModel({
    required this.id,
    required this.fileId,
    required this.assignmentId,
    required this.fileName,
    required this.path,
    required this.fileType,
    required this.fileStage,
    required this.uploadedBy,
    required this.uploadDate,
    required this.isInternal,
  });

  factory AssignmentFileModel.fromJson(Map<String, dynamic> json) {
    return AssignmentFileModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      fileId: json['file_id']?.toString() ?? '',
      assignmentId: json['assignment_id']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      fileType: json['file_type']?.toString() ?? '',
      fileStage: json['file_stage']?.toString() ?? 'draft',
      uploadedBy: json['uploaded_by']?.toString() ?? 'Student',
      uploadDate: json['upload_date']?.toString() ?? '',
      isInternal: json['is_internal'] == 1 || json['is_internal'] == '1' || json['is_internal'] == true,
    );
  }
}

