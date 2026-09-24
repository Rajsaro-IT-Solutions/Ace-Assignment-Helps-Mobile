import 'package:flutter/material.dart';
import '../../core/models/dashboard_stats_model.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminNotificationsScreen extends StatefulWidget {
  final UserModel user;

  const AdminNotificationsScreen({super.key, required this.user});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  bool _loading = true;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _loading = true);
    final list = await ApiService.getNotifications(
      role: 'Admin',
      userId: widget.user.id,
    );
    if (mounted) {
      setState(() {
        _notifications = list;
        _loading = false;
      });
    }
  }

  void _showBroadcastDialog() {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    String selectedRole = 'ALL';
    bool sending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.campaign_rounded, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Broadcast Alert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Target Audience', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.group_outlined)),
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('All Platform Users')),
                    DropdownMenuItem(value: 'Student', child: Text('All Registered Students')),
                    DropdownMenuItem(value: 'Expert', child: Text('All Academic Experts')),
                    DropdownMenuItem(value: 'Allocator', child: Text('Staff Allocators')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedRole = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Alert Headline / Title *',
                    hintText: 'e.g. Scheduled Maintenance Notice',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: msgCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Broadcast Content *',
                    hintText: 'Write the announcement message...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: sending
                  ? null
                  : () async {
                      final title = titleCtrl.text.trim();
                      final msg = msgCtrl.text.trim();
                      if (title.isEmpty || msg.isEmpty) return;

                      setDlgState(() => sending = true);
                      final ok = await ApiService.sendBroadcastNotification(
                        targetRole: selectedRole,
                        title: title,
                        message: msg,
                      );

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (ok) {
                        _fetchNotifications();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Broadcast notification dispatched!'), backgroundColor: AppTheme.success),
                          );
                        }
                      }
                    },
              child: sending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Dispatch Alert'),
            ),
          ],
        ),
      ),
    );
  }

  void _markAllRead() async {
    final ok = await ApiService.markAllNotificationsRead(widget.user.id);
    if (mounted && ok) {
      _fetchNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All marked as read'), backgroundColor: AppTheme.success),
      );
    }
  }

  void _deleteNotification(String id) async {
    final ok = await ApiService.deleteNotification(id);
    if (mounted && ok) {
      _fetchNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Platform Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read_outlined),
            tooltip: 'Mark all as read',
            onPressed: _markAllRead,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showBroadcastDialog,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.campaign_rounded, color: Colors.white),
        label: const Text('Broadcast Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 54, color: AppTheme.textDim),
                      SizedBox(height: 12),
                      Text('No notifications present', style: TextStyle(color: AppTheme.textMuted)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final n = _notifications[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: n.isRead ? Colors.white : AppTheme.primaryLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: n.isRead ? AppTheme.border : AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: n.isRead ? AppTheme.bg : AppTheme.primary,
                            child: Icon(Icons.notifications_active_rounded, size: 18, color: n.isRead ? AppTheme.textDim : Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text(n.message, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                                const SizedBox(height: 6),
                                Text(n.createdAt, style: const TextStyle(fontSize: 10, color: AppTheme.textDim)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textDim),
                            onPressed: () => _deleteNotification(n.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
