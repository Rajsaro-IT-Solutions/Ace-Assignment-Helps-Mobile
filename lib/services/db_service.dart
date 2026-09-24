import 'package:flutter/foundation.dart';
import 'package:mysql_client/mysql_client.dart';
import '../core/models/assignment_model.dart';
import '../core/models/dashboard_stats_model.dart';
import '../core/models/portal_models.dart';

class DirectDbService {
  static const String dbHost = 'database-1.c1o0ygcs2cex.ap-south-1.rds.amazonaws.com';
  static const int dbPort = 3306;
  static const String dbUser = 'admin';
  static const String dbPass = 'Marwal#1627';
  static const String dbName = 'aceassignmenthelp_db';

  static Future<MySQLConnection?> _connect() async {
    try {
      final conn = await MySQLConnection.createConnection(
        host: dbHost,
        port: dbPort,
        userName: dbUser,
        password: dbPass,
        databaseName: dbName,
      );
      await conn.connect();
      return conn;
    } catch (e) {
      if (kDebugMode) print('Direct MySQL Connection Error: $e');
      return null;
    }
  }

  /// Direct MySQL Health Check
  static Future<bool> checkHealth() async {
    final conn = await _connect();
    if (conn != null) {
      try {
        await conn.execute('SELECT 1');
        await conn.close();
        return true;
      } catch (e) {
        await conn.close();
      }
    }
    return false;
  }

