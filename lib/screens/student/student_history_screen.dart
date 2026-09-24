import 'package:flutter/material.dart';
import '../../core/models/assignment_model.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../common/assignment_detail_sheet.dart';
import 'invoice_view_dialog.dart';

class StudentHistoryScreen extends StatefulWidget {
  final UserModel user;

  const StudentHistoryScreen({super.key, required this.user});

  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  bool _loading = true;
  List<AssignmentModel> _allHistory = [];
  final _searchCtrl = TextEditingController();
  String _selectedTab = 'All History'; // 'All History', 'Past Completed', 'Deleted'

  final List<String> _tabs = ['All History', 'Past Completed', 'Deleted'];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final all = await ApiService.getAssignments(
      role: 'Student',
      userId: widget.user.id,
      status: 'All',
    );

    // Filter historical or completed/archived/cancelled orders
    final historical = all.where((a) {
      final s = a.status.toLowerCase();
      return s.contains('completed') ||
          s.contains('delivered') ||
          s.contains('cancel') ||
          s.contains('refund') ||
          s.contains('archive') ||
          s.contains('trash') ||
          s.contains('delete');
    }).toList();

    if (mounted) {
      setState(() {
        _allHistory = historical;
        _loading = false;
      });
    }
  }

  int get _totalArchivedCount => _allHistory.length;

  int get _completedCount => _allHistory.where((a) {
        final s = a.status.toLowerCase();
        return s.contains('completed') || s.contains('delivered');
      }).length;

  int get _deletedCount => _allHistory.where((a) {
        final s = a.status.toLowerCase();
        return s.contains('archive') || s.contains('trash') || s.contains('delete');
      }).length;

  int get _cancelledOrRefundedCount => _allHistory.where((a) {
        final s = a.status.toLowerCase();
        return s.contains('cancel') || s.contains('refund');
      }).length;

  List<AssignmentModel> get _filteredList {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _allHistory.where((a) {
      final matchesQuery = q.isEmpty ||
          a.assignmentId.toLowerCase().contains(q) ||
          a.title.toLowerCase().contains(q) ||
          a.subject.toLowerCase().contains(q);

      final s = a.status.toLowerCase();
      bool matchesTab = true;
      if (_selectedTab == 'Past Completed') {
        matchesTab = s.contains('completed') || s.contains('delivered');
      } else if (_selectedTab == 'Deleted') {
        matchesTab = s.contains('archive') || s.contains('trash') || s.contains('delete');
      }

      return matchesQuery && matchesTab;
    }).toList();
  }

  void _restoreOrder(AssignmentModel a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Assignment'),
        content: Text('Restore order ${a.assignmentId} from archives back to active review?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await ApiService.restoreAssignment(a.assignmentId);
    if (mounted) {
      if (ok) {
        _loadHistory();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment successfully restored to Active.'), backgroundColor: AppTheme.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to restore assignment.'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('completed') || s.contains('delivered')) return AppTheme.success;
    if (s.contains('cancel') || s.contains('trash') || s.contains('delete')) return AppTheme.danger;
    if (s.contains('refund')) return const Color(0xFF8B5CF6);
    return AppTheme.textDim;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Assignment History & Archives'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadHistory),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 4 KPI Metric Cards (Mirroring /student/history.php)
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Total Archived',
                            '$_totalArchivedCount',
                            Icons.inventory_2_outlined,
                            AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            'Past Completed',
                            '$_completedCount',
                            Icons.check_circle_outline_rounded,
                            AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Deleted Orders',
                            '$_deletedCount',
                            Icons.delete_outline_rounded,
                            AppTheme.danger,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            'Refunded / Cancel',
                            '$_cancelledOrRefundedCount',
                            Icons.currency_exchange_rounded,
                            const Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search and Filter Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: 'Search archived orders by title, ID, subject...',
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
                            children: _tabs.map((tab) {
                              final isSelected = _selectedTab == tab;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(tab),
                                  selected: isSelected,
                                  onSelected: (_) => setState(() => _selectedTab = tab),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Archive List
                    if (_filteredList.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(36),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.history_edu_rounded, size: 48, color: AppTheme.textDim),
                            const SizedBox(height: 12),
                            Text(
                              _selectedTab == 'All History'
                                  ? 'No archives or past orders'
                                  : 'No orders in $_selectedTab',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _searchCtrl.text.isNotEmpty
                                  ? 'No records match "${_searchCtrl.text.trim()}". Try different keywords.'
                                  : 'Completed assignments and past records will be securely archived here.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
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
                          final sCol = _getStatusColor(a.status);
                          final isDeleted = a.status.toLowerCase().contains('delete') ||
                              a.status.toLowerCase().contains('trash') ||
                              a.status.toLowerCase().contains('archive');

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
                                // Top row: ID, Status, Price
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        a.assignmentId,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: sCol.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: sCol.withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        a.status,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: sCol,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Title & Subject
                                Text(
                                  a.title,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.bg,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        a.subject,
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textDim, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '• ${a.wordCount} words',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Financials & Date
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Investment: ${a.price.toStringAsFixed(2)} ${a.currency}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDim),
                                    ),
                                    Text(
                                      a.deadline.isNotEmpty ? 'Deadline: ${a.deadline.split(' ')[0]}' : 'Archived',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),

                                // Action Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          AssignmentDetailSheet.show(
                                            context,
                                            assignment: a,
                                            currentUser: widget.user,
                                            onStatusChanged: _loadHistory,
                                          );
                                        },
                                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                        label: const Text('Details →', style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          InvoiceViewDialog.show(
                                            context,
                                            assignment: a,
                                            currentUser: widget.user,
                                            onPaymentSuccess: _loadHistory,
                                          );
                                        },
                                        icon: const Icon(Icons.receipt_long_rounded, size: 16),
                                        label: const Text('View Invoice', style: TextStyle(fontSize: 12)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                    if (isDeleted) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        tooltip: 'Restore Order',
                                        icon: const Icon(Icons.restore_from_trash_rounded, color: AppTheme.success),
                                        onPressed: () => _restoreOrder(a),
                                      ),
                                    ],
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

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
