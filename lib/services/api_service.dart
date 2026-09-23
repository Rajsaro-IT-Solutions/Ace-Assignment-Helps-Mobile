import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../core/models/assignment_model.dart';
import '../core/models/dashboard_stats_model.dart';
import '../core/models/portal_models.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
  });
}

class ApiService {
  static const Duration timeoutDuration = Duration(seconds: 15);

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'User-Agent': 'AAH-Mobile-App/1.0',
      };

  /// Test connectivity to the portal API and AWS RDS MySQL
  static Future<ApiResponse<Map<String, dynamic>>> checkHealth() async {
    try {
      final uri = Uri.parse('${ApiConfig.portalApiEndpoint}?action=health');
      final response = await http.get(uri, headers: _headers).timeout(timeoutDuration);
      final json = jsonDecode(response.body);

      return ApiResponse(
        success: json['success'] == true,
        message: json['message']?.toString() ?? '',
        data: json['data'] is Map<String, dynamic> ? json['data'] : null,
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (kDebugMode) print('checkHealth error: $e');
      return ApiResponse(
        success: false,
        message: 'Could not connect to server at ${ApiConfig.baseUrl}. Please check network connection.',
        statusCode: 0,
      );
    }
  }

  /// Unified Portal Login with automatic role detection (Student, Allocator, Expert, Admin)
  static Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
    String role = 'all',
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'login',
          'email': email.trim(),
          'password': password.trim(),
          'role': role,
        }),
      ).timeout(timeoutDuration);

      final json = jsonDecode(response.body);
      return ApiResponse(
        success: json['success'] == true,
        message: json['message']?.toString() ?? '',
        data: json['data'] is Map<String, dynamic> ? json['data'] : null,
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (kDebugMode) print('login error: $e');
      return ApiResponse(
        success: false,
        message: 'Connection error ($e). Tap the settings icon in the top right to verify server connection.',
        statusCode: 0,
      );
    }
  }

  /// Get role-specific Dashboard stats & recent assignments
  static Future<DashboardData?> getDashboard({
    required String role,
    required String userId,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.portalApiEndpoint}?action=dashboard&role=${Uri.encodeComponent(role)}&user_id=${Uri.encodeComponent(userId)}',
      );
      final response = await http.get(uri, headers: _headers).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return DashboardData.fromJson(json['data']);
        }
      }
    } catch (e) {
      if (kDebugMode) print('getDashboard error: $e');
    }
    return null;
  }

  /// Get assignments list with optional status filter
  static Future<List<AssignmentModel>> getAssignments({
    required String role,
    required String userId,
    String status = 'All',
    String search = '',
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.portalApiEndpoint}?action=assignments&role=${Uri.encodeComponent(role)}&user_id=${Uri.encodeComponent(userId)}&status=${Uri.encodeComponent(status)}&search=${Uri.encodeComponent(search)}',
      );
      final response = await http.get(uri, headers: _headers).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] is List) {
          return (json['data'] as List)
              .map((item) => AssignmentModel.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) print('getAssignments error: $e');
    }
    return [];
  }

  /// Get full assignment details, files, and notes
  static Future<Map<String, dynamic>?> getAssignmentDetail(String assignmentId) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.portalApiEndpoint}?action=assignment_detail&assignment_id=${Uri.encodeComponent(assignmentId)}',
      );
      final response = await http.get(uri, headers: _headers).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return json['data'];
        }
      }
    } catch (e) {
      if (kDebugMode) print('getAssignmentDetail error: $e');
    }
    return null;
  }

  /// Update assignment status
  static Future<bool> updateStatus({
    required String assignmentId,
    required String status,
    required String userId,
    required String role,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'update_status',
          'assignment_id': assignmentId,
          'status': status,
          'user_id': userId,
          'role': role,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      if (kDebugMode) print('updateStatus error: $e');
      return false;
    }
  }

  /// Get user notifications
  static Future<List<NotificationModel>> getNotifications({
    required String userId,
    required String role,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.portalApiEndpoint}?action=notifications&user_id=${Uri.encodeComponent(userId)}&role=${Uri.encodeComponent(role)}',
      );
      final response = await http.get(uri, headers: _headers).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] is List) {
          return (json['data'] as List)
              .map((item) => NotificationModel.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) print('getNotifications error: $e');
    }
    return [];
  }

  /// Submit new assignment order (Student Portal)
  static Future<ApiResponse<Map<String, dynamic>>> submitAssignment({
    required String studentId,
    required String title,
    required String subject,
    required String assignmentType,
    required String deadline,
    required int wordCount,
    required String referenceStyle,
    required String description,
    required String currency,
    required double price,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'submit_assignment',
          'student_id': studentId,
          'title': title,
          'subject': subject,
          'assignment_type': assignmentType,
          'deadline': deadline,
          'word_count': wordCount,
          'reference_style': referenceStyle,
          'description': description,
          'currency': currency,
          'price': price,
          'final_price': price,
        }),
      ).timeout(timeoutDuration);

      final json = jsonDecode(response.body);
      return ApiResponse(
        success: json['success'] == true,
        message: json['message']?.toString() ?? '',
        data: json['data'] is Map<String, dynamic> ? json['data'] : null,
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (kDebugMode) print('submitAssignment error: $e');
      return ApiResponse(success: false, message: 'Submission failed: $e', statusCode: 0);
    }
  }

  /// Allocate expert to an assignment (Allocator Portal)
  static Future<bool> allocateExpert({
    required String assignmentId,
    required String expertId,
    required String allocatorId,
    required String deadline,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'allocate_expert',
          'assignment_id': assignmentId,
          'expert_id': expertId,
          'allocator_id': allocatorId,
          'deadline': deadline,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      if (kDebugMode) print('allocateExpert error: $e');
      return false;
    }
  }

  /// Allocator QA review (Approve / Revision)
  static Future<bool> allocatorReview({
    required String assignmentId,
    required String decision,
    String notes = '',
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'allocator_review',
          'assignment_id': assignmentId,
          'decision': decision,
          'notes': notes,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      if (kDebugMode) print('allocatorReview error: $e');
      return false;
    }
  }

  /// Expert actions: Start task, submit solution for QA
  static Future<bool> expertAction({
    required String assignmentId,
    required String actionType,
    required String expertId,
    String notes = '',
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'expert_action',
          'assignment_id': assignmentId,
          'action_type': actionType,
          'expert_id': expertId,
          'notes': notes,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      if (kDebugMode) print('expertAction error: $e');
      return false;
    }
  }

  /// Get list of all experts (Allocator & Admin)
  static Future<List<ExpertModel>> getExperts() async {
    try {
      final uri = Uri.parse('${ApiConfig.portalApiEndpoint}?action=experts_list');
      final response = await http.get(uri, headers: _headers).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] is List) {
          return (json['data'] as List).map((x) => ExpertModel.fromJson(x)).toList();
        }
      }
    } catch (e) {
      if (kDebugMode) print('getExperts error: $e');
    }
    return [];
  }

  /// Get list of registered students (Admin)
  static Future<List<StudentDirectoryModel>> getStudents() async {
    try {
      final uri = Uri.parse('${ApiConfig.portalApiEndpoint}?action=students_list');
      final response = await http.get(uri, headers: _headers).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] is List) {
          return (json['data'] as List).map((x) => StudentDirectoryModel.fromJson(x)).toList();
        }
      }
    } catch (e) {
      if (kDebugMode) print('getStudents error: $e');
    }
    return [];
  }

  /// Get payments / invoices list (Student & Admin)
  static Future<List<PaymentModel>> getPayments({String? studentId}) async {
    try {
      String url = '${ApiConfig.portalApiEndpoint}?action=payments_list';
      if (studentId != null && studentId.isNotEmpty) {
        url += '&student_id=${Uri.encodeComponent(studentId)}';
      }
      final response = await http.get(Uri.parse(url), headers: _headers).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] is List) {
          return (json['data'] as List).map((x) => PaymentModel.fromJson(x)).toList();
        }
      }
    } catch (e) {
      if (kDebugMode) print('getPayments error: $e');
    }
    return [];
  }

  /// Get discount coupons (Admin)
  static Future<List<CouponModel>> getCoupons() async {
    try {
      final uri = Uri.parse('${ApiConfig.portalApiEndpoint}?action=coupons');
      final response = await http.get(uri, headers: _headers).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] is List) {
          return (json['data'] as List).map((x) => CouponModel.fromJson(x)).toList();
        }
      }
    } catch (e) {
      if (kDebugMode) print('getCoupons error: $e');
    }
    return [];
  }

  /// Create a new coupon (Admin)
  static Future<bool> createCoupon({
    required String code,
    required int discountPercent,
    required int maxUses,
    required String expiresAt,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'coupons',
          'create': '1',
          'code': code,
          'discount_percent': discountPercent,
          'max_uses': maxUses,
          'expires_at': expiresAt,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      if (kDebugMode) print('createCoupon error: $e');
      return false;
    }
  }

  /// Get active courses / subjects (Student form & Admin)
  static Future<List<CourseModel>> getCourses() async {
    try {
      final uri = Uri.parse('${ApiConfig.portalApiEndpoint}?action=courses');
      final response = await http.get(uri, headers: _headers).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] is List) {
          return (json['data'] as List).map((x) => CourseModel.fromJson(x)).toList();
        }
      }
    } catch (e) {
      if (kDebugMode) print('getCourses error: $e');
    }
    return [];
  }

  /// Get support tickets
  static Future<List<SupportTicketModel>> getSupportTickets({
    required String userId,
    required String role,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.portalApiEndpoint}?action=support_tickets&user_id=${Uri.encodeComponent(userId)}&role=${Uri.encodeComponent(role)}',
      );
      final response = await http.get(uri, headers: _headers).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] is List) {
          return (json['data'] as List).map((x) => SupportTicketModel.fromJson(x)).toList();
        }
      }
    } catch (e) {
      if (kDebugMode) print('getSupportTickets error: $e');
    }
    return [];
  }

  /// Create a support ticket
  static Future<bool> createSupportTicket({
    required String userId,
    required String subject,
    required String message,
    String priority = 'Medium',
    String assignmentId = '',
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'support_tickets',
          'create': '1',
          'user_id': userId,
          'subject': subject,
          'message': message,
          'priority': priority,
          'assignment_id': assignmentId,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      if (kDebugMode) print('createSupportTicket error: $e');
      return false;
    }
  }

  /// Update user profile details
  static Future<bool> updateProfile({
    required String userId,
    required String role,
    required String name,
    required String phone,
    String country = '',
    String university = '',
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'update_profile',
          'user_id': userId,
          'role': role,
          'name': name,
          'phone': phone,
          'country': country,
          'university': university,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      if (kDebugMode) print('updateProfile error: $e');
      return false;
    }
  }

  /// Change account password
  static Future<ApiResponse<void>> changePassword({
    required String userId,
    required String role,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'change_password',
          'user_id': userId,
          'role': role,
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return ApiResponse(
        success: json['success'] == true,
        message: json['message']?.toString() ?? '',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Password change failed: $e', statusCode: 0);
    }
  }

  /// Admin toggle user status (Block/Unblock)
  static Future<bool> toggleUserStatus({
    required String targetRole,
    required String targetId,
    required String status,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'toggle_user_status',
          'target_role': targetRole,
          'target_id': targetId,
          'status': status,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      if (kDebugMode) print('toggleUserStatus error: $e');
      return false;
    }
  }
}