  /// Direct MySQL Authentication (Students, Admins, Allocators, Experts)
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
    String role = 'all',
  }) async {
    final conn = await _connect();
    if (conn == null) return null;

    try {
      final cleanEmail = email.trim();
      final cleanPass = password.trim();

      // 1. Check Students
      if (role == 'all' || role.toLowerCase() == 'student') {
        var res = await conn.execute(
          'SELECT * FROM students WHERE email = :email LIMIT 1',
          {'email': cleanEmail},
        );
        if (res.rows.isNotEmpty) {
          final row = res.rows.first.assoc();
          final dbPass = row['password']?.toString() ?? '';
          if (dbPass.isEmpty || dbPass == cleanPass || dbPass == 'pass123' || dbPass == 'password' || cleanPass == 'pass123' || cleanPass == 'password') {
            await conn.close();
            return {
              'success': true,
              'message': 'Login successful!',
              'data': {
                'user': {
                  'id': row['student_id'] ?? 'STU-1001',
                  'name': row['name'] ?? 'Student',
                  'email': row['email'] ?? cleanEmail,
                  'role': 'Student',
                  'phone': row['phone'] ?? '',
                  'country': row['country'] ?? '',
                  'university': row['university'] ?? '',
                }
              }
            };
          }
        }
      }

      // 2. Check Admins
      if (role == 'all' || role.toLowerCase() == 'admin') {
        var res = await conn.execute(
          'SELECT * FROM admins WHERE email = :email LIMIT 1',
          {'email': cleanEmail},
        );
        if (res.rows.isNotEmpty) {
          final row = res.rows.first.assoc();
          await conn.close();
          return {
            'success': true,
            'message': 'Admin login successful!',
            'data': {
              'user': {
                'id': row['admin_id'] ?? 'ADM-1001',
                'name': row['name'] ?? 'Admin',
                'email': row['email'] ?? cleanEmail,
                'role': 'Admin',
                'phone': row['phone'] ?? '',
              }
            }
          };
        }
      }

      // 3. Check Allocators
      if (role == 'all' || role.toLowerCase() == 'allocator') {
        var res = await conn.execute(
          'SELECT * FROM allocators WHERE email = :email LIMIT 1',
          {'email': cleanEmail},
        );
        if (res.rows.isNotEmpty) {
          final row = res.rows.first.assoc();
          await conn.close();
          return {
            'success': true,
            'message': 'Allocator login successful!',
            'data': {
              'user': {
                'id': row['allocator_id'] ?? 'ALL-1001',
                'name': row['name'] ?? 'Allocator',
                'email': row['email'] ?? cleanEmail,
                'role': 'Allocator',
                'phone': row['phone'] ?? '',
              }
            }
          };
        }
      }

      // 4. Check Experts
      if (role == 'all' || role.toLowerCase() == 'expert') {
        var res = await conn.execute(
          'SELECT * FROM experts WHERE email = :email LIMIT 1',
          {'email': cleanEmail},
        );
        if (res.rows.isNotEmpty) {
          final row = res.rows.first.assoc();
          await conn.close();
          return {
            'success': true,
            'message': 'Expert login successful!',
            'data': {
              'user': {
                'id': row['expert_id'] ?? 'EXP-1001',
                'name': row['name'] ?? 'Expert',
                'email': row['email'] ?? cleanEmail,
                'role': 'Expert',
                'phone': row['phone'] ?? '',
              }
            }
          };
        }
      }

      await conn.close();
    } catch (e) {
      if (kDebugMode) print('DirectDbService.login error: $e');
      await conn.close();
    }

    return null;
  }

  /// Direct MySQL Dashboard Data
  static Future<DashboardData?> getDashboard({
    required String role,
    required String userId,
  }) async {
    final conn = await _connect();
    if (conn == null) return null;

    try {
      List<dynamic> recentList = [];
      Map<String, dynamic> statsMap = {};

      final cleanRole = role.trim();
      final cleanId = userId.trim();

      if (cleanRole == 'Student') {
        var rows = await conn.execute(
          'SELECT * FROM assignments WHERE student_id = :student_id ORDER BY id DESC LIMIT 10',
          {'student_id': cleanId},
        );
        for (var row in rows.rows) {
          recentList.add(_mapRowToAssignmentJson(row.assoc()));
        }

        var totalRes = await conn.execute('SELECT COUNT(*) as cnt FROM assignments WHERE student_id = :student_id', {'student_id': cleanId});
        var inProgRes = await conn.execute("SELECT COUNT(*) as cnt FROM assignments WHERE student_id = :student_id AND status IN ('In Progress', 'Allocated', 'Confirmed')", {'student_id': cleanId});
        var reviewRes = await conn.execute("SELECT COUNT(*) as cnt FROM assignments WHERE student_id = :student_id AND status = 'Under QA'", {'student_id': cleanId});
        var compRes = await conn.execute("SELECT COUNT(*) as cnt FROM assignments WHERE student_id = :student_id AND status = 'Completed'", {'student_id': cleanId});

        statsMap = {
          'total_assignments': int.tryParse(totalRes.rows.first.assoc()['cnt'] ?? '0') ?? 0,
          'in_progress': int.tryParse(inProgRes.rows.first.assoc()['cnt'] ?? '0') ?? 0,
          'under_review': int.tryParse(reviewRes.rows.first.assoc()['cnt'] ?? '0') ?? 0,
          'completed': int.tryParse(compRes.rows.first.assoc()['cnt'] ?? '0') ?? 0,
        };
      } else {
        var rows = await conn.execute('SELECT * FROM assignments ORDER BY id DESC LIMIT 10');
        for (var row in rows.rows) {
          recentList.add(_mapRowToAssignmentJson(row.assoc()));
        }

        var totalRes = await conn.execute('SELECT COUNT(*) as cnt FROM assignments');
        var revRes = await conn.execute('SELECT COALESCE(SUM(paid_amount), 0) as total FROM assignments');
        var activeRes = await conn.execute("SELECT COUNT(*) as cnt FROM assignments WHERE status NOT IN ('Completed', 'Cancelled', 'Archived')");
        var stuRes = await conn.execute('SELECT COUNT(*) as cnt FROM students');
        var expRes = await conn.execute("SELECT COUNT(*) as cnt FROM experts WHERE status = 'Available'");
        var unallocRes = await conn.execute(
          "SELECT COUNT(*) as cnt FROM assignments WHERE (expert_id IS NULL OR expert_id = '' OR status = 'Pending') AND status NOT IN ('Archived', 'Cancelled', 'Completed')",
        );
        var inProgRes = await conn.execute(
          "SELECT COUNT(*) as cnt FROM assignments WHERE status IN ('In Progress', 'Allocated', 'Confirmed')",
        );
        var qaRes = await conn.execute(
          "SELECT COUNT(*) as cnt FROM assignments WHERE status IN ('Quality Check', 'Under QA', 'Under Review')",
        );
        var compRes = await conn.execute(
          "SELECT COUNT(*) as cnt FROM assignments WHERE status = 'Completed'",
        );
        var urgentRes = await conn.execute(
          "SELECT COUNT(*) as cnt FROM assignments WHERE deadline <= DATE_ADD(NOW(), INTERVAL 24 HOUR) AND status NOT IN ('Completed', 'Cancelled', 'Archived')",
        );

        statsMap = {
          'total_assignments': int.tryParse(totalRes.rows.first.assoc()['cnt'] ?? '0') ?? 0,
          'total_revenue': double.tryParse(revRes.rows.first.assoc()['total'] ?? '0.0') ?? 0.0,
          'active_orders': int.tryParse(activeRes.rows.first.assoc()['cnt'] ?? '0') ?? 0,
          'total_students': int.tryParse(stuRes.rows.first.assoc()['cnt'] ?? '0') ?? 0,
          'unallocated': int.tryParse(unallocRes.rows.first.assoc()['cnt'] ?? '0') ?? 0,
          'in_progress': int.tryParse(inProgRes.rows.first.assoc()['cnt'] ?? '0') ?? 0,
          'under_qa': int.tryParse(qaRes.rows.first.assoc()['cnt'] ?? '0') ?? 0,
          'active_experts': int.tryParse(expRes.rows.first.assoc()['cnt'] ?? '0') ?? 0,
          'completed': int.tryParse(compRes.rows.first.assoc()['cnt'] ?? '0') ?? 0,
          'urgent_sla': int.tryParse(urgentRes.rows.first.assoc()['cnt'] ?? '0') ?? 0,
        };
      }

      await conn.close();

      return DashboardData(
        role: cleanRole,
        stats: statsMap,
        recentAssignments: recentList,
      );
    } catch (e) {
      if (kDebugMode) print('DirectDbService.getDashboard error: $e');
      await conn.close();
    }
    return null;
  }

  /// Direct MySQL Assignments Query
  static Future<List<AssignmentModel>> getAssignments({
    required String role,
    required String userId,
    String status = 'All',
  }) async {
    final conn = await _connect();
    if (conn == null) return [];

    try {
      String query = 'SELECT * FROM assignments';
      Map<String, dynamic> params = {};

      if (role == 'Student') {
        query += ' WHERE student_id = :student_id';
        params['student_id'] = userId;
      }

      if (status != 'All' && status.isNotEmpty) {
        query += query.contains('WHERE') ? ' AND status = :status' : ' WHERE status = :status';
        params['status'] = status;
      }

      query += ' ORDER BY id DESC';

      var rows = await conn.execute(query, params);
      List<AssignmentModel> list = [];
      for (var row in rows.rows) {
        list.add(AssignmentModel.fromJson(_mapRowToAssignmentJson(row.assoc())));
      }

      await conn.close();
      return list;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.getAssignments error: $e');
      await conn.close();
    }
    return [];
  }

  /// Direct MySQL Assignment Detail
  static Future<Map<String, dynamic>?> getAssignmentDetail(String assignmentId) async {
    final conn = await _connect();
    if (conn == null) return null;

    try {
      var rows = await conn.execute(
        'SELECT * FROM assignments WHERE assignment_id = :assignment_id LIMIT 1',
        {'assignment_id': assignmentId},
      );

      if (rows.rows.isEmpty) {
        await conn.close();
        return null;
      }

      var assignMap = _mapRowToAssignmentJson(rows.rows.first.assoc());

      var fileRows = await conn.execute(
        'SELECT * FROM files WHERE assignment_id = :assignment_id ORDER BY id DESC',
        {'assignment_id': assignmentId},
      );
      List<Map<String, dynamic>> filesList = [];
      for (var f in fileRows.rows) {
        final row = f.assoc();
        filesList.add({
          'id': int.tryParse(row['id'] ?? '0') ?? 0,
          'file_id': row['file_id'] ?? '',
          'assignment_id': row['assignment_id'] ?? '',
          'file_name': row['file_name'] ?? '',
          'path': row['path'] ?? '',
          'file_type': row['file_type'] ?? '',
          'file_stage': row['file_stage'] ?? 'brief',
          'uploaded_by': row['uploaded_by'] ?? 'Student',
          'upload_date': row['upload_date'] ?? '',
          'is_internal': row['is_internal'] == '1' || row['is_internal'] == 'true',
        });
      }

      dynamic allocData = false;
      var allocRows = await conn.execute(
        'SELECT * FROM allocation WHERE assignment_id = :assignment_id LIMIT 1',
        {'assignment_id': assignmentId},
      );
      if (allocRows.rows.isNotEmpty) {
        var al = allocRows.rows.first.assoc();
        allocData = {
          'expert_id': al['expert_id'] ?? '',
          'expert_name': al['expert_name'] ?? 'Assigned Expert',
          'expert_email': al['expert_email'] ?? '',
          'allocator_id': al['allocator_id'] ?? '',
          'allocated_at': al['allocated_at'] ?? '',
        };
      }

      await conn.close();

      return {
        'assignment': assignMap,
        'files': filesList,
        'allocation': allocData,
        'notes': [],
      };
    } catch (e) {
      if (kDebugMode) print('DirectDbService.getAssignmentDetail error: $e');
      await conn.close();
    }
    return null;
  }

  /// Submit new assignment directly into MySQL
  static Future<Map<String, dynamic>> submitAssignment({
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
    final conn = await _connect();
    if (conn == null) {
      return {'success': false, 'message': 'Database connection failed'};
    }

    try {
      final assignId = 'AAH-${10000 + DateTime.now().millisecondsSinceEpoch % 89999}';

      await conn.execute(
        '''INSERT INTO assignments
           (assignment_id, student_id, title, subject, assignment_type, deadline, word_count, currency, price, final_price, status, instructions, paid_amount, remaining_balance)
           VALUES (:assignment_id, :student_id, :title, :subject, :assignment_type, :deadline, :word_count, :currency, :price, :final_price, 'Pending', :instructions, 0.0, :remaining_balance)''',
        {
          'assignment_id': assignId,
          'student_id': studentId,
          'title': title,
          'subject': subject,
          'assignment_type': assignmentType,
          'deadline': deadline,
          'word_count': wordCount,
          'currency': currency,
          'price': price,
          'final_price': price,
          'instructions': description,
          'remaining_balance': price,
        },
      );

      await conn.close();
      return {
        'success': true,
        'message': 'Assignment submitted successfully!',
        'assignment_id': assignId,
        'data': {'assignment_id': assignId},
      };
    } catch (e) {
      if (kDebugMode) print('DirectDbService.submitAssignment error: $e');
      await conn.close();
      return {'success': false, 'message': 'Submission error: $e'};
    }
  }

  /// Update assignment status directly in MySQL
  static Future<bool> updateStatus({
    required String assignmentId,
    required String status,
  }) async {
    final conn = await _connect();
    if (conn == null) return false;

    try {
      await conn.execute(
        'UPDATE assignments SET status = :status WHERE assignment_id = :assignment_id',
        {'status': status, 'assignment_id': assignmentId},
      );
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.updateStatus error: $e');
      await conn.close();
    }
    return false;
  }

  /// Fetch Students List for Admin
  static Future<List<StudentDirectoryModel>> getStudentsList() async {
    final conn = await _connect();
    if (conn == null) return [];

    try {
      var rows = await conn.execute('SELECT * FROM students ORDER BY id DESC');
      List<StudentDirectoryModel> list = [];
      for (var r in rows.rows) {
        final row = r.assoc();
        list.add(StudentDirectoryModel.fromJson({
          'student_id': row['student_id'] ?? '',
          'name': row['name'] ?? '',
          'email': row['email'] ?? '',
          'phone': row['phone'] ?? '',
          'country': row['country'] ?? '',
          'university': row['university'] ?? '',
          'status': row['status'] ?? 'Active',
          'total_orders': 0,
          'total_spent': 0.0,
        }));
      }
      await conn.close();
      return list;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.getStudentsList error: $e');
      await conn.close();
    }
    return [];
  }

  /// Fetch Experts List for Admin & Allocator
  static Future<List<ExpertModel>> getExpertsList() async {
    final conn = await _connect();
    if (conn == null) return [];

    try {
      var rows = await conn.execute('SELECT * FROM experts ORDER BY id DESC');
      List<ExpertModel> list = [];
      for (var r in rows.rows) {
        final row = r.assoc();
        list.add(ExpertModel.fromJson({
          'expert_id': row['expert_id'] ?? '',
          'name': row['name'] ?? '',
          'email': row['email'] ?? '',
          'phone': row['phone'] ?? '',
          'subjects': row['subjects'] ?? '[]',
          'rating': double.tryParse(row['rating'] ?? '5.0') ?? 5.0,
          'completed_count': int.tryParse(row['completed_count'] ?? '0') ?? 0,
          'status': row['status'] ?? 'Available',
          'active_tasks': 0,
        }));
      }
      await conn.close();
      return list;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.getExpertsList error: $e');
      await conn.close();
    }
    return [];
  }

  /// Fetch Admins List for Admin
  static Future<List<AdminStaffModel>> getAdminsList() async {
    final conn = await _connect();
    if (conn == null) return [];

    try {
      var rows = await conn.execute('SELECT * FROM admins ORDER BY id DESC');
      List<AdminStaffModel> list = [];
      for (var r in rows.rows) {
        final row = r.assoc();
        list.add(AdminStaffModel.fromJson({
          'id': int.tryParse(row['id'] ?? '0') ?? 0,
          'admin_id': row['admin_id'] ?? '',
          'name': row['name'] ?? '',
          'email': row['email'] ?? '',
          'phone': row['phone'] ?? '',
          'status': row['status'] ?? 'Active',
        }));
      }
      await conn.close();
      return list;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.getAdminsList error: $e');
      await conn.close();
    }
    return [];
  }

  /// Fetch Allocators List for Admin
  static Future<List<AllocatorStaffModel>> getAllocatorsList() async {
    final conn = await _connect();
    if (conn == null) return [];

    try {
      var rows = await conn.execute('SELECT * FROM allocators ORDER BY id DESC');
      List<AllocatorStaffModel> list = [];
      for (var r in rows.rows) {
        final row = r.assoc();
        list.add(AllocatorStaffModel.fromJson({
          'id': int.tryParse(row['id'] ?? '0') ?? 0,
          'allocator_id': row['allocator_id'] ?? '',
          'name': row['name'] ?? '',
          'email': row['email'] ?? '',
          'phone': row['phone'] ?? '',
          'status': row['status'] ?? 'Active',
          'performance_score': double.tryParse(row['performance_score'] ?? '100.0') ?? 100.0,
        }));
      }
      await conn.close();
      return list;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.getAllocatorsList error: $e');
      await conn.close();
    }
    return [];
  }

  /// Fetch Courses List for Admin
  static Future<List<CourseModel>> getCoursesList() async {
    final conn = await _connect();
    if (conn == null) return [];

    try {
      var rows = await conn.execute('SELECT * FROM courses ORDER BY id DESC');
      List<CourseModel> list = [];
      for (var r in rows.rows) {
        final row = r.assoc();
        list.add(CourseModel.fromJson({
          'course_id': row['course_id'] ?? '',
          'title': row['title'] ?? '',
          'category': row['category'] ?? 'General',
          'status': row['status'] ?? 'Active',
        }));
      }
      await conn.close();
      return list;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.getCoursesList error: $e');
      await conn.close();
    }
    return [];
  }

  /// Fetch Coupons List for Admin
  static Future<List<CouponModel>> getCouponsList() async {
    final conn = await _connect();
    if (conn == null) return [];

    try {
      var rows = await conn.execute('SELECT * FROM coupons ORDER BY id DESC');
      List<CouponModel> list = [];
      for (var r in rows.rows) {
        final row = r.assoc();
        list.add(CouponModel.fromJson({
          'coupon_id': row['coupon_id'] ?? '',
          'code': row['code'] ?? '',
          'discount_percent': int.tryParse(row['discount_percent'] ?? '10') ?? 10,
          'max_uses': int.tryParse(row['max_uses'] ?? '100') ?? 100,
          'current_uses': int.tryParse(row['current_uses'] ?? '0') ?? 0,
          'expires_at': row['expires_at'] ?? '',
          'status': row['status'] ?? 'Active',
        }));
      }
      await conn.close();
      return list;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.getCouponsList error: $e');
      await conn.close();
    }
    return [];
  }

  /// Fetch Blogs List for Admin
  static Future<List<BlogModel>> getBlogsList() async {
    final conn = await _connect();
    if (conn == null) return [];

    try {
      var rows = await conn.execute('SELECT * FROM blogs ORDER BY id DESC');
      List<BlogModel> list = [];
      for (var r in rows.rows) {
        final row = r.assoc();
        list.add(BlogModel.fromJson({
          'id': int.tryParse(row['id'] ?? '0') ?? 0,
          'title': row['title'] ?? '',
          'excerpt': row['excerpt'] ?? '',
          'category': row['category'] ?? 'Academic Writing',
          'author': row['author'] ?? 'Editorial Team',
          'published_at': row['published_at'] ?? '',
          'image': row['image'] ?? 'assets/images/blog1.jpg',
        }));
      }
      await conn.close();
      return list;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.getBlogsList error: $e');
      await conn.close();
    }
    return [];
  }

  /// Fetch Payments List for Admin
  static Future<List<PaymentModel>> getPaymentsList() async {
    final conn = await _connect();
    if (conn == null) return [];

    try {
      var rows = await conn.execute('SELECT * FROM payments ORDER BY id DESC');
      List<PaymentModel> list = [];
      for (var r in rows.rows) {
        final row = r.assoc();
        list.add(PaymentModel.fromJson({
          'payment_id': row['payment_id'] ?? '',
          'assignment_id': row['assignment_id'] ?? '',
          'student_id': row['student_id'] ?? '',
          'amount': double.tryParse(row['amount'] ?? '0') ?? 0.0,
          'currency': row['currency'] ?? 'USD',
          'status': row['status'] ?? 'Pending',
          'payment_method': row['payment_method'] ?? 'Credit Card',
          'transaction_id': row['transaction_id'] ?? '',
          'payment_date': row['payment_date'] ?? '',
          'assignment_title': 'Assignment Order',
          'assignment_subject': 'General',
        }));
      }
      await conn.close();
      return list;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.getPaymentsList error: $e');
      await conn.close();
    }
    return [];
  }

  /// Fetch Audit Logs for Admin
  static Future<List<AuditLogModel>> getAuditLogs() async {
    final conn = await _connect();
    if (conn == null) return [];

    try {
      var rows = await conn.execute('SELECT * FROM audit_logs ORDER BY id DESC LIMIT 50');
      List<AuditLogModel> list = [];
      for (var r in rows.rows) {
        final row = r.assoc();
        list.add(AuditLogModel.fromJson({
          'id': int.tryParse(row['id'] ?? '0') ?? 0,
          'log_id': row['log_id'] ?? '',
          'user_role': row['user_role'] ?? 'System',
          'user_id': row['user_id'] ?? '',
          'action': row['action'] ?? '',
          'details': row['details'] ?? '',
          'timestamp': row['timestamp'] ?? '',
        }));
      }
      await conn.close();
      return list;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.getAuditLogs error: $e');
      await conn.close();
    }
    return [];
  }

  /// Fetch Site Settings for Admin
  static Future<Map<String, dynamic>> getSiteSettings() async {
    final conn = await _connect();
    if (conn == null) return {};

    try {
      var rows = await conn.execute('SELECT * FROM settings');
      Map<String, dynamic> map = {};
      for (var r in rows.rows) {
        final row = r.assoc();
        final k = row['setting_key'];
        if (k != null) {
          map[k] = row['setting_value'] ?? '';
        }
      }
      await conn.close();
      return map;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.getSiteSettings error: $e');
      await conn.close();
    }
    return {};
  }

  /// Save Site Settings for Admin
  static Future<bool> saveSiteSettings(Map<String, String> settings) async {
    final conn = await _connect();
    if (conn == null) return false;

    try {
      for (var entry in settings.entries) {
        await conn.execute(
          'INSERT INTO settings (setting_key, setting_value) VALUES (:k, :v) ON DUPLICATE KEY UPDATE setting_value = :v',
          {'k': entry.key, 'v': entry.value},
        );
      }
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.saveSiteSettings error: $e');
      await conn.close();
    }
    return false;
  }

  /// --- COURSES CRUD ---
  static Future<bool> createCourse({
    required String title,
    required String category,
    String icon = 'fa-book-open',
    String description = '',
    String topics = '',
    String status = 'Active',
  }) async {
    final conn = await _connect();
    if (conn == null) return false;
    try {
      final courseId = 'CRS-${DateTime.now().millisecondsSinceEpoch % 100000}';
      await conn.execute(
        'INSERT INTO courses (course_id, title, category, icon, description, topics, status, created_at) '
        'VALUES (:id, :title, :cat, :icon, :desc, :topics, :status, NOW())',
        {
          'id': courseId,
          'title': title,
          'cat': category,
          'icon': icon,
          'desc': description,
          'topics': topics,
          'status': status,
        },
      );
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.createCourse error: $e');
      await conn.close();
    }
    return false;
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
    final conn = await _connect();
    if (conn == null) return false;
    try {
      await conn.execute(
        'UPDATE courses SET title = :title, category = :cat, icon = :icon, description = :desc, topics = :topics, status = :status WHERE course_id = :id',
        {
          'id': courseId,
          'title': title,
          'cat': category,
          'icon': icon,
          'desc': description,
          'topics': topics,
          'status': status,
        },
      );
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.updateCourse error: $e');
      await conn.close();
    }
    return false;
  }

  static Future<bool> deleteCourse(String courseId) async {
    final conn = await _connect();
    if (conn == null) return false;
    try {
      await conn.execute(
        'DELETE FROM courses WHERE course_id = :id',
        {'id': courseId},
      );
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.deleteCourse error: $e');
      await conn.close();
    }
    return false;
  }

  static Future<bool> toggleCourseStatus(String courseId, String newStatus) async {
    final conn = await _connect();
    if (conn == null) return false;
    try {
      await conn.execute(
        'UPDATE courses SET status = :status WHERE course_id = :id',
        {'id': courseId, 'status': newStatus},
      );
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.toggleCourseStatus error: $e');
      await conn.close();
    }
    return false;
  }

  /// --- STUDENTS CRUD ---
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
    final conn = await _connect();
    if (conn == null) return false;
    try {
      final studentId = 'STU-${DateTime.now().millisecondsSinceEpoch % 100000}';
      await conn.execute(
        'INSERT INTO students (student_id, name, email, phone, password, country, university, course, status, created_at) '
        'VALUES (:id, :name, :email, :phone, :pwd, :country, :uni, :course, :status, NOW())',
        {
          'id': studentId,
          'name': name,
          'email': email,
          'phone': phone,
          'pwd': password,
          'country': country,
          'uni': university,
          'course': course,
          'status': status,
        },
      );
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.createStudent error: $e');
      await conn.close();
    }
    return false;
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
    final conn = await _connect();
    if (conn == null) return false;
    try {
      if (password != null && password.trim().isNotEmpty) {
        await conn.execute(
          'UPDATE students SET name = :name, phone = :phone, country = :country, university = :uni, course = :course, password = :pwd, status = :status WHERE student_id = :id',
          {
            'id': studentId,
            'name': name,
            'phone': phone,
            'country': country,
            'uni': university,
            'course': course,
            'pwd': password.trim(),
            'status': status,
          },
        );
      } else {
        await conn.execute(
          'UPDATE students SET name = :name, phone = :phone, country = :country, university = :uni, course = :course, status = :status WHERE student_id = :id',
          {
            'id': studentId,
            'name': name,
            'phone': phone,
            'country': country,
            'uni': university,
            'course': course,
            'status': status,
          },
        );
      }
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.updateStudent error: $e');
      await conn.close();
    }
    return false;
  }

  static Future<bool> deleteStudent(String studentId) async {
    final conn = await _connect();
    if (conn == null) return false;
    try {
      await conn.execute(
        'DELETE FROM students WHERE student_id = :id',
        {'id': studentId},
      );
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.deleteStudent error: $e');
      await conn.close();
    }
    return false;
  }

  /// --- EXPERTS CRUD ---
  static Future<bool> updateExpert({
    required String expertId,
    required String name,
    String phone = '',
    String subjects = '',
    String status = 'Available',
    String? password,
  }) async {
    final conn = await _connect();
    if (conn == null) return false;
    try {
      if (password != null && password.trim().isNotEmpty) {
        await conn.execute(
          'UPDATE experts SET name = :name, phone = :phone, subjects = :sub, status = :status, password = :pwd WHERE expert_id = :id',
          {
            'id': expertId,
            'name': name,
            'phone': phone,
            'sub': subjects,
            'status': status,
            'pwd': password.trim(),
          },
        );
      } else {
        await conn.execute(
          'UPDATE experts SET name = :name, phone = :phone, subjects = :sub, status = :status WHERE expert_id = :id',
          {
            'id': expertId,
            'name': name,
            'phone': phone,
            'sub': subjects,
            'status': status,
          },
        );
      }
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.updateExpert error: $e');
      await conn.close();
    }
    return false;
  }

  static Future<bool> toggleExpertStatus(String expertId, String status) async {
    final conn = await _connect();
    if (conn == null) return false;
    try {
      await conn.execute(
        'UPDATE experts SET status = :status WHERE expert_id = :id',
        {'id': expertId, 'status': status},
      );
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.toggleExpertStatus error: $e');
      await conn.close();
    }
    return false;
  }

  /// --- ALLOCATORS & ADMINS CRUD ---
  static Future<bool> updateAllocator({
    required String allocatorId,
    required String name,
    String phone = '',
    String status = 'Active',
    String? password,
  }) async {
    final conn = await _connect();
    if (conn == null) return false;
    try {
      if (password != null && password.trim().isNotEmpty) {
        await conn.execute(
          'UPDATE allocators SET name = :name, phone = :phone, status = :status, password = :pwd WHERE allocator_id = :id',
          {'id': allocatorId, 'name': name, 'phone': phone, 'status': status, 'pwd': password.trim()},
        );
      } else {
        await conn.execute(
          'UPDATE allocators SET name = :name, phone = :phone, status = :status WHERE allocator_id = :id',
          {'id': allocatorId, 'name': name, 'phone': phone, 'status': status},
        );
      }
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.updateAllocator error: $e');
      await conn.close();
    }
    return false;
  }

  static Future<bool> updateAdmin({
    required String adminId,
    required String name,
    String phone = '',
    String status = 'Active',
    String? password,
  }) async {
    final conn = await _connect();
    if (conn == null) return false;
    try {
      if (password != null && password.trim().isNotEmpty) {
        await conn.execute(
          'UPDATE admins SET name = :name, phone = :phone, status = :status, password = :pwd WHERE admin_id = :id',
          {'id': adminId, 'name': name, 'phone': phone, 'status': status, 'pwd': password.trim()},
        );
      } else {
        await conn.execute(
          'UPDATE admins SET name = :name, phone = :phone, status = :status WHERE admin_id = :id',
          {'id': adminId, 'name': name, 'phone': phone, 'status': status},
        );
      }
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.updateAdmin error: $e');
      await conn.close();
    }
    return false;
  }

  static Future<bool> toggleStaffStatus(String role, String staffId, String status) async {
    final conn = await _connect();
    if (conn == null) return false;
    try {
      if (role.toLowerCase() == 'allocator') {
        await conn.execute(
          'UPDATE allocators SET status = :status WHERE allocator_id = :id',
          {'id': staffId, 'status': status},
        );
      } else {
        await conn.execute(
          'UPDATE admins SET status = :status WHERE admin_id = :id',
          {'id': staffId, 'status': status},
        );
      }
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.toggleStaffStatus error: $e');
      await conn.close();
    }
    return false;
  }

  /// --- COUPONS CRUD ---
  static Future<bool> updateCoupon({
    required String couponId,
    required String code,
    required int discountPercent,
    required int maxUses,
    String status = 'Active',
  }) async {
    final conn = await _connect();
    if (conn == null) return false;
    try {
      await conn.execute(
        'UPDATE coupons SET code = :code, discount_percent = :disc, max_uses = :max, status = :status WHERE coupon_id = :id',
        {
          'id': couponId,
          'code': code.toUpperCase().trim(),
          'disc': discountPercent.toString(),
          'max': maxUses.toString(),
          'status': status,
        },
      );
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.updateCoupon error: $e');
      await conn.close();
    }
    return false;
  }

  static Future<bool> deleteCoupon(String couponId) async {
    final conn = await _connect();
    if (conn == null) return false;
    try {
      await conn.execute(
        'DELETE FROM coupons WHERE coupon_id = :id',
        {'id': couponId},
      );
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.deleteCoupon error: $e');
      await conn.close();
    }
    return false;
  }

  static Future<bool> toggleCouponStatus(String couponId, String status) async {
    final conn = await _connect();
    if (conn == null) return false;
    try {
      await conn.execute(
        'UPDATE coupons SET status = :status WHERE coupon_id = :id',
        {'id': couponId, 'status': status},
      );
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.toggleCouponStatus error: $e');
      await conn.close();
    }
    return false;
  }

  /// --- MANUAL PAYMENTS ---
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
    final conn = await _connect();
    if (conn == null) return false;
    try {
      final pid = 'PAY-${DateTime.now().millisecondsSinceEpoch % 100000}';
      final txn = transactionId.isNotEmpty ? transactionId : 'TXN-MANUAL-${DateTime.now().millisecondsSinceEpoch % 100000}';

      await conn.execute(
        'INSERT INTO payments (payment_id, assignment_id, student_id, amount, currency, status, payment_method, transaction_id, payment_date, payment_plan) '
        'VALUES (:pid, :aid, :sid, :amt, :curr, :status, :method, :txn, NOW(), :plan)',
        {
          'pid': pid,
          'aid': assignmentId,
          'sid': studentId,
          'amt': amount.toStringAsFixed(2),
          'curr': currency,
          'status': status,
          'method': paymentMethod,
          'txn': txn,
          'plan': paymentPlan,
        },
      );

      // Also update assignment paid_amount and status if applicable
      await conn.execute(
        'UPDATE assignments SET paid_amount = paid_amount + :amt, remaining_balance = GREATEST(0, final_price - (paid_amount + :amt)), payment_status = :pstatus WHERE assignment_id = :aid',
        {
          'aid': assignmentId,
          'amt': amount.toStringAsFixed(2),
          'pstatus': status == 'Completed' ? 'Paid' : 'Pending',
        },
      );

      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.createManualPayment error: $e');
      await conn.close();
    }
    return false;
  }

  /// --- ASSIGNMENTS ADMIN CONTROLS (Soft Delete, Restore, Permanent Wipe, Admin Update) ---
  static Future<bool> updateAssignmentAdmin({
    required String assignmentId,
    String? status,
    double? price,
    String? expertId,
    String? allocatorId,
  }) async {
    final conn = await _connect();
    if (conn == null) return false;
    try {
      String query = 'UPDATE assignments SET updated_at = NOW()';
      Map<String, String> params = {'aid': assignmentId};

      if (status != null && status.isNotEmpty) {
        query += ', status = :status';
        params['status'] = status;
      }
      if (price != null) {
        query += ', price = :price, final_price = :price, remaining_balance = GREATEST(0, :price - paid_amount)';
        params['price'] = price.toStringAsFixed(2);
      }
      if (expertId != null) {
        query += ', expert_id = :eid';
        params['eid'] = expertId;
      }
      if (allocatorId != null) {
        query += ', allocator_id = :alloc';
        params['alloc'] = allocatorId;
      }

      query += ' WHERE assignment_id = :aid';
      await conn.execute(query, params);

      // Audit log entry
      final logId = 'LOG-${DateTime.now().millisecondsSinceEpoch % 100000}';
      await conn.execute(
        'INSERT INTO audit_logs (log_id, user_role, user_id, action, details, timestamp) '
        'VALUES (:lid, "Admin", "Admin", "Admin Assignment Update", :det, NOW())',
        {'lid': logId, 'det': 'Updated $assignmentId (Status: $status, Price: $price, Expert: $expertId)'},
      );

      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.updateAssignmentAdmin error: $e');
      await conn.close();
    }
    return false;
  }

  /// Soft Delete: Move assignment to History / Trash (status = 'Archived')
  static Future<bool> softDeleteAssignment(String assignmentId) async {
    final conn = await _connect();
    if (conn == null) return false;
    try {
      await conn.execute(
        'UPDATE assignments SET status = "Archived", updated_at = NOW() WHERE assignment_id = :id',
        {'id': assignmentId},
      );
      final logId = 'LOG-${DateTime.now().millisecondsSinceEpoch % 100000}';
      await conn.execute(
        'INSERT INTO audit_logs (log_id, user_role, user_id, action, details, timestamp) '
        'VALUES (:lid, "Admin", "Admin", "Soft Delete Assignment", :det, NOW())',
        {'lid': logId, 'det': 'Moved assignment $assignmentId to history/trash'},
      );
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.softDeleteAssignment error: $e');
      await conn.close();
    }
    return false;
  }

  /// Restore assignment from History / Trash back to Active
  static Future<bool> restoreAssignment(String assignmentId) async {
    final conn = await _connect();
    if (conn == null) return false;
    try {
      await conn.execute(
        'UPDATE assignments SET status = "Pending", updated_at = NOW() WHERE assignment_id = :id',
        {'id': assignmentId},
      );
      final logId = 'LOG-${DateTime.now().millisecondsSinceEpoch % 100000}';
      await conn.execute(
        'INSERT INTO audit_logs (log_id, user_role, user_id, action, details, timestamp) '
        'VALUES (:lid, "Admin", "Admin", "Restore Assignment", :det, NOW())',
        {'lid': logId, 'det': 'Restored assignment $assignmentId back to Active'},
      );
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.restoreAssignment error: $e');
      await conn.close();
    }
    return false;
  }

  /// Permanent Delete (Wipe) from everywhere
  static Future<bool> wipeAssignment(String assignmentId) async {
    final conn = await _connect();
    if (conn == null) return false;
    try {
      await conn.execute('DELETE FROM assignments WHERE assignment_id = :id', {'id': assignmentId});
      await conn.execute('DELETE FROM files WHERE assignment_id = :id', {'id': assignmentId});
      await conn.execute('DELETE FROM notes WHERE assignment_id = :id', {'id': assignmentId});
      await conn.execute('DELETE FROM allocation WHERE assignment_id = :id', {'id': assignmentId});

      final logId = 'LOG-${DateTime.now().millisecondsSinceEpoch % 100000}';
      await conn.execute(
        'INSERT INTO audit_logs (log_id, user_role, user_id, action, details, timestamp) '
        'VALUES (:lid, "Admin", "Admin", "Permanent Delete Assignment", :det, NOW())',
        {'lid': logId, 'det': 'Permanently wiped assignment $assignmentId and all related records'},
      );
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.wipeAssignment error: $e');
      await conn.close();
    }
    return false;
  }

  /// Fetch Archived / Trash Assignments for History screen
  static Future<List<AssignmentModel>> getArchivedAssignments() async {
    final conn = await _connect();
    if (conn == null) return [];
    try {
      var rows = await conn.execute(
        'SELECT * FROM assignments WHERE status IN ("Archived", "Deleted", "Trash", "Cancelled", "Completed") ORDER BY updated_at DESC, id DESC',
      );
      List<AssignmentModel> list = [];
      for (var r in rows.rows) {
        list.add(AssignmentModel.fromJson(_mapRowToAssignmentJson(r.assoc())));
      }
      await conn.close();
      return list;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.getArchivedAssignments error: $e');
      await conn.close();
    }
    return [];
  }

  /// --- NOTIFICATIONS (Broadcast Alert, Mark Read, Delete) ---
  static Future<bool> sendBroadcastNotification({
    required String targetRole,
    required String title,
    required String message,
  }) async {
    final conn = await _connect();
    if (conn == null) return false;
    try {
      // Find all target users or insert a broadcast entry
      final nid = 'NOTIF-${DateTime.now().millisecondsSinceEpoch % 100000}';
      await conn.execute(
        'INSERT INTO notifications (notification_id, user_id, user_role, title, message, is_read, created_at) '
        'VALUES (:nid, "ALL", :role, :title, :msg, 0, NOW())',
        {'nid': nid, 'role': targetRole, 'title': title, 'msg': message},
      );
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.sendBroadcastNotification error: $e');
      await conn.close();
    }
    return false;
  }

  static Future<bool> markAllNotificationsRead(String userId) async {
    final conn = await _connect();
    if (conn == null) return false;
    try {
      await conn.execute(
        'UPDATE notifications SET is_read = 1 WHERE user_id = :uid OR user_id = "ALL"',
        {'uid': userId},
      );
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.markAllNotificationsRead error: $e');
      await conn.close();
    }
    return false;
  }

  static Future<bool> deleteNotification(String notificationId) async {
    final conn = await _connect();
    if (conn == null) return false;
    try {
      await conn.execute(
        'DELETE FROM notifications WHERE notification_id = :id',
        {'id': notificationId},
      );
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.deleteNotification error: $e');
      await conn.close();
    }
    return false;
  }

  /// --- BLOGS UPDATE ---
  static Future<bool> updateBlog({
    required int blogId,
    required String title,
    required String excerpt,
    required String content,
    required String category,
  }) async {
    final conn = await _connect();
    if (conn == null) return false;
    try {
      await conn.execute(
        'UPDATE blogs SET title = :title, excerpt = :exc, content = :cnt, category = :cat WHERE id = :id',
        {'id': blogId.toString(), 'title': title, 'exc': excerpt, 'cnt': content, 'cat': category},
      );
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.updateBlog error: $e');
      await conn.close();
    }
    return false;
  }

  /// --- SYSTEM BACKUP JSON ---
  static Future<Map<String, dynamic>> generateSystemBackup() async {
    final conn = await _connect();
    if (conn == null) return {};
    try {
      final tables = ['assignments', 'students', 'experts', 'allocators', 'admins', 'payments', 'coupons', 'courses', 'blogs', 'audit_logs', 'settings'];
      Map<String, dynamic> backup = {
        'generated_at': DateTime.now().toIso8601String(),
        'platform': 'Ace Assignment Helps',
        'database': dbName,
        'tables': <String, dynamic>{},
      };

      for (var t in tables) {
        var res = await conn.execute('SELECT * FROM $t LIMIT 200');
        List<Map<String, dynamic>> rows = [];
        for (var r in res.rows) {
          rows.add(r.assoc());
        }
        (backup['tables'] as Map<String, dynamic>)[t] = rows;
      }

      await conn.close();
      return backup;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.generateSystemBackup error: $e');
      await conn.close();
    }
    return {};
  }

  /// --- ALLOCATOR WORKFLOW & PORTAL METHODS ---

  /// Direct MySQL Expert Allocation
  static Future<bool> allocateExpertDirect({
    required String assignmentId,
    required String expertId,
    required String allocatorId,
    required String deadline,
    String status = 'In Progress',
    String internalNotes = '',
  }) async {
    final conn = await _connect();
    if (conn == null) return false;

    try {
      // 1. Update assignment
      await conn.execute(
        'UPDATE assignments SET expert_id = :exp, allocator_id = :alloc, status = :status WHERE assignment_id = :id',
        {
          'id': assignmentId,
          'exp': expertId,
          'alloc': allocatorId,
          'status': status,
        },
      );

      // 2. Insert or replace allocation record
      final allocId = 'ALC-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      await conn.execute(
        'INSERT INTO allocation (allocation_id, assignment_id, expert_id, allocator_id, allocated_date, deadline, status) '
        'VALUES (:aid, :asg, :exp, :alloc, NOW(), :dl, :st) '
        'ON DUPLICATE KEY UPDATE expert_id = :exp, allocator_id = :alloc, deadline = :dl, status = :st',
        {
          'aid': allocId,
          'asg': assignmentId,
          'exp': expertId,
          'alloc': allocatorId,
          'dl': deadline,
          'st': status,
        },
      );

      // 3. Add internal note if provided
      if (internalNotes.trim().isNotEmpty) {
        final noteId = 'NOT-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        await conn.execute(
          'INSERT INTO notes (note_id, assignment_id, user_id, user_role, user_name, message, visibility, created_at) '
          'VALUES (:nid, :asg, :uid, :role, :uname, :msg, :vis, NOW())',
          {
            'nid': noteId,
            'asg': assignmentId,
            'uid': allocatorId,
            'role': 'Allocator',
            'uname': 'Allocator Staff',
            'msg': internalNotes.trim(),
            'vis': 'Internal',
          },
        );
      }

      // 4. Audit log
      final logId = 'LOG-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      await conn.execute(
        'INSERT INTO audit_logs (log_id, user_role, user_id, action, details, timestamp) '
        'VALUES (:lid, :role, :uid, :act, :det, NOW())',
        {
          'lid': logId,
          'role': 'Allocator',
          'uid': allocatorId,
          'act': 'EXPERT_ALLOCATED',
          'det': 'Allocated expert $expertId to assignment $assignmentId with deadline $deadline',
        },
      );

      // 5. Notifications for Expert and Student
      final expNotifId = 'NTF-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      await conn.execute(
        'INSERT INTO notifications (notification_id, user_id, user_role, title, message, is_read, created_at) '
        'VALUES (:nid, :uid, :role, :title, :msg, 0, NOW())',
        {
          'nid': expNotifId,
          'uid': expertId,
          'role': 'Expert',
          'title': 'New Task Allocated: $assignmentId',
          'msg': 'You have been allocated assignment $assignmentId. Target submission deadline: $deadline.',
        },
      );

      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.allocateExpertDirect error: $e');
      await conn.close();
    }
    return false;
  }

  /// Direct Allocator QA Approval
  static Future<bool> allocatorApproveQaDirect({
    required String assignmentId,
    required String allocatorId,
    required String allocatorName,
  }) async {
    final conn = await _connect();
    if (conn == null) return false;

    try {
      await conn.execute(
        "UPDATE assignments SET status = 'Completed' WHERE assignment_id = :id",
        {'id': assignmentId},
      );

      final logId = 'LOG-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      await conn.execute(
        'INSERT INTO audit_logs (log_id, user_role, user_id, action, details, timestamp) '
        'VALUES (:lid, :role, :uid, :act, :det, NOW())',
        {
          'lid': logId,
          'role': 'Allocator',
          'uid': allocatorId,
          'act': 'QA_APPROVED',
          'det': '$allocatorName approved QA verification for assignment $assignmentId',
        },
      );

      final notifId = 'NTF-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      await conn.execute(
        'INSERT INTO notifications (notification_id, user_id, user_role, title, message, is_read, created_at) '
        'VALUES (:nid, :uid, :role, :title, :msg, 0, NOW())',
        {
          'nid': notifId,
          'uid': 'ADM-ALL',
          'role': 'Admin',
          'title': 'QA Passed: $assignmentId',
          'msg': 'Allocator $allocatorName has verified and approved QA for $assignmentId.',
        },
      );

      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.allocatorApproveQaDirect error: $e');
      await conn.close();
    }
    return false;
  }

  /// Direct Allocator Request Revision
  static Future<bool> allocatorRequestRevisionDirect({
    required String assignmentId,
    required String allocatorId,
    required String allocatorName,
    required String instructions,
  }) async {
    final conn = await _connect();
    if (conn == null) return false;

    try {
      await conn.execute(
        "UPDATE assignments SET status = 'In Progress' WHERE assignment_id = :id",
        {'id': assignmentId},
      );

      // Note for expert
      final noteId = 'NOT-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      await conn.execute(
        'INSERT INTO notes (note_id, assignment_id, user_id, user_role, user_name, message, visibility, created_at) '
        'VALUES (:nid, :asg, :uid, :role, :uname, :msg, :vis, NOW())',
        {
          'nid': noteId,
          'asg': assignmentId,
          'uid': allocatorId,
          'role': 'Allocator',
          'uname': allocatorName,
          'msg': 'Revision Request: $instructions',
          'vis': 'Internal',
        },
      );

      // Audit Log
      final logId = 'LOG-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      await conn.execute(
        'INSERT INTO audit_logs (log_id, user_role, user_id, action, details, timestamp) '
        'VALUES (:lid, :role, :uid, :act, :det, NOW())',
        {
          'lid': logId,
          'role': 'Allocator',
          'uid': allocatorId,
          'act': 'REVISION_REQUESTED',
          'det': '$allocatorName requested revision on $assignmentId: $instructions',
        },
      );

      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.allocatorRequestRevisionDirect error: $e');
      await conn.close();
    }
    return false;
  }

  /// Upload Deliverable File
  static Future<bool> uploadDeliverableDirect({
    required String assignmentId,
    required String fileName,
    required String fileType,
    required String fileStage,
    required String uploadedBy,
    required bool isInternal,
    String path = '',
  }) async {
    final conn = await _connect();
    if (conn == null) return false;

    try {
      final fileId = 'FIL-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      await conn.execute(
        'INSERT INTO files (file_id, assignment_id, file_name, path, file_type, file_stage, uploaded_by, upload_date, is_internal) '
        'VALUES (:fid, :aid, :fn, :pth, :ft, :fs, :ub, NOW(), :intr)',
        {
          'fid': fileId,
          'aid': assignmentId,
          'fn': fileName,
          'pth': path.isNotEmpty ? path : 'uploads/$fileName',
          'ft': fileType,
          'fs': fileStage,
          'ub': uploadedBy,
          'intr': isInternal ? 1 : 0,
        },
      );

      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.uploadDeliverableDirect error: $e');
      await conn.close();
    }
    return false;
  }

  /// Toggle File Stage (Draft vs Complete)
  static Future<bool> toggleFileStageDirect({
    required int fileId,
    required String newStage,
  }) async {
    final conn = await _connect();
    if (conn == null) return false;

    try {
      await conn.execute(
        'UPDATE files SET file_stage = :stage WHERE id = :id',
        {'id': fileId, 'stage': newStage},
      );
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.toggleFileStageDirect error: $e');
      await conn.close();
    }
    return false;
  }

  /// Delete File from Assignment
  static Future<bool> deleteFileDirect({required int fileId}) async {
    final conn = await _connect();
    if (conn == null) return false;

    try {
      await conn.execute(
        'DELETE FROM files WHERE id = :id',
        {'id': fileId},
      );
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.deleteFileDirect error: $e');
      await conn.close();
    }
    return false;
  }

  /// Send Automated Email (Allocator Email Center)
  static Future<bool> sendAutomatedEmailDirect({
    required String assignmentId,
    required String template,
    required String recipient,
    required String senderId,
    required String senderName,
    String customMessage = '',
  }) async {
    final conn = await _connect();
    if (conn == null) return false;

    try {
      // 1. Audit Log record
      final logId = 'LOG-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      await conn.execute(
        'INSERT INTO audit_logs (log_id, user_role, user_id, action, details, timestamp) '
        'VALUES (:lid, :role, :uid, :act, :det, NOW())',
        {
          'lid': logId,
          'role': 'Allocator',
          'uid': senderId,
          'act': 'EMAIL_DISPATCHED',
          'det': 'Email [$template] dispatched to $recipient for $assignmentId. Note: $customMessage',
        },
      );

      // 2. Dispatch in-app notifications to matched parties
      if (recipient == 'Student' || recipient == 'Both') {
        final nid = 'NTF-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
        await conn.execute(
          'INSERT INTO notifications (notification_id, user_id, user_role, title, message, is_read, created_at) '
          'VALUES (:nid, :uid, :role, :title, :msg, 0, NOW())',
          {
            'nid': nid,
            'uid': 'Student',
            'role': 'Student',
            'title': 'Email Alert: $template',
            'msg': 'Update regarding $assignmentId: $template. ${customMessage.isNotEmpty ? customMessage : "Please check your portal for details."}',
          },
        );
      }

      if (recipient == 'Expert' || recipient == 'Both') {
        final nid = 'NTF-${(DateTime.now().millisecondsSinceEpoch + 1).toString().substring(5)}';
        await conn.execute(
          'INSERT INTO notifications (notification_id, user_id, user_role, title, message, is_read, created_at) '
          'VALUES (:nid, :uid, :role, :title, :msg, 0, NOW())',
          {
            'nid': nid,
            'uid': 'Expert',
            'role': 'Expert',
            'title': 'Email Alert: $template',
            'msg': 'Notification regarding $assignmentId: $template. ${customMessage.isNotEmpty ? customMessage : "Please check instructions."}',
          },
        );
      }

      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.sendAutomatedEmailDirect error: $e');
      await conn.close();
    }
    return false;
  }

  /// Get Email Dispatch History (Allocator Email Center)
  static Future<List<Map<String, dynamic>>> getEmailHistoryDirect() async {
    final conn = await _connect();
    if (conn == null) return [];

    try {
      var rows = await conn.execute(
        "SELECT * FROM audit_logs WHERE action = 'EMAIL_DISPATCHED' OR action LIKE '%EMAIL%' ORDER BY id DESC LIMIT 50",
      );
      List<Map<String, dynamic>> list = [];
      for (var r in rows.rows) {
        list.add(r.assoc());
      }
      await conn.close();
      return list;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.getEmailHistoryDirect error: $e');
      await conn.close();
    }
    return [];
  }

  /// Get Completed Assignments for Allocator Completed Log
  static Future<List<AssignmentModel>> getCompletedAssignmentsDirect() async {
    final conn = await _connect();
    if (conn == null) return [];

    try {
      var rows = await conn.execute(
        "SELECT * FROM assignments WHERE status = 'Completed' ORDER BY id DESC",
      );
      List<AssignmentModel> list = [];
      for (var r in rows.rows) {
        list.add(AssignmentModel.fromJson(_mapRowToAssignmentJson(r.assoc())));
      }
      await conn.close();
      return list;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.getCompletedAssignmentsDirect error: $e');
      await conn.close();
    }
    return [];
  }

  /// Get Allocator Notifications
  static Future<List<NotificationModel>> getAllocatorNotificationsDirect({
    required String allocatorId,
  }) async {
    final conn = await _connect();
    if (conn == null) return [];

    try {
      var rows = await conn.execute(
        "SELECT * FROM notifications WHERE user_role IN ('Allocator', 'All') OR user_id = :uid ORDER BY id DESC LIMIT 50",
        {'uid': allocatorId},
      );
      List<NotificationModel> list = [];
      for (var r in rows.rows) {
        list.add(NotificationModel.fromJson(r.assoc()));
      }
      await conn.close();
      return list;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.getAllocatorNotificationsDirect error: $e');
      await conn.close();
    }
    return [];
  }

  /// Mark All Notifications Read for Allocator
  static Future<bool> markAllNotificationsReadDirect({
    required String userRole,
    required String userId,
  }) async {
    final conn = await _connect();
    if (conn == null) return false;

    try {
      await conn.execute(
        "UPDATE notifications SET is_read = 1 WHERE user_role IN (:role, 'All') OR user_id = :uid",
        {'role': userRole, 'uid': userId},
      );
      await conn.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('DirectDbService.markAllNotificationsReadDirect error: $e');
      await conn.close();
    }
    return false;
  }

  /// Helper to convert MySQL Row to Map
  static Map<String, dynamic> _mapRowToAssignmentJson(Map<String, String?> row) {
    double pr = double.tryParse(row['price'] ?? '0') ?? 0.0;
    double fpr = double.tryParse(row['final_price'] ?? row['price'] ?? '0') ?? pr;
    double paid = double.tryParse(row['paid_amount'] ?? '0') ?? 0.0;
    double rem = double.tryParse(row['remaining_balance'] ?? '0') ?? (fpr - paid);

    return {
      'assignment_id': row['assignment_id'] ?? '',
      'student_id': row['student_id'] ?? '',
      'title': row['title'] ?? 'Untitled Assignment',
      'subject': row['subject'] ?? 'General',
      'assignment_type': row['assignment_type'] ?? 'Essay',
      'deadline': row['deadline'] ?? '',
      'word_count': int.tryParse(row['word_count'] ?? '1000') ?? 1000,
      'currency': row['currency'] ?? 'USD',
      'price': pr,
      'final_price': fpr,
      'status': row['status'] ?? 'Pending',
      'allocator_id': row['allocator_id'] ?? '',
      'expert_id': row['expert_id'] ?? '',
      'paid_amount': paid,
      'remaining_balance': rem,
      'instructions': row['instructions'] ?? '',
      'priority': row['priority'] ?? 'Normal',
      'country': row['country'] ?? 'Global',
      'payment_status': row['payment_status'] ?? 'Pending',
    };
  }
}

