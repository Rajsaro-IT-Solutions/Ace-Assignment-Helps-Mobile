import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/assignment_model.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../common/assignment_detail_sheet.dart';

class AllocatorCompletedScreen extends StatefulWidget {
  final UserModel user;

  const AllocatorCompletedScreen({super.key, required this.user});

  @override
  State<AllocatorCompletedScreen> createState() => _AllocatorCompletedScreenState();
}

class _AllocatorCompletedScreenState extends State<AllocatorCompletedScreen> {
  bool _loading = true;
  List<AssignmentModel> _completedList = [];
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCompleted();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCompleted() async {
    setState(() => _loading = true);
    final list = await ApiService.getCompletedAssignmentsForAllocator();
    if (mounted) {
      setState(() {
        _completedList = list;
        _loading = false;
      });
    }
  }

  List<AssignmentModel> get _filteredList {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _completedList;
    return _completedList.where((a) {
      return a.assignmentId.toLowerCase().contains(query) ||
          a.title.toLowerCase().contains(query) ||
          a.subject.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Completed Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchCompleted,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchCompleted,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF065F46), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.task_alt_rounded, color: Colors.white, size: 36),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_completedList.length} Finished Deliverables',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Archived log of fulfilled, quality-verified student submissions.',
                                  style: TextStyle(fontSize: 12, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search Field
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search by Order ID, title, or subject...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: AppTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Empty State or List
                    if (_filteredList.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textDim),
                            SizedBox(height: 12),
                            Text('No completed assignments found', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          DateTime? dl = DateTime.tryParse(a.deadline);
                          final dlStr = dl != null ? DateFormat('MMM d, yyyy').format(dl) : a.deadline;

                          return Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppTheme.success),
                                    ),
                                    child: Text(
                                      a.assignmentId,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      a.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.school_outlined, size: 14, color: AppTheme.textDim),
                                      const SizedBox(width: 4),
                                      Text(a.subject, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                      const SizedBox(width: 14),
                                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textDim),
                                      const SizedBox(width: 4),
                                      Text('Target: $dlStr', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                        child: Text(
                                          'Student: ${a.studentId.isNotEmpty ? a.studentId : "[Protected]"}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textDim),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (a.expertId.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(4)),
                                          child: Text(
                                            'Expert: ${a.expertId}',
                                            style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textDim),
                              onTap: () {
                                AssignmentDetailSheet.show(
                                  context,
                                  assignment: a,
                                  currentUser: widget.user,
                                  onStatusChanged: _fetchCompleted,
                                );
                              },
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
}
