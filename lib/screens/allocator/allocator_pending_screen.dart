import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/assignment_model.dart';
import '../../core/models/portal_models.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../common/assignment_detail_sheet.dart';

class AllocatorPendingScreen extends StatefulWidget {
  final UserModel user;

  const AllocatorPendingScreen({super.key, required this.user});

  @override
  State<AllocatorPendingScreen> createState() => _AllocatorPendingScreenState();
}

class _AllocatorPendingScreenState extends State<AllocatorPendingScreen> {
  bool _loading = true;
  List<AssignmentModel> _pendingAssignments = [];

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() => _loading = true);
    final all = await ApiService.getAssignments(
      role: 'Allocator',
      userId: widget.user.id,
      status: 'Pending',
    );
    if (mounted) {
      setState(() {
        _pendingAssignments = all;
        _loading = false;
      });
    }
  }

  void _showAllocateBottomSheet(AssignmentModel assignment) async {
    List<ExpertModel> experts = await ApiService.getExperts();
    if (!mounted) return;

    String? selectedExpertId = experts.isNotEmpty ? experts.first.expertId : null;
    DateTime expertDeadline = DateTime.now().add(const Duration(days: 3));
    bool allocating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Allocate Expert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                Text(
                  'Order: ${assignment.title} (${assignment.assignmentId})',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),

                const Text('Select Academic Expert *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (experts.isEmpty)
                  const Text('No active experts found in roster.')
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedExpertId,
                        isExpanded: true,
                        items: experts.map((e) {
                          return DropdownMenuItem(
                            value: e.expertId,
                            child: Row(
                              children: [
                                Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('Active: ${e.activeTasks}', style: const TextStyle(fontSize: 10, color: AppTheme.primary)),
                                ),
                                const Spacer(),
                                Text('⭐ ${e.rating}', style: const TextStyle(fontSize: 12, color: AppTheme.warning)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setSheetState(() => selectedExpertId = v);
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                const Text('Set Expert Submission Deadline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 18, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEE, MMM d, yyyy • 23:59').format(expertDeadline),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: expertDeadline,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) {
                            setSheetState(() => expertDeadline = picked);
                          }
                        },
                        child: const Text('Change Date'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (allocating || selectedExpertId == null)
                        ? null
                        : () async {
                            setSheetState(() => allocating = true);
                            final navigator = Navigator.of(ctx);
                            final messenger = ScaffoldMessenger.of(context);
                            final ok = await ApiService.allocateExpert(
                              assignmentId: assignment.assignmentId,
                              expertId: selectedExpertId!,
                              allocatorId: widget.user.id,
                              deadline: DateFormat('yyyy-MM-dd 23:59:59').format(expertDeadline),
                            );
                            if (!mounted) return;
                            navigator.pop();
                            if (ok) {
                              _loadPending();
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Expert successfully allocated! Task moved to Active.'), backgroundColor: AppTheme.success),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: allocating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Confirm Expert Allocation'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Pending Allocation Queue'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadPending),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPending,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 32),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_pendingAssignments.length} Orders Awaiting Allocation',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Review briefs and assign suitable PhD subject specialists.',
                                  style: TextStyle(fontSize: 12, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_pendingAssignments.isEmpty)
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
                            Icon(Icons.check_circle_outline_rounded, size: 52, color: AppTheme.success),
                            SizedBox(height: 12),
                            Text('Queue is all clear!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 4),
                            Text('All incoming student assignments have been allocated.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pendingAssignments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final a = _pendingAssignments[i];
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.warningBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        a.assignmentId,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.warning),
                                      ),
                                    ),
                                    Text(
                                      '${a.wordCount} Words',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  a.title,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Subject: ${a.subject}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule, size: 14, color: AppTheme.textDim),
                                    const SizedBox(width: 4),
                                    Text('Deadline: ${a.deadlineFormatted}', style: const TextStyle(fontSize: 12, color: AppTheme.textDim)),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          AssignmentDetailSheet.show(
                                            context,
                                            assignment: a,
                                            currentUser: widget.user,
                                          );
                                        },
                                        child: const Text('View Brief'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showAllocateBottomSheet(a),
                                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                                        label: const Text('Allocate'),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
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
}
