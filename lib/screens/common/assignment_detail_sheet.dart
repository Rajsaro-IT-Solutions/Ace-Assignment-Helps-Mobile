import 'package:flutter/material.dart';
import '../../core/models/assignment_model.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class AssignmentDetailSheet extends StatefulWidget {
  final AssignmentModel assignment;
  final UserModel currentUser;
  final VoidCallback? onStatusChanged;

  const AssignmentDetailSheet({
    super.key,
    required this.assignment,
    required this.currentUser,
    this.onStatusChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required AssignmentModel assignment,
    required UserModel currentUser,
    VoidCallback? onStatusChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AssignmentDetailSheet(
        assignment: assignment,
        currentUser: currentUser,
        onStatusChanged: onStatusChanged,
      ),
    );
  }

  @override
  State<AssignmentDetailSheet> createState() => _AssignmentDetailSheetState();
}

class _AssignmentDetailSheetState extends State<AssignmentDetailSheet> {
  Map<String, dynamic>? _detailData;
  bool _updatingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final data = await ApiService.getAssignmentDetail(widget.assignment.assignmentId);
    if (mounted) {
      setState(() {
        _detailData = data;
      });
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    setState(() => _updatingStatus = true);
    final success = await ApiService.updateStatus(
      assignmentId: widget.assignment.assignmentId,
      status: newStatus,
      userId: widget.currentUser.id,
      role: widget.currentUser.role,
    );
    if (mounted) {
      setState(() => _updatingStatus = false);
      if (success) {
        Navigator.of(context).pop();
        widget.onStatusChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    final isStaff = widget.currentUser.isAdmin || widget.currentUser.isAllocator || widget.currentUser.isExpert;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top Header: ID & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    a.assignmentId,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                Text(
                  a.status,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title & Subject
            Text(
              a.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textMain),
            ),
            const SizedBox(height: 4),
            Text(
              '${a.subject} • ${a.assignmentType}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.secondary),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.border),
            const SizedBox(height: 12),

            // Key Specs Grid
            Row(
              children: [
                _buildSpecTile('Word Count', '${a.wordCount} words', Icons.text_snippet_outlined),
                _buildSpecTile('Deadline', a.deadline.split(' ').first, Icons.calendar_today_rounded),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSpecTile('Total Price', '${a.currency} ${a.finalPrice > 0 ? a.finalPrice : a.price}', Icons.payments_outlined),
                _buildSpecTile('Paid', '${a.currency} ${a.paidAmount}', Icons.check_circle_outline),
              ],
            ),
            const SizedBox(height: 16),

            // Instructions
            if (a.instructions.isNotEmpty) ...[
              const Text(
                'Instructions & Guidelines',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textMain),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  a.instructions,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Allocation Info
            if (_detailData != null && _detailData!['allocation'] != null) ...[
              const Text(
                'Assigned Expert',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textMain),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppTheme.primaryLight,
                      child: Icon(Icons.person, color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _detailData!['allocation']['expert_name'] ?? 'Assigned Expert',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          _detailData!['allocation']['expert_email'] ?? '',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textDim),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Staff Actions (Update Status)
            if (isStaff) ...[
              const Text(
                'Update Status',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textMain),
              ),
              const SizedBox(height: 10),
              if (_updatingStatus)
                const Center(child: CircularProgressIndicator())
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusButton('In Progress', AppTheme.primary),
                    _buildStatusButton('Under QA', AppTheme.warning),
                    _buildStatusButton('Completed', AppTheme.success),
                  ],
                ),
              const SizedBox(height: 16),
            ],

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.slateDark,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecTile(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(String status, Color color) {
    final isCurrent = widget.assignment.status.toLowerCase() == status.toLowerCase();
    return OutlinedButton(
      onPressed: isCurrent ? null : () => _changeStatus(status),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: isCurrent ? 2 : 1),
        backgroundColor: isCurrent ? color.withValues(alpha: 0.1) : null,
      ),
      child: Text(isCurrent ? '✓ $status' : status),
    );
  }
}
