import 'package:flutter/material.dart';
import '../../core/models/assignment_model.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../common/assignment_detail_sheet.dart';

class AdminHistoryScreen extends StatefulWidget {
  final UserModel user;

  const AdminHistoryScreen({super.key, required this.user});

  @override
  State<AdminHistoryScreen> createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends State<AdminHistoryScreen> {
  bool _loading = true;
  List<AssignmentModel> _historyList = [];
  final _searchCtrl = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    setState(() => _loading = true);
    final list = await ApiService.getArchivedAssignments();
    if (mounted) {
      setState(() {
        _historyList = list;
        _loading = false;
      });
    }
  }

  int get _softDeletedCount =>
      _historyList.where((a) => a.status.toLowerCase() == 'archived' || a.status.toLowerCase() == 'deleted' || a.status.toLowerCase() == 'trash').length;

  int get _completedCount =>
      _historyList.where((a) => a.status.toLowerCase().contains('complete') || a.status.toLowerCase().contains('delivered')).length;

  int get _cancelledCount =>
      _historyList.where((a) => a.status.toLowerCase().contains('cancel') || a.status.toLowerCase().contains('refund')).length;

  List<AssignmentModel> get _filteredList {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _historyList.where((a) {
      final matchesQuery = q.isEmpty ||
          a.assignmentId.toLowerCase().contains(q) ||
          a.title.toLowerCase().contains(q) ||
          a.studentId.toLowerCase().contains(q) ||
          a.subject.toLowerCase().contains(q);

      final s = a.status.toLowerCase();
      bool matchesStatus = true;
      if (_selectedFilter == 'Trash') {
        matchesStatus = s == 'archived' || s == 'deleted' || s == 'trash';
      } else if (_selectedFilter == 'Completed') {
        matchesStatus = s.contains('complete') || s.contains('delivered');
      } else if (_selectedFilter == 'Cancelled') {
        matchesStatus = s.contains('cancel') || s.contains('refund');
      }

      return matchesQuery && matchesStatus;
    }).toList();
  }

  void _confirmRestore(AssignmentModel a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Assignment'),
        content: Text('Restore assignment ${a.assignmentId} from history back to Active (Pending Review)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Restore Order'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await ApiService.restoreAssignment(a.assignmentId);
    if (mounted) {
      if (ok) {
        _fetchHistory();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Assignment ${a.assignmentId} restored to active orders!'), backgroundColor: AppTheme.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to restore assignment.'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  void _confirmWipe(AssignmentModel a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.danger),
            SizedBox(width: 8),
            Text('Permanently Wipe Everywhere'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to completely erase assignment:'),
            const SizedBox(height: 6),
            Text(a.assignmentId, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.danger, fontSize: 16)),
            const SizedBox(height: 10),
            const Text(
              'IRREVERSIBLE ACTION: This will completely delete the order record, student files, allocations, and chat history permanently.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Yes, Permanently Wipe'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await ApiService.wipeAssignment(a.assignmentId);
    if (mounted) {
      if (ok) {
        _fetchHistory();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Assignment ${a.assignmentId} permanently wiped.'), backgroundColor: AppTheme.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to wipe assignment.'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Assignment History & Trash'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchHistory),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchHistory,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Metrics Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard('Total Archived', '${_historyList.length}', Icons.inventory_2_outlined, AppTheme.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard('In Trash', '$_softDeletedCount', Icons.delete_sweep_rounded, AppTheme.warning),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard('Completed', '$_completedCount', Icons.check_circle_outline_rounded, AppTheme.success),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard('Cancelled', '$_cancelledCount', Icons.cancel_outlined, AppTheme.danger),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search & Filters
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search by ID, title, student, or subject...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () => setState(() => _searchCtrl.clear()))
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Text('Filter:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                        const SizedBox(width: 8),
                        Wrap(
                          spacing: 6,
                          children: ['All', 'Trash', 'Completed', 'Cancelled'].map((f) {
                            final isSel = _selectedFilter == f;
                            return ChoiceChip(
                              label: Text(f, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : AppTheme.textMain)),
                              selected: isSel,
                              selectedColor: AppTheme.primary,
                              onSelected: (_) => setState(() => _selectedFilter = f),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Historical Orders & Trash (${_filteredList.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                    const SizedBox(height: 12),

                    if (_filteredList.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(36),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.history_toggle_off_rounded, size: 48, color: AppTheme.textDim),
                            SizedBox(height: 12),
                            Text('No archived or deleted records found', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final a = _filteredList[i];
                          final isTrash = a.status.toLowerCase() == 'archived' ||
                              a.status.toLowerCase() == 'deleted' ||
                              a.status.toLowerCase() == 'trash';

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      a.assignmentId,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.primary),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isTrash
                                            ? AppTheme.warning.withValues(alpha: 0.15)
                                            : a.status.toLowerCase().contains('complete')
                                                ? AppTheme.successBg
                                                : AppTheme.dangerBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        a.status,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isTrash
                                              ? AppTheme.warning
                                              : a.status.toLowerCase().contains('complete')
                                                  ? AppTheme.success
                                                  : AppTheme.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(a.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                                const SizedBox(height: 2),
                                Text('${a.subject} • ${a.wordCount} words • Price: \$${a.price.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        AssignmentDetailSheet.show(
                                          context,
                                          assignment: a,
                                          currentUser: widget.user,
                                          onStatusChanged: _fetchHistory,
                                        );
                                      },
                                      icon: const Icon(Icons.tune_rounded, size: 14),
                                      label: const Text('Control', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isTrash)
                                      ElevatedButton.icon(
                                        onPressed: () => _confirmRestore(a),
                                        icon: const Icon(Icons.restore_from_trash_rounded, size: 14),
                                        label: const Text('Restore', style: TextStyle(fontSize: 12)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.success,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => _confirmWipe(a),
                                      icon: const Icon(Icons.delete_forever_rounded, size: 14),
                                      label: const Text('Wipe', style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.danger,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            radius: 18,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
