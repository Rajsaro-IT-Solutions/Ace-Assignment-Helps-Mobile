import 'package:flutter/material.dart';
import '../../core/models/dashboard_stats_model.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../common/assignment_detail_sheet.dart';

class StudentNotificationsScreen extends StatefulWidget {
  final UserModel user;

  const StudentNotificationsScreen({super.key, required this.user});

  @override
  State<StudentNotificationsScreen> createState() => _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen> {
  bool _loading = true;
  List<NotificationModel> _notifications = [];
  String _filter = 'All'; // All, Unread, Read
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _loading = true);
    final list = await ApiService.getStudentNotifications(studentId: widget.user.id);
    if (mounted) {
      setState(() {
        _notifications = list;
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    final ok = await ApiService.markAllStudentNotificationsRead(studentId: widget.user.id);
    if (ok) {
      _fetchNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read.'), backgroundColor: AppTheme.success),
        );
      }
    }
  }

  Future<void> _deleteNotification(String id) async {
    final ok = await ApiService.deleteNotification(id);
    if (ok) {
      setState(() {
        _notifications.removeWhere((n) => n.id == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification dismissed.'), backgroundColor: AppTheme.success),
        );
      }
    }
  }

  String? _extractAssignmentId(String text) {
    final exp = RegExp(r'(ORD-[A-Za-z0-9-]+|AAH-[A-Za-z0-9-]+)');
    final match = exp.firstMatch(text);
    return match?.group(0);
  }

  void _navigateToOrder(String assignmentId) async {
    setState(() => _loading = true);
    final assignments = await ApiService.getAssignments(
      role: 'Student',
      userId: widget.user.id,
      search: assignmentId,
    );
    setState(() => _loading = false);

    if (mounted) {
      if (assignments.isNotEmpty) {
        AssignmentDetailSheet.show(
          context,
          assignment: assignments.first,
          currentUser: widget.user,
          onStatusChanged: _fetchNotifications,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order $assignmentId not found or archived.')),
        );
      }
    }
  }

  List<NotificationModel> get _filteredList {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _notifications.where((n) {
      if (_filter == 'Unread' && n.isRead) return false;
      if (_filter == 'Read' && !n.isRead) return false;
      if (q.isNotEmpty) {
        return n.title.toLowerCase().contains(q) || n.message.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  IconData _getIconForNotification(String title, String message) {
    final t = '${title.toLowerCase()} ${message.toLowerCase()}';
    if (t.contains('payment') || t.contains('invoice') || t.contains('deposit') || t.contains('balance')) {
      return Icons.payment_rounded;
    }
    if (t.contains('refund') || t.contains('cancel')) {
      return Icons.currency_exchange_rounded;
    }
    if (t.contains('allocat') || t.contains('expert')) {
      return Icons.assignment_ind_rounded;
    }
    if (t.contains('complete') || t.contains('deliver') || t.contains('draft')) {
      return Icons.task_alt_rounded;
    }
    if (t.contains('message') || t.contains('chat') || t.contains('ticket')) {
      return Icons.chat_bubble_outline_rounded;
    }
    return Icons.notifications_active_outlined;
  }

  Color _getColorForNotification(String title, String message) {
    final t = '${title.toLowerCase()} ${message.toLowerCase()}';
    if (t.contains('payment') || t.contains('complete') || t.contains('deliver')) {
      return AppTheme.success;
    }
    if (t.contains('refund') || t.contains('cancel')) {
      return AppTheme.danger;
    }
    if (t.contains('allocat') || t.contains('expert')) {
      return AppTheme.info;
    }
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('Notifications (${_notifications.length})'),
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'Mark All as Read',
              onPressed: _markAllRead,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surface,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search notification alerts...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFilterChip('All', _notifications.length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Unread', unreadCount),
                    const SizedBox(width: 8),
                    _buildFilterChip('Read', _notifications.length - unreadCount),
                  ],
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _filter == 'Unread' ? Icons.mark_email_read_rounded : Icons.notifications_none_rounded,
                              size: 48,
                              color: AppTheme.textDim,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _filter == 'Unread' ? 'No unread notifications' : 'No notifications found',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchCtrl.text.isNotEmpty
                                  ? 'Try adjusting your search keywords.'
                                  : 'Assignment updates and system alerts will appear here.',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchNotifications,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final n = _filteredList[i];
                            final icon = _getIconForNotification(n.title, n.message);
                            final color = _getColorForNotification(n.title, n.message);
                            final orderId = _extractAssignmentId('${n.title} ${n.message}');

                            return Dismissible(
                              key: Key(n.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: AppTheme.danger,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
                              ),
                              onDismissed: (_) => _deleteNotification(n.id),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: n.isRead ? AppTheme.surface : AppTheme.primaryLight.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: n.isRead ? AppTheme.border : AppTheme.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(icon, size: 20, color: color),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      n.title,
                                                      style: TextStyle(
                                                        fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                                                        fontSize: 14,
                                                        color: AppTheme.textMain,
                                                      ),
                                                    ),
                                                  ),
                                                  if (!n.isRead)
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: const BoxDecoration(
                                                        color: AppTheme.primary,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                n.message,
                                                style: const TextStyle(fontSize: 13, color: AppTheme.textDim, height: 1.35),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    n.createdAt.isNotEmpty ? n.createdAt : 'Recent',
                                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                                  ),
                                                  Row(
                                                    children: [
                                                      if (orderId != null)
                                                        TextButton.icon(
                                                          style: TextButton.styleFrom(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                            minimumSize: Size.zero,
                                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                          ),
                                                          icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                                                          label: Text(
                                                            'Track Order $orderId',
                                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                          ),
                                                          onPressed: () => _navigateToOrder(orderId),
                                                        ),
                                                      IconButton(
                                                        icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textDim),
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                        tooltip: 'Dismiss',
                                                        onPressed: () => _deleteNotification(n.id),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final selected = _filter == label;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: selected,
      onSelected: (_) => setState(() => _filter = label),
    );
  }
}
