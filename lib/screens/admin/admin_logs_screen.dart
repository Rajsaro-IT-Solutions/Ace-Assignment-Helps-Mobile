import 'package:flutter/material.dart';
import '../../core/models/portal_models.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminLogsScreen extends StatefulWidget {
  final UserModel user;

  const AdminLogsScreen({super.key, required this.user});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  bool _loading = true;
  List<AuditLogModel> _logs = [];
  List<AuditLogModel> _filtered = [];
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    setState(() => _loading = true);
    final list = await ApiService.getAuditLogs();
    if (mounted) {
      setState(() {
        _logs = list;
        _applyFilter(_searchCtrl.text);
        _loading = false;
      });
    }
  }

  void _applyFilter(String q) {
    final query = q.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() => _filtered = _logs);
    } else {
      setState(() {
        _filtered = _logs.where((l) {
          return l.action.toLowerCase().contains(query) ||
              l.userRole.toLowerCase().contains(query) ||
              l.userId.toLowerCase().contains(query) ||
              l.details.toLowerCase().contains(query);
        }).toList();
      });
    }
  }

  Color _getActionColor(String action) {
    final a = action.toLowerCase();
    if (a.contains('delete') || a.contains('refund') || a.contains('block')) return AppTheme.danger;
    if (a.contains('release') || a.contains('create') || a.contains('approve') || a.contains('login')) return AppTheme.success;
    if (a.contains('revision') || a.contains('update')) return AppTheme.warning;
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('System Audit Trail & Logs'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchLogs),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchCtrl,
              onChanged: _applyFilter,
              decoration: InputDecoration(
                hintText: 'Search audit action, user or order ID...',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history_toggle_off_rounded, size: 54, color: AppTheme.textDim),
                            const SizedBox(height: 12),
                            const Text('No audit events found', style: TextStyle(color: AppTheme.textMuted)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) {
                          final log = _filtered[i];
                          final actionColor = _getActionColor(log.action);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: actionColor.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.security_rounded, color: actionColor, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text('${log.userRole} (${log.userId})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            const Spacer(),
                                            Text(
                                              log.timestamp.length >= 16 ? log.timestamp.substring(5, 16) : log.timestamp,
                                              style: const TextStyle(fontSize: 11, color: AppTheme.textDim),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: actionColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            log.action,
                                            style: TextStyle(color: actionColor, fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(log.details, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
