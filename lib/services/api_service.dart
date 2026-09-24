import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../core/models/assignment_model.dart';
import '../core/models/dashboard_stats_model.dart';
import '../core/models/portal_models.dart';
import '../core/models/user_model.dart';
import 'db_service.dart';

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

      if (json['success'] == true) {
        return ApiResponse(
          success: true,
          message: json['message']?.toString() ?? 'Online',
          data: json['data'] is Map<String, dynamic> ? json['data'] : null,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) print('checkHealth HTTP error, trying direct DB: $e');
    }

    // Direct MySQL Fallback to AWS RDS
    final dbOk = await DirectDbService.checkHealth();
    if (dbOk) {
      return ApiResponse(
        success: true,
        message: 'Connected directly to AWS RDS MySQL',
        data: {'database': 'connected (AWS RDS MySQL)'},
        statusCode: 200,
      );
    }

    return ApiResponse(
      success: false,
      message: 'Could not connect to database on AWS RDS.',
      statusCode: 0,
    );
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
      if (json['success'] == true) {
        return ApiResponse(
          success: true,
          message: json['message']?.toString() ?? 'Login successful!',
          data: json['data'] is Map<String, dynamic> ? json['data'] : null,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) print('login HTTP error, trying direct MySQL: $e');
    }

    // Direct MySQL fallback to AWS RDS
    final directRes = await DirectDbService.login(email: email, password: password, role: role);
    if (directRes != null && directRes['success'] == true) {
      return ApiResponse(
        success: true,
        message: directRes['message']?.toString() ?? 'Login successful!',
        data: directRes['data'] as Map<String, dynamic>?,
        statusCode: 200,
      );
    }

    return ApiResponse(
      success: false,
      message: 'Invalid credentials or user account not found.',
      statusCode: 0,
    );
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
      if (kDebugMode) print('getDashboard HTTP error, trying direct MySQL: $e');
    }

    return await DirectDbService.getDashboard(role: role, userId: userId);
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
      if (kDebugMode) print('getAssignments HTTP error, trying direct MySQL: $e');
    }

    return await DirectDbService.getAssignments(role: role, userId: userId, status: status);
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
      if (kDebugMode) print('getAssignmentDetail HTTP error, trying direct MySQL: $e');
    }

    return await DirectDbService.getAssignmentDetail(assignmentId);
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
      if (json['success'] == true) return true;
    } catch (e) {
      if (kDebugMode) print('updateStatus HTTP error, trying direct MySQL: $e');
    }

    return await DirectDbService.updateStatus(assignmentId: assignmentId, status: status);
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
    String status = 'In Progress',
    String internalNotes = '',
  }) async {
    try {
      final dbOk = await DirectDbService.allocateExpertDirect(
        assignmentId: assignmentId,
        expertId: expertId,
        allocatorId: allocatorId,
        deadline: deadline,
        status: status,
        internalNotes: internalNotes,
      );
      if (dbOk) return true;
    } catch (_) {}

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
      if (kDebugMode) print('getExperts HTTP error, trying direct MySQL: $e');
    }
    return await DirectDbService.getExpertsList();
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
      if (kDebugMode) print('getStudents HTTP error, trying direct MySQL: $e');
    }
    return await DirectDbService.getStudentsList();
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
      if (kDebugMode) print('getPayments HTTP error, trying direct MySQL: $e');
    }
    return await DirectDbService.getPaymentsList();
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
      if (kDebugMode) print('getCoupons HTTP error, trying direct MySQL: $e');
    }
    return await DirectDbService.getCouponsList();
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
      if (kDebugMode) print('getCourses HTTP error, trying direct MySQL: $e');
    }
    return await DirectDbService.getCoursesList();
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

  /// Student Self-Registration
  static Future<ApiResponse<UserModel>> registerStudent({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String country,
    required String university,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'register',
          'name': name.trim(),
          'email': email.trim(),
          'password': password.trim(),
          'phone': phone.trim(),
          'country': country.trim(),
          'university': university.trim(),
        }),
      ).timeout(timeoutDuration);

      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] is Map && (json['data'] as Map)['user'] is Map) {
        return ApiResponse(
          success: true,
          message: json['message']?.toString() ?? 'Registration successful!',
          data: UserModel.fromJson(Map<String, dynamic>.from((json['data'] as Map)['user'])),
          statusCode: response.statusCode,
        );
      }
      return ApiResponse(
        success: false,
        message: json['message']?.toString() ?? 'Registration failed',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e', statusCode: 0);
    }
  }

  /// Upload assignment file (multipart)
  static Future<ApiResponse<List<dynamic>>> uploadAssignmentFile({
    required String assignmentId,
    required String filePath,
    required String fileName,
    String fileStage = 'brief',
    String uploadedBy = 'Student',
    bool isInternal = false,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'ngrok-skip-browser-warning': 'true',
        'User-Agent': 'AAH-Mobile-App/1.0',
      });
      request.fields['action'] = 'upload_file';
      request.fields['assignment_id'] = assignmentId;
      request.fields['file_stage'] = fileStage;
      request.fields['uploaded_by'] = uploadedBy;
      request.fields['is_internal'] = isInternal ? '1' : '0';

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: fileName,
      ));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);
      final json = jsonDecode(response.body);

      return ApiResponse(
        success: json['success'] == true,
        message: json['message']?.toString() ?? '',
        data: json['data'] is Map && (json['data'] as Map)['files'] is List ? (json['data'] as Map)['files'] as List : null,
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (kDebugMode) print('uploadAssignmentFile error: $e');
      return ApiResponse(success: false, message: 'Upload failed: $e', statusCode: 0);
    }
  }

  /// Delete assignment file
  static Future<bool> deleteAssignmentFile(String fileId) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'delete_file',
          'file_id': fileId,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Submit revision request
  static Future<ApiResponse<void>> requestRevision({
    required String assignmentId,
    required String studentId,
    required String instructions,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'request_revision',
          'assignment_id': assignmentId,
          'student_id': studentId,
          'instructions': instructions,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return ApiResponse(
        success: json['success'] == true,
        message: json['message']?.toString() ?? '',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Revision request failed: $e', statusCode: 0);
    }
  }

  /// Submit refund request
  static Future<ApiResponse<void>> requestRefund({
    required String assignmentId,
    required String studentId,
    required String reason,
    required String details,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'request_refund',
          'assignment_id': assignmentId,
          'student_id': studentId,
          'reason': reason,
          'details': details,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return ApiResponse(
        success: json['success'] == true,
        message: json['message']?.toString() ?? '',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Refund request failed: $e', statusCode: 0);
    }
  }

  /// Get live chat messages
  static Future<List<ChatMessageModel>> getChatMessages({
    String? studentId,
    String? assignmentId,
  }) async {
    try {
      String query = '${ApiConfig.portalApiEndpoint}?action=get_chat';
      if (studentId != null && studentId.isNotEmpty) {
        query += '&student_id=${Uri.encodeComponent(studentId)}';
      }
      if (assignmentId != null && assignmentId.isNotEmpty) {
        query += '&assignment_id=${Uri.encodeComponent(assignmentId)}';
      }
      final response = await http.get(Uri.parse(query), headers: _headers).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] is List) {
          return (json['data'] as List)
              .map((item) => ChatMessageModel.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) print('getChatMessages error: $e');
    }
    return [];
  }

  /// Send live chat message
  static Future<ChatMessageModel?> sendChatMessage({
    required String senderId,
    required String senderRole,
    required String senderName,
    required String studentId,
    String? assignmentId,
    required String message,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'send_chat',
          'sender_id': senderId,
          'sender_role': senderRole,
          'sender_name': senderName,
          'student_id': studentId,
          'assignment_id': assignmentId ?? '',
          'message': message,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] is Map) {
        return ChatMessageModel.fromJson(Map<String, dynamic>.from(json['data']));
      }
    } catch (e) {
      if (kDebugMode) print('sendChatMessage error: $e');
    }
    return null;
  }

  /// Allocator Approve QA
  static Future<bool> allocatorApproveQa({
    required String assignmentId,
    required String allocatorId,
    required String allocatorName,
  }) async {
    try {
      final dbOk = await DirectDbService.allocatorApproveQaDirect(
        assignmentId: assignmentId,
        allocatorId: allocatorId,
        allocatorName: allocatorName,
      );
      if (dbOk) return true;
    } catch (_) {}

    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'allocator_approve_qa',
          'assignment_id': assignmentId,
          'allocator_id': allocatorId,
          'allocator_name': allocatorName,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Allocator Request Revision from Expert
  static Future<bool> allocatorRequestRevision({
    required String assignmentId,
    required String allocatorId,
    required String allocatorName,
    required String instructions,
  }) async {
    try {
      final dbOk = await DirectDbService.allocatorRequestRevisionDirect(
        assignmentId: assignmentId,
        allocatorId: allocatorId,
        allocatorName: allocatorName,
        instructions: instructions,
      );
      if (dbOk) return true;
    } catch (_) {}

    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'allocator_request_revision',
          'assignment_id': assignmentId,
          'allocator_id': allocatorId,
          'allocator_name': allocatorName,
          'instructions': instructions,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Admin Final Solution Release
  static Future<bool> adminReleaseSolution({
    required String assignmentId,
    required String adminId,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'admin_release_solution',
          'assignment_id': assignmentId,
          'admin_id': adminId,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get Admins List
  static Future<List<AdminStaffModel>> getAdmins() async {
    try {
      final uri = Uri.parse('${ApiConfig.portalApiEndpoint}?action=admins_list');
      final response = await http.get(uri, headers: _headers).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] is List) {
          return (json['data'] as List)
              .map((item) => AdminStaffModel.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) print('getAdmins HTTP error, trying direct MySQL: $e');
    }
    return await DirectDbService.getAdminsList();
  }

  /// Create Admin
  static Future<bool> createAdmin({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'admin_create',
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Delete Admin
  static Future<bool> deleteAdmin(String adminId) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'admin_delete',
          'admin_id': adminId,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get Allocators List
  static Future<List<AllocatorStaffModel>> getAllocators() async {
    try {
      final uri = Uri.parse('${ApiConfig.portalApiEndpoint}?action=allocators_list');
      final response = await http.get(uri, headers: _headers).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] is List) {
          return (json['data'] as List)
              .map((item) => AllocatorStaffModel.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) print('getAllocators HTTP error, trying direct MySQL: $e');
    }
    return await DirectDbService.getAllocatorsList();
  }

  /// Create Allocator
  static Future<bool> createAllocator({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'allocator_create',
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Delete Allocator
  static Future<bool> deleteAllocator(String allocatorId) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'allocator_delete',
          'allocator_id': allocatorId,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Create Expert
  static Future<bool> createExpert({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String subjects,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'expert_create',
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'subjects': subjects,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Delete Expert
  static Future<bool> deleteExpert(String expertId) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'expert_delete',
          'expert_id': expertId,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Update Expert Payout Details
  static Future<bool> updateExpertPayout({
    required String expertId,
    String payoutInfo = '',
    String bankName = '',
    String accountHolder = '',
    String accountNumber = '',
    String ifscSwift = '',
    String paypalEmail = '',
  }) async {
    try {
      final infoString = payoutInfo.isNotEmpty
          ? payoutInfo
          : 'Bank: $bankName | Beneficiary: $accountHolder | Acc: $accountNumber | IFSC: $ifscSwift | PayPal: $paypalEmail';
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'expert_update_payout',
          'expert_id': expertId,
          'payout_info': infoString,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Convenience wrapper to upload file directly
  static Future<bool> uploadFile({
    required String assignmentId,
    required File file,
    String fileStage = 'brief',
    String uploadedBy = 'User',
    bool isInternal = false,
  }) async {
    final fileName = file.path.split('/').last;
    final res = await uploadAssignmentFile(
      assignmentId: assignmentId,
      filePath: file.path,
      fileName: fileName,
      fileStage: fileStage,
      uploadedBy: uploadedBy,
      isInternal: isInternal,
    );
    return res.success;
  }

  /// Convenience wrapper to get assignment chat messages
  static Future<List<ChatMessageModel>> getChat(String assignmentId) =>
      getChatMessages(assignmentId: assignmentId);

  /// Convenience wrapper to send assignment chat message
  static Future<bool> sendChat({
    required String assignmentId,
    required String senderId,
    required String senderRole,
    required String senderName,
    required String message,
    String? studentId,
    String? expertId,
  }) async {
    final res = await sendChatMessage(
      senderId: senderId,
      senderRole: senderRole,
      senderName: senderName,
      studentId: studentId ?? senderId,
      assignmentId: assignmentId,
      message: message,
    );
    return res != null;
  }

  /// Get System Audit Logs
  static Future<List<AuditLogModel>> getAuditLogs() async {
    try {
      final uri = Uri.parse('${ApiConfig.portalApiEndpoint}?action=audit_logs');
      final response = await http.get(uri, headers: _headers).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] is List) {
          return (json['data'] as List)
              .map((item) => AuditLogModel.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) print('getAuditLogs HTTP error, trying direct MySQL: $e');
    }
    return await DirectDbService.getAuditLogs();
  }

  /// Get Blogs List
  static Future<List<BlogModel>> getBlogs() async {
    try {
      final uri = Uri.parse('${ApiConfig.portalApiEndpoint}?action=blogs_list');
      final response = await http.get(uri, headers: _headers).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] is List) {
          return (json['data'] as List)
              .map((item) => BlogModel.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) print('getBlogs HTTP error, trying direct MySQL: $e');
    }
    return await DirectDbService.getBlogsList();
  }

  /// Create Blog
  static Future<bool> createBlog({
    required String title,
    required String excerpt,
    required String category,
    required String author,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'blog_create',
          'title': title,
          'excerpt': excerpt,
          'category': category,
          'author': author,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Delete Blog
  static Future<bool> deleteBlog(int blogId) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'blog_delete',
          'id': blogId,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get Site Settings
  static Future<Map<String, dynamic>?> getSiteSettings() async {
    try {
      final uri = Uri.parse('${ApiConfig.portalApiEndpoint}?action=site_settings');
      final response = await http.get(uri, headers: _headers).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] is Map<String, dynamic>) {
          return json['data'];
        }
      }
    } catch (e) {
      if (kDebugMode) print('getSiteSettings HTTP error, trying direct MySQL: $e');
    }
    return await DirectDbService.getSiteSettings();
  }

  /// Update Site Settings
  static Future<bool> updateSiteSettings(Map<String, dynamic> settings) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final payload = Map<String, dynamic>.from(settings);
      payload['action'] = 'site_settings';
      payload['save_settings'] = '1';

      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Process Partial / Remaining Payment
  static Future<ApiResponse<void>> processPartialPayment({
    required String assignmentId,
    required String studentId,
    required double amount,
    String paymentMethod = 'Stripe / Online',
    String currency = 'USD',
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.portalApiEndpoint);
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': 'process_partial_payment',
          'assignment_id': assignmentId,
          'student_id': studentId,
          'amount': amount,
          'payment_method': paymentMethod,
          'currency': currency,
        }),
      ).timeout(timeoutDuration);
      final json = jsonDecode(response.body);
      return ApiResponse(
        success: json['success'] == true,
        message: json['message']?.toString() ?? '',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Payment processing failed: $e', statusCode: 0);
    }
  }

  /// Get Invoice Detail
  static Future<Map<String, dynamic>?> getInvoiceDetail(String assignmentId) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.portalApiEndpoint}?action=invoice_detail&assignment_id=${Uri.encodeComponent(assignmentId)}',
      );
      final response = await http.get(uri, headers: _headers).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] is Map<String, dynamic>) {
          return json['data'];
        }
      }
    } catch (e) {
      if (kDebugMode) print('getInvoiceDetail error: $e');
    }
    return null;
  }

  // ================= ADMIN PORTAL OPERATIONS ================= //

  /// Courses CRUD
  static Future<bool> createCourse({
    required String title,
    required String category,
    String icon = 'fa-book-open',
    String description = '',
    String topics = '',
    String status = 'Active',
  }) async {
    return await DirectDbService.createCourse(
      title: title,
      category: category,
      icon: icon,
      description: description,
      topics: topics,
      status: status,
    );
  }

  static Future<bool> updateCourse({
    required String courseId,
    required String title,
    required String category,
    String icon = 'fa-book-open',
    String description = '',
    String topics = '',
    String status = 'Active',
  }) async {
    return await DirectDbService.updateCourse(
      courseId: courseId,
      title: title,
      category: category,
      icon: icon,
      description: description,
      topics: topics,
      status: status,
    );
  }

  static Future<bool> deleteCourse(String courseId) async {
    return await DirectDbService.deleteCourse(courseId);
  }

  static Future<bool> toggleCourseStatus(String courseId, String newStatus) async {
    return await DirectDbService.toggleCourseStatus(courseId, newStatus);
  }

  /// Students CRUD
  static Future<bool> createStudent({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String country = 'United Kingdom',
    String university = '',
    String course = '',
    String status = 'Active',
  }) async {
    return await DirectDbService.createStudent(
      name: name,
      email: email,
      password: password,
      phone: phone,
      country: country,
      university: university,
      course: course,
      status: status,
    );
  }

  static Future<bool> updateStudent({
    required String studentId,
    required String name,
    String phone = '',
    String country = '',
    String university = '',
    String course = '',
    String? password,
    String status = 'Active',
  }) async {
    return await DirectDbService.updateStudent(
      studentId: studentId,
      name: name,
      phone: phone,
      country: country,
      university: university,
      course: course,
      password: password,
      status: status,
    );
  }

  static Future<bool> deleteStudent(String studentId) async {
    return await DirectDbService.deleteStudent(studentId);
  }

  /// Experts CRUD
  static Future<bool> updateExpert({
    required String expertId,
    required String name,
    String phone = '',
    String subjects = '',
    String status = 'Available',
    String? password,
  }) async {
    return await DirectDbService.updateExpert(
      expertId: expertId,
      name: name,
      phone: phone,
      subjects: subjects,
      status: status,
      password: password,
    );
  }

  static Future<bool> toggleExpertStatus(String expertId, String status) async {
    return await DirectDbService.toggleExpertStatus(expertId, status);
  }

  /// Staff CRUD
  static Future<bool> updateAllocator({
    required String allocatorId,
    required String name,
    String phone = '',
    String status = 'Active',
    String? password,
  }) async {
    return await DirectDbService.updateAllocator(
      allocatorId: allocatorId,
      name: name,
      phone: phone,
      status: status,
      password: password,
    );
  }

  static Future<bool> updateAdmin({
    required String adminId,
    required String name,
    String phone = '',
    String status = 'Active',
    String? password,
  }) async {
    return await DirectDbService.updateAdmin(
      adminId: adminId,
      name: name,
      phone: phone,
      status: status,
      password: password,
    );
  }

  static Future<bool> toggleStaffStatus(String role, String staffId, String status) async {
    return await DirectDbService.toggleStaffStatus(role, staffId, status);
  }

  /// Coupons CRUD
  static Future<bool> updateCoupon({
    required String couponId,
    required String code,
    required int discountPercent,
    required int maxUses,
    String status = 'Active',
  }) async {
    return await DirectDbService.updateCoupon(
      couponId: couponId,
      code: code,
      discountPercent: discountPercent,
      maxUses: maxUses,
      status: status,
    );
  }

  static Future<bool> deleteCoupon(String couponId) async {
    return await DirectDbService.deleteCoupon(couponId);
  }

  static Future<bool> toggleCouponStatus(String couponId, String status) async {
    return await DirectDbService.toggleCouponStatus(couponId, status);
  }

  /// Manual Payments
  static Future<bool> createManualPayment({
    required String assignmentId,
    required String studentId,
    required double amount,
    String currency = 'USD',
    String paymentMethod = 'Bank Wire / Offline Transfer',
    String transactionId = '',
    String paymentPlan = 'Full Payment',
    String status = 'Completed',
  }) async {
    return await DirectDbService.createManualPayment(
      assignmentId: assignmentId,
      studentId: studentId,
      amount: amount,
      currency: currency,
      paymentMethod: paymentMethod,
      transactionId: transactionId,
      paymentPlan: paymentPlan,
      status: status,
    );
  }

  /// Assignments Admin Controls
  static Future<bool> updateAssignmentAdmin({
    required String assignmentId,
    String? status,
    double? price,
    String? expertId,
    String? allocatorId,
  }) async {
    return await DirectDbService.updateAssignmentAdmin(
      assignmentId: assignmentId,
      status: status,
      price: price,
      expertId: expertId,
      allocatorId: allocatorId,
    );
  }

  static Future<bool> softDeleteAssignment(String assignmentId) async {
    return await DirectDbService.softDeleteAssignment(assignmentId);
  }

  static Future<bool> restoreAssignment(String assignmentId) async {
    return await DirectDbService.restoreAssignment(assignmentId);
  }

  static Future<bool> wipeAssignment(String assignmentId) async {
    return await DirectDbService.wipeAssignment(assignmentId);
  }

  static Future<List<AssignmentModel>> getArchivedAssignments() async {
    return await DirectDbService.getArchivedAssignments();
  }

  /// Notifications
  static Future<bool> sendBroadcastNotification({
    required String targetRole,
    required String title,
    required String message,
  }) async {
    return await DirectDbService.sendBroadcastNotification(
      targetRole: targetRole,
      title: title,
      message: message,
    );
  }

  static Future<bool> markAllNotificationsRead(String userId) async {
    return await DirectDbService.markAllNotificationsRead(userId);
  }

  static Future<bool> deleteNotification(String notificationId) async {
    return await DirectDbService.deleteNotification(notificationId);
  }

  /// Blogs
  static Future<bool> updateBlog({
    required int blogId,
    required String title,
    required String excerpt,
    required String content,
    required String category,
  }) async {
    return await DirectDbService.updateBlog(
      blogId: blogId,
      title: title,
      excerpt: excerpt,
      content: content,
      category: category,
    );
  }

  /// System Backup
  static Future<Map<String, dynamic>> generateSystemBackup() async {
    return await DirectDbService.generateSystemBackup();
  }

  /// Allocator Deliverable Files CRUD
  static Future<bool> uploadDeliverable({
    required String assignmentId,
    required String fileName,
    required String fileType,
    required String fileStage,
    required String uploadedBy,
    required bool isInternal,
    String path = '',
  }) async {
    return await DirectDbService.uploadDeliverableDirect(
      assignmentId: assignmentId,
      fileName: fileName,
      fileType: fileType,
      fileStage: fileStage,
      uploadedBy: uploadedBy,
      isInternal: isInternal,
      path: path,
    );
  }

  static Future<bool> toggleFileStage({
    required int fileId,
    required String newStage,
  }) async {
    return await DirectDbService.toggleFileStageDirect(
      fileId: fileId,
      newStage: newStage,
    );
  }

  static Future<bool> deleteFile({required int fileId}) async {
    return await DirectDbService.deleteFileDirect(fileId: fileId);
  }

  /// Allocator Email Center
  static Future<bool> sendAutomatedEmail({
    required String assignmentId,
    required String template,
    required String recipient,
    required String senderId,
    required String senderName,
    String customMessage = '',
  }) async {
    return await DirectDbService.sendAutomatedEmailDirect(
      assignmentId: assignmentId,
      template: template,
      recipient: recipient,
      senderId: senderId,
      senderName: senderName,
      customMessage: customMessage,
    );
  }

  static Future<List<Map<String, dynamic>>> getEmailHistory() async {
    return await DirectDbService.getEmailHistoryDirect();
  }

  /// Allocator Completed Log
  static Future<List<AssignmentModel>> getCompletedAssignmentsForAllocator() async {
    return await DirectDbService.getCompletedAssignmentsDirect();
  }

  /// Allocator Notifications
  static Future<List<NotificationModel>> getAllocatorNotifications({
    required String allocatorId,
  }) async {
    return await DirectDbService.getAllocatorNotificationsDirect(allocatorId: allocatorId);
  }

  static Future<bool> markAllAllocatorNotificationsRead({
    required String allocatorId,
  }) async {
    return await DirectDbService.markAllNotificationsReadDirect(
      userRole: 'Allocator',
      userId: allocatorId,
    );
  }
}


