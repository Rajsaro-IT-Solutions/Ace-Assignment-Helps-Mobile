import 'package:flutter/material.dart';
import '../core/models/assignment_model.dart';
import '../core/theme/app_theme.dart';

class AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final VoidCallback? onTap;

  const AssignmentCard({
    super.key,
    required this.assignment,
    this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.success;
      case 'in progress':
        return AppTheme.primary;
      case 'under qa':
      case 'under review':
      case 'revision':
        return AppTheme.warning;
      case 'cancelled':
        return AppTheme.danger;
      default:
        return AppTheme.secondary;
    }
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.successBg;
      case 'in progress':
        return AppTheme.primaryLight;
      case 'under qa':
      case 'under review':
      case 'revision':
        return AppTheme.warningBg;
      case 'cancelled':
        return AppTheme.dangerBg;
      default:
        return AppTheme.secondaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(assignment.status);
    final statusBg = _getStatusBg(assignment.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Assignment ID and Status Badge
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
                    assignment.assignmentId,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        assignment.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Subject Tag
            Text(
              assignment.subject.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.secondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),

            // Title
            Text(
              assignment.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMain,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            const Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 12),

            // Metadata Row: Word count & Deadline
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description_outlined, size: 16, color: AppTheme.textDim),
                    const SizedBox(width: 5),
                    Text(
                      '${assignment.wordCount} words',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                    ),
                  ],
                ),
                if (assignment.deadline.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textDim),
                      const SizedBox(width: 5),
                      Text(
                        assignment.deadline.split(' ').first,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted,
                            ),
                      ),
                    ],
                  ),
                Text(
                  '${assignment.currency} ${assignment.finalPrice > 0 ? assignment.finalPrice.toStringAsFixed(0) : assignment.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMain,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
