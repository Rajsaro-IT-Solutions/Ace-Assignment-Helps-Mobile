import 'package:flutter/material.dart';
import '../../core/models/assignment_model.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../common/assignment_detail_sheet.dart';

class AllocatorAllocatedScreen extends StatefulWidget {
  final UserModel user;

  const AllocatorAllocatedScreen({super.key, required this.user});

  @override
  State<AllocatorAllocatedScreen> createState() => _AllocatorAllocatedScreenState();
}

class _AllocatorAllocatedScreenState extends State<AllocatorAllocatedScreen> {
  bool _loading = true;
  List<AssignmentModel> _activeAllocations = [];
  String _statusFilter = 'All';
  final _searchCtrl = TextEditingController();

  final List<String> _filters = ['All', 'Allocated', 'In Progress', 'Quality Check', 'Revision'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchAllocations();
  }

  Future<void> _fetchAllocations() async {
    setState(() => _loading = true);
    final all = await ApiService.getAssignments(
      role: 'Allocator',
      userId: widget.user.id,
      status: 'All',
    );

    if (mounted) {
      setState(() {
        _activeAllocations = all.where((a) {
          final s = a.status.toLowerCase();
          final matchesActive = s.contains('allocated') || s.contains('progress') || s.contains('qa') || s.contains('quality');
          if (!matchesActive) return false;
          if (_statusFilter == 'All') return true;
          return a.status.toLowerCase().contains(_statusFilter.toLowerCase());
        }).toList();
        _loading = false;
      });
    }
  }

  Color _getSlaColor(SlaInfo? sla) {
    if (sla == null) return AppTheme.success;
    final lvl = sla.level.toLowerCase();
    if (lvl == 'red' || sla.hoursLeft <= 12) return AppTheme.danger;
    if (lvl == 'amber' || sla.hoursLeft <= 24) return AppTheme.warning;
    return AppTheme.success;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Active Production Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchAllocations,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search active tasks by ID, subject, or title...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppTheme.bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) {
                      final isSel = _statusFilter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                          selected: isSel,
                          selectedColor: AppTheme.primaryLight,
                          onSelected: (_) {
                            setState(() => _statusFilter = f);
                            _fetchAllocations();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : () {
                    final q = _searchCtrl.text.trim().toLowerCase();
                    final displayList = _activeAllocations.where((a) {
                      if (q.isNotEmpty) {
                        return a.assignmentId.toLowerCase().contains(q) ||
                            a.title.toLowerCase().contains(q) ||
                            a.subject.toLowerCase().contains(q);
                      }
                      return true;
                    }).toList();

                    if (displayList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('No active assignments in this filter', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: displayList.length,
                      itemBuilder: (ctx, i) {
                        final a = displayList[i];
                          final slaColor = _getSlaColor(a.sla);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 1.5,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => AssignmentDetailSheet.show(
                                context,
                                assignment: a,
                                currentUser: widget.user,
                                onStatusChanged: _fetchAllocations,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.getStatusColor(a.status).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            a.status,
                                            style: TextStyle(
                                              color: AppTheme.getStatusColor(a.status),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        // SLA Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: slaColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.timer_outlined, size: 12, color: slaColor),
                                              const SizedBox(width: 4),
                                              Text(
                                                a.sla?.label ?? 'On Track',
                                                style: TextStyle(color: slaColor, fontWeight: FontWeight.bold, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(a.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.school_outlined, size: 14, color: AppTheme.textMuted),
                                        const SizedBox(width: 4),
                                        Text(a.subject, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                        const Spacer(),
                                        const Icon(Icons.event_outlined, size: 14, color: AppTheme.textMuted),
                                        const SizedBox(width: 4),
                                        Text(a.deadline, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.badge_outlined, size: 16, color: AppTheme.primary),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Assigned: ${a.expertId.isNotEmpty ? a.expertId : "Pending Allocation"}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textMuted),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        );
                      },
                    );
                  }(),
          ),
        ],
      ),
    );
  }
}
