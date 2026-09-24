import 'package:flutter/material.dart';
import '../../core/models/assignment_model.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/assignment_card.dart';
import '../common/assignment_detail_sheet.dart';

class StudentHistoryScreen extends StatefulWidget {
  final UserModel user;

  const StudentHistoryScreen({super.key, required this.user});

  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  bool _loading = true;
  List<AssignmentModel> _historyList = [];
  String _search = '';
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final all = await ApiService.getAssignments(
      role: 'Student',
      userId: widget.user.id,
      status: 'All',
      search: _search,
    );

    // Filter historical statuses
    final filtered = all.where((a) {
      final s = a.status.toLowerCase();
      final isHist = s.contains('completed') || s.contains('delivered') || s.contains('cancel') || s.contains('refund');
      if (!isHist) return false;

      if (_selectedFilter == 'Completed') {
        return s.contains('completed') || s.contains('delivered');
      } else if (_selectedFilter == 'Cancelled') {
        return s.contains('cancel') || s.contains('refund');
      }
      return true;
    }).toList();

    if (mounted) {
      setState(() {
        _historyList = filtered;
        _loading = false;
      });
    }
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
      body: Column(
        children: [
          // Filter & Search Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surface,
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by topic, ID, or subject...',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                  ),
                  onChanged: (v) {
                    _search = v.trim();
                    _loadHistory();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: _filters.map((f) {
                    final selected = _selectedFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _selectedFilter = f);
                          _loadHistory();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _historyList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history_edu_rounded, size: 48, color: AppTheme.textDim),
                            const SizedBox(height: 12),
                            const Text('No historical orders found', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              _selectedFilter == 'All'
                                  ? 'Delivered and archived assignments will be recorded here.'
                                  : 'No orders found matching $_selectedFilter filter.',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _historyList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final a = _historyList[i];
                            return AssignmentCard(
                              assignment: a,
                              onTap: () {
                                AssignmentDetailSheet.show(
                                  context,
                                  assignment: a,
                                  currentUser: widget.user,
                                  onStatusChanged: _loadHistory,
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
