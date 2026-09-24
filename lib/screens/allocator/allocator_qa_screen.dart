import 'package:flutter/material.dart';
import '../../core/models/assignment_model.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../common/assignment_detail_sheet.dart';

class AllocatorQaScreen extends StatefulWidget {
  final UserModel user;

  const AllocatorQaScreen({super.key, required this.user});

  @override
  State<AllocatorQaScreen> createState() => _AllocatorQaScreenState();
}

class _AllocatorQaScreenState extends State<AllocatorQaScreen> {
  bool _loading = true;
  List<AssignmentModel> _qaAssignments = [];
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchQaAssignments();
  }

  Future<void> _fetchQaAssignments() async {
    setState(() => _loading = true);
    final list = await ApiService.getAssignments(
      role: 'Allocator',
      userId: widget.user.id,
      status: 'Quality Check',
    );
    if (mounted) {
      setState(() {
        _qaAssignments = list;
        _loading = false;
      });
    }
  }

  Future<void> _approveQa(AssignmentModel asm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: AppTheme.success),
            SizedBox(width: 8),
            Text('Approve QA Deliverables'),
          ],
        ),
        content: Text(
          'Confirm quality verification for Order ${asm.assignmentId}? This will forward the deliverable to Platform Admin for final release.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Approve & Forward'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _actionLoading = true);
    final ok = await ApiService.allocatorApproveQa(
      assignmentId: asm.assignmentId,
      allocatorId: widget.user.id,
      allocatorName: widget.user.name,
    );

    if (mounted) {
      setState(() => _actionLoading = false);
      if (ok) {
        _fetchQaAssignments();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QA Approved! Order forwarded to Admin.'), backgroundColor: AppTheme.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to approve QA. Check connection.'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<void> _requestRevision(AssignmentModel asm) async {
    final instructionsCtrl = TextEditingController();

    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.assignment_return_rounded, color: AppTheme.warning),
            SizedBox(width: 8),
            Text('Request QA Revision', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order: ${asm.assignmentId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            const Text('Explain why the deliverable needs revision (plagiarism, missing sections, formatting, etc.):', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            TextField(
              controller: instructionsCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter specific revision instructions for the expert...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (instructionsCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter revision notes'), backgroundColor: AppTheme.warning),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            child: const Text('Send Revision Request'),
          ),
        ],
      ),
    );

    if (send != true) return;

    setState(() => _actionLoading = true);
    final ok = await ApiService.allocatorRequestRevision(
      assignmentId: asm.assignmentId,
      allocatorId: widget.user.id,
      allocatorName: widget.user.name,
      instructions: instructionsCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _actionLoading = false);
      if (ok) {
        _fetchQaAssignments();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Revision request sent to expert. Order status reset to Revision.'), backgroundColor: AppTheme.warning),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to request revision.'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('QA Review & Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchQaAssignments,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _actionLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Processing QA verification...'),
                    ],
                  ),
                )
              : _qaAssignments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_rounded, size: 64, color: Colors.green.shade200),
                          const SizedBox(height: 16),
                          const Text('QA Review Queue is Clear!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text('No solutions currently pending allocator quality checks.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _qaAssignments.length,
                      itemBuilder: (ctx, i) {
                        final asm = _qaAssignments[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 1.5,
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
                                        color: AppTheme.warning.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('Quality Check Required', style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold, fontSize: 11)),
                                    ),
                                    Text(asm.assignmentId, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(asm.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text('Subject: ${asm.subject} • ${asm.wordCount} words', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                                if (asm.expertId.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('Allocated Expert: ${asm.expertId}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                                ],
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => AssignmentDetailSheet.show(
                                          context,
                                          assignment: asm,
                                          currentUser: widget.user,
                                          onStatusChanged: _fetchQaAssignments,
                                        ),
                                        icon: const Icon(Icons.description_outlined, size: 16),
                                        label: const Text('Inspect Files', style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _requestRevision(asm),
                                        icon: const Icon(Icons.replay_rounded, size: 16, color: AppTheme.warning),
                                        label: const Text('Revise', style: TextStyle(fontSize: 12, color: AppTheme.warning)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _approveQa(asm),
                                        icon: const Icon(Icons.check_rounded, size: 16),
                                        label: const Text('Approve', style: TextStyle(fontSize: 12)),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
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
    );
  }
}
