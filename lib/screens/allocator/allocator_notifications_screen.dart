import 'package:flutter/material.dart';
import '../../core/models/dashboard_stats_model.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class AllocatorNotificationsScreen extends StatefulWidget {
  final UserModel user;

  const AllocatorNotificationsScreen({super.key, required this.user});

  @override
  State<AllocatorNotificationsScreen> createState() => _AllocatorNotificationsScreenState();
}

class _AllocatorNotificationsScreenState extends State<AllocatorNotificationsScreen> {
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
    final list = await ApiService.getAllocatorNotifications(allocatorId: widget.user.id);
    if (mounted) {
      setState(() {
        _notifications = list;
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    final ok = await ApiService.markAllAllocatorNotificationsRead(allocatorId: widget.user.id);
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
          const SnackBar(content: Text('Notification removed.'), backgroundColor: AppTheme.success),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: Column(
                children: [
                  // Filter and Search Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search notification alerts...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor: AppTheme.bg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.border),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: ['All', 'Unread', 'Read'].map((f) {
                            final isSel = _filter == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(f == 'Unread' ? 'Unread ($unreadCount)' : f),
                                selected: isSel,
                                selectedColor: AppTheme.primary,
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.white : AppTheme.textMain,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                                onSelected: (_) => setState(() => _filter = f),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Notifications List
                  Expanded(
                    child: _filteredList.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_off_outlined, size: 48, color: AppTheme.textDim),
                                SizedBox(height: 12),
                                Text('No notifications in this filter', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              final n = _filteredList[i];
                              return Dismissible(
                                key: Key(n.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: AppTheme.danger,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                                ),
                                onDismissed: (_) => _deleteNotification(n.id),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: n.isRead ? AppTheme.surface : Colors.blue.shade50.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: n.isRead ? AppTheme.border : AppTheme.primary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: n.isRead ? Colors.grey.shade100 : AppTheme.primaryLight,
                                      child: Icon(
                                        n.isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                                        color: n.isRead ? AppTheme.textDim : AppTheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n.title,
                                            style: TextStyle(
                                              fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                                              fontSize: 14,
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
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(n.message, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.3)),
                                        const SizedBox(height: 6),
                                        Text(n.createdAt, style: const TextStyle(fontSize: 10, color: AppTheme.textDim)),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textDim),
                                      onPressed: () => _deleteNotification(n.id),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
