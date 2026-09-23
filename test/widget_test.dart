import 'package:flutter_test/flutter_test.dart';
import 'package:aah_portal/core/models/user_model.dart';
import 'package:aah_portal/core/models/assignment_model.dart';

void main() {
  test('UserModel parses from JSON correctly', () {
    final json = {
      'id': 'STU-1001',
      'name': 'Gokul Marwal',
      'email': 'gokulmarwal1627@gmail.com',
      'role': 'Student',
      'phone': '+91 8233432123',
      'country': 'United Kingdom'
    };

    final user = UserModel.fromJson(json);

    expect(user.id, 'STU-1001');
    expect(user.name, 'Gokul Marwal');
    expect(user.email, 'gokulmarwal1627@gmail.com');
    expect(user.role, 'Student');
    expect(user.isStudent, true);
    expect(user.isAdmin, false);
  });

  test('AssignmentModel parses from JSON correctly', () {
    final json = {
      'assignment_id': 'ACE-2026-000101',
      'student_id': 'STU-1001',
      'title': 'Data Science Dissertation',
      'subject': 'Data Science & Applied Statistics',
      'assignment_type': 'Dissertation',
      'deadline': '2026-09-28 05:14:55',
      'word_count': 2000,
      'currency': 'INR',
      'price': 2000.0,
      'final_price': 1600.0,
      'status': 'Completed',
      'allocator_id': 'ALL-501',
      'expert_id': 'EXP-304',
      'paid_amount': 320.0,
      'remaining_balance': 1280.0,
    };

    final a = AssignmentModel.fromJson(json);

    expect(a.assignmentId, 'ACE-2026-000101');
    expect(a.studentId, 'STU-1001');
    expect(a.wordCount, 2000);
    expect(a.finalPrice, 1600.0);
    expect(a.status, 'Completed');
  });
}
