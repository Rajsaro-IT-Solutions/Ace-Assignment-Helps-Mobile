import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/api_config.dart';
import '../../core/models/assignment_model.dart';
import '../../core/models/portal_models.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../student/invoice_view_dialog.dart';

class AssignmentDetailSheet extends StatefulWidget {
  final AssignmentModel assignment;
  final UserModel currentUser;
  final VoidCallback? onStatusChanged;

  const AssignmentDetailSheet({
    super.key,
    required this.assignment,
    required this.currentUser,
    this.onStatusChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required AssignmentModel assignment,
    required UserModel currentUser,
    VoidCallback? onStatusChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AssignmentDetailSheet(
        assignment: assignment,
        currentUser: currentUser,
        onStatusChanged: onStatusChanged,
      ),
    );
  }

  @override
  State<AssignmentDetailSheet> createState() => _AssignmentDetailSheetState();
}

class _AssignmentDetailSheetState extends State<AssignmentDetailSheet> {
  Map<String, dynamic>? _detailData;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final data = await ApiService.getAssignmentDetail(widget.assignment.assignmentId);
    if (mounted) {
      setState(() {
        _detailData = data;
      });
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    setState(() => _actionLoading = true);
    final success = await ApiService.updateStatus(
      assignmentId: widget.assignment.assignmentId,
      status: newStatus,
      userId: widget.currentUser.id,
      role: widget.currentUser.role,
    );
    if (mounted) {
      setState(() => _actionLoading = false);
      if (success) {
        Navigator.of(context).pop();
        widget.onStatusChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus'), backgroundColor: AppTheme.success),
        );
      }
    }
  }

  Future<void> _openFile(String path) async {
    String fullUrl = path.startsWith('http') ? path : '${ApiConfig.baseUrl}/$path';
    final uri = Uri.parse(fullUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file at $fullUrl')),
        );
      }
    }
  }

  void _showRevisionDialog() {
    final instructionsCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.rate_review_rounded, color: AppTheme.warning),
            SizedBox(width: 8),
            Text('Request Free Revision'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify in detail what modifications or additions are required:',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: instructionsCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'e.g. Please expand section 3 on methodology and add 2 additional peer-reviewed citations...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final txt = instructionsCtrl.text.trim();
              if (txt.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _actionLoading = true);
              final res = await ApiService.requestRevision(
                assignmentId: widget.assignment.assignmentId,
                studentId: widget.currentUser.id,
                instructions: txt,
              );
              setState(() => _actionLoading = false);
              if (mounted) {
                if (res.success) {
                  Navigator.pop(context);
                  widget.onStatusChanged?.call();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Revision request submitted!'), backgroundColor: AppTheme.success),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res.message), backgroundColor: AppTheme.danger),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning, foregroundColor: Colors.black),
            child: const Text('Submit Revision'),
          ),
        ],
      ),
    );
  }

  void _showRefundDialog() {
    String selectedCategory = 'Quality Not Up to Mark';
    final detailsCtrl = TextEditingController();
    bool submitting = false;

    final categories = [
      'Quality Not Up to Mark',
      'Missed Agreed Deadline',
      'Wrong Solution / Irrelevant Topic',
      'Duplicate Payment / Charged Twice',
      'Change of Mind / Cancellation',
      'Other Reason',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.currency_exchange_rounded, color: AppTheme.danger),
                SizedBox(width: 8),
                Text('Request Refund', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reason Category *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDlgState(() => selectedCategory = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Explanation & Details *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: detailsCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Please describe the issue or reason for the refund request...',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: submitting
                    ? null
                    : () async {
                        if (detailsCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please provide an explanation.')),
                          );
                          return;
                        }
                        setDlgState(() => submitting = true);
                        final res = await ApiService.requestRefund(
                          assignmentId: widget.assignment.assignmentId,
                          studentId: widget.currentUser.id,
                          reason: selectedCategory,
                          details: detailsCtrl.text.trim(),
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        if (res.success) {
                          _loadDetail();
                          widget.onStatusChanged?.call();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Refund request submitted to management for review.'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res.message.isNotEmpty ? res.message : 'Refund request failed.'),
                              backgroundColor: AppTheme.danger,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                child: submitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Refund Request'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _allocatorApprove() async {
    setState(() => _actionLoading = true);
    final ok = await ApiService.allocatorApproveQa(
      assignmentId: widget.assignment.assignmentId,
      allocatorId: widget.currentUser.id,
      allocatorName: widget.currentUser.name,
    );
    setState(() => _actionLoading = false);
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
        widget.onStatusChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QA Approved! Order forwarded for final Admin release.'), backgroundColor: AppTheme.success),
        );
      }
    }
  }

  void _allocatorRevision() {
    final instructionsCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request QA Revision from Expert'),
        content: TextField(
          controller: instructionsCtrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Specify QA remarks or required fixes...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final txt = instructionsCtrl.text.trim();
              if (txt.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _actionLoading = true);
              final ok = await ApiService.allocatorRequestRevision(
                assignmentId: widget.assignment.assignmentId,
                allocatorId: widget.currentUser.id,
                allocatorName: widget.currentUser.name,
                instructions: txt,
              );
              setState(() => _actionLoading = false);
              if (mounted && ok) {
                Navigator.pop(context);
                widget.onStatusChanged?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Revision request sent back to expert.'), backgroundColor: AppTheme.warning),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            child: const Text('Send Revision Request'),
          ),
        ],
      ),
    );
  }

  void _showAllocatorWorkflowDialog() async {
    final experts = await ApiService.getExperts();
    if (!mounted) return;

    String selectedExpert = widget.assignment.expertId;
    String selectedStatus = widget.assignment.status;
    final notesCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Workflow & Allocation Control'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assign Primary Expert', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: experts.any((e) => e.expertId == selectedExpert) ? selectedExpert : '',
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Unassigned', style: TextStyle(fontSize: 12))),
                    ...experts.map((e) => DropdownMenuItem(
                          value: e.expertId,
                          child: Text('${e.name} (${e.status})', style: const TextStyle(fontSize: 12)),
                        )),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedExpert = val);
                  },
                ),
                const SizedBox(height: 14),

                const Text('Production Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: ['Pending', 'In Progress', 'Under Review', 'Quality Check', 'Completed', 'Cancelled'].contains(selectedStatus)
                      ? selectedStatus
                      : 'In Progress',
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: ['Pending', 'In Progress', 'Under Review', 'Quality Check', 'Completed', 'Cancelled']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedStatus = val);
                  },
                ),
                const SizedBox(height: 14),

                const Text('Internal Technical Notes / Remarks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Enter guidelines for the assigned expert...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDlgState(() => saving = true);
                      final ok = await ApiService.allocateExpert(
                        assignmentId: widget.assignment.assignmentId,
                        expertId: selectedExpert,
                        allocatorId: widget.currentUser.id,
                        deadline: widget.assignment.deadline,
                        status: selectedStatus,
                        internalNotes: notesCtrl.text.trim(),
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (!mounted) return;
                      if (ok) {
                        Navigator.pop(context);
                        widget.onStatusChanged?.call();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Allocation updated successfully!'), backgroundColor: AppTheme.success),
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadDeliverableDialog() {
    final nameCtrl = TextEditingController(text: 'Solution_Deliverable_${widget.assignment.assignmentId}.docx');
    String fileType = 'Complete Solution';
    String fileStage = 'Complete';
    bool isInternal = false;
    bool uploading = false;

    final types = [
      'Complete Solution',
      'Draft Solution',
      'Turnitin Plagiarism Report',
      'Source Code / Script',
      'Dataset / Archive',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Upload Deliverable File'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('File Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),

                const Text('Deliverable Type *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: fileType,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: types.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) {
                    if (v != null) setDlgState(() => fileType = v);
                  },
                ),
                const SizedBox(height: 14),

                const Text('Access Stage *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: fileStage,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Complete', child: Text('Complete File / Final Solution', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'Draft', child: Text('Draft Deliverable (Milestone)', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (v) {
                    if (v != null) setDlgState(() => fileStage = v);
                  },
                ),
                const SizedBox(height: 14),

                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Staff Internal File (Hidden from student)', style: TextStyle(fontSize: 12)),
                  value: isInternal,
                  onChanged: (v) => setDlgState(() => isInternal = v ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: uploading
                  ? null
                  : () async {
                      setDlgState(() => uploading = true);
                      final ok = await ApiService.uploadDeliverable(
                        assignmentId: widget.assignment.assignmentId,
                        fileName: nameCtrl.text.trim(),
                        fileType: fileType,
                        fileStage: fileStage.toLowerCase(),
                        uploadedBy: widget.currentUser.name,
                        isInternal: isInternal,
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (!mounted) return;
                      if (ok) {
                        _loadDetail();
                        widget.onStatusChanged?.call();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Deliverable file uploaded successfully!'), backgroundColor: AppTheme.success),
                        );
                      }
                    },
              child: uploading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Upload File'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentUploadBriefDialog() {
    final nameCtrl = TextEditingController();
    String fileType = 'Document (PDF/DOCX)';
    bool uploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.upload_file_rounded, color: AppTheme.primary),
                SizedBox(width: 8),
                Text('Upload Brief Material', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('File / Document Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(hintText: 'e.g. Lecture_Notes_Week4.pdf'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Document Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: fileType,
                    items: const [
                      DropdownMenuItem(value: 'Document (PDF/DOCX)', child: Text('Document (PDF/DOCX)')),
                      DropdownMenuItem(value: 'Presentation / Slides', child: Text('Presentation / Slides')),
                      DropdownMenuItem(value: 'Rubric / Marking Criteria', child: Text('Rubric / Marking Criteria')),
                      DropdownMenuItem(value: 'Dataset / Code (ZIP/CSV)', child: Text('Dataset / Code (ZIP/CSV)')),
                      DropdownMenuItem(value: 'Other Reference File', child: Text('Other Reference File')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDlgState(() => fileType = v);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: uploading
                    ? null
                    : () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        setDlgState(() => uploading = true);
                        final ok = await ApiService.uploadStudentSupplementaryFile(
                          assignmentId: widget.assignment.assignmentId,
                          fileName: nameCtrl.text.trim(),
                          fileType: fileType,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        if (ok) {
                          _loadDetail();
                          widget.onStatusChanged?.call();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Brief material uploaded successfully!'), backgroundColor: AppTheme.success),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Upload failed. Please try again.'), backgroundColor: AppTheme.danger),
                          );
                        }
                      },
                child: uploading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Upload File'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleFileStage(AssignmentFileModel f) async {
    final nextStage = f.fileStage.toLowerCase() == 'complete' ? 'draft' : 'complete';
    final ok = await ApiService.toggleFileStage(fileId: f.id, newStage: nextStage);
    if (ok) {
      _loadDetail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File access updated to ${nextStage.toUpperCase()}'), backgroundColor: AppTheme.success),
        );
      }
    }
  }

  void _deleteFile(AssignmentFileModel f) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Remove file "${f.fileName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final ok = await ApiService.deleteFile(fileId: f.id);
    if (ok) {
      _loadDetail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File removed.'), backgroundColor: AppTheme.success),
        );
      }
    }
  }

  void _adminRelease() async {
    setState(() => _actionLoading = true);
    final ok = await ApiService.adminReleaseSolution(
      assignmentId: widget.assignment.assignmentId,
      adminId: widget.currentUser.id,
    );
    setState(() => _actionLoading = false);
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
        widget.onStatusChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solution released to student successfully!'), backgroundColor: AppTheme.success),
        );
      }
    }
  }

  void _showAdminOverrideDialog() async {
    final priceCtrl = TextEditingController(text: widget.assignment.price.toStringAsFixed(2));
    String selectedStatus = widget.assignment.status;
    String selectedExpert = widget.assignment.expertId;
    String selectedAllocator = widget.assignment.allocatorId;
    bool saving = false;

    // Load available experts & allocators
    final experts = await ApiService.getExperts();
    final allocators = await ApiService.getAllocators();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.tune_rounded, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Admin Workflow Overrides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assignment Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: ['Pending', 'Confirmed', 'In Progress', 'Under QA', 'Completed', 'Under Review', 'Cancelled', 'Archived'].contains(selectedStatus)
                      ? selectedStatus
                      : 'Pending',
                  items: const [
                    DropdownMenuItem(value: 'Pending', child: Text('Pending Review')),
                    DropdownMenuItem(value: 'Confirmed', child: Text('Confirmed')),
                    DropdownMenuItem(value: 'In Progress', child: Text('In Progress (Working)')),
                    DropdownMenuItem(value: 'Under QA', child: Text('Under QA Verification')),
                    DropdownMenuItem(value: 'Completed', child: Text('Completed & Delivered')),
                    DropdownMenuItem(value: 'Under Review', child: Text('Under Review / Revision')),
                    DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                    DropdownMenuItem(value: 'Archived', child: Text('Archived / In Trash')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedStatus = val);
                  },
                ),
                const SizedBox(height: 12),
                const Text('Price Override (USD \$)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.attach_money_rounded)),
                ),
                const SizedBox(height: 12),
                const Text('Allocated PhD Expert', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: experts.any((e) => e.expertId == selectedExpert) ? selectedExpert : '',
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.school_outlined)),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Unassigned / None')),
                    ...experts.map((e) => DropdownMenuItem(value: e.expertId, child: Text('${e.name} (${e.expertId})', style: const TextStyle(fontSize: 12)))),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedExpert = val);
                  },
                ),
                const SizedBox(height: 12),
                const Text('Assigned Allocator Staff', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: allocators.any((a) => a.allocatorId == selectedAllocator) ? selectedAllocator : '',
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.support_agent_outlined)),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Unassigned / None')),
                    ...allocators.map((a) => DropdownMenuItem(value: a.allocatorId, child: Text('${a.name} (${a.allocatorId})', style: const TextStyle(fontSize: 12)))),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedAllocator = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final pr = double.tryParse(priceCtrl.text.trim()) ?? widget.assignment.price;
                      setDlgState(() => saving = true);

                      final ok = await ApiService.updateAssignmentAdmin(
                        assignmentId: widget.assignment.assignmentId,
                        status: selectedStatus,
                        price: pr,
                        expertId: selectedExpert.isNotEmpty ? selectedExpert : null,
                        allocatorId: selectedAllocator.isNotEmpty ? selectedAllocator : null,
                      );

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (!mounted) return;
                      if (ok) {
                        Navigator.pop(context);
                        widget.onStatusChanged?.call();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Admin changes updated successfully!'), backgroundColor: AppTheme.success),
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Overrides'),
            ),
          ],
        ),
      ),
    );
  }

  void _adminSoftDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to History / Trash'),
        content: Text('Move assignment ${widget.assignment.assignmentId} to History? It can be restored later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await ApiService.softDeleteAssignment(widget.assignment.assignmentId);
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
        widget.onStatusChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment moved to history & trash.'), backgroundColor: AppTheme.success),
        );
      }
    }
  }

  void _adminPermanentWipe() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete Everywhere'),
        content: Text(
          'Are you sure you want to permanently wipe assignment ${widget.assignment.assignmentId}?\nThis removes all files, chat, notes, and records completely.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Wipe Everywhere'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await ApiService.wipeAssignment(widget.assignment.assignmentId);
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
        widget.onStatusChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment permanently erased.'), backgroundColor: AppTheme.success),
        );
      }
    }
  }

  void _openOfficialInvoice() {
    showDialog(
      context: context,
      builder: (_) => InvoiceViewDialog(
        assignment: widget.assignment,
        currentUser: widget.currentUser,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    final total = a.finalPrice > 0 ? a.finalPrice : a.price;
    final balance = (total - a.paidAmount).clamp(0.0, double.infinity);

    final rawFiles = (_detailData != null && _detailData!['files'] is List) ? (_detailData!['files'] as List) : [];
    final files = rawFiles
        .whereType<Map>()
        .map((f) => AssignmentFileModel.fromJson(Map<String, dynamic>.from(f)))
        .toList();

    final briefFiles = files.where((f) => f.fileStage.toLowerCase() == 'brief').toList();
    final solutionFiles = files.where((f) => f.fileStage.toLowerCase() != 'brief').toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header: ID, Status, and Invoice Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  a.assignmentId,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primary),
                ),
              ),
              Row(
                children: [
                  if (!widget.currentUser.isAllocator) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        InvoiceViewDialog.show(
                          context,
                          assignment: a,
                          currentUser: widget.currentUser,
                          onPaymentSuccess: () {
                            _loadDetail();
                            widget.onStatusChanged?.call();
                          },
                        );
                      },
                      icon: const Icon(Icons.receipt_long_rounded, size: 14),
                      label: const Text('Invoice', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.getStatusColor(a.status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      a.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getStatusColor(a.status),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Subject
                  Text(
                    a.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textMain),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${a.subject} • ${a.assignmentType}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.secondary),
                  ),
                  const SizedBox(height: 14),

                  // Lifecycle Progress Stepper
                  _buildLifecycleStepper(a.status),
                  const SizedBox(height: 16),

                  // Specs Grid
                  Row(
                    children: [
                      _buildSpecTile('Word Count', '${a.wordCount} words', Icons.text_snippet_outlined),
                      _buildSpecTile('Deadline', a.deadline.split(' ').first, Icons.calendar_today_rounded),
                    ],
                  ),
                  if (widget.currentUser.isAllocator) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 18, color: Colors.amber),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Financials & Student PII masked in compliance with Allocator RBAC.',
                              style: TextStyle(fontSize: 11, color: Colors.brown, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Row(
                      children: [
                        _buildSpecTile('Total Price', '${a.currency} ${total.toStringAsFixed(2)}', Icons.payments_outlined),
                        _buildSpecTile('Paid to Date', '${a.currency} ${a.paidAmount.toStringAsFixed(2)}', Icons.check_circle_outline),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Brief Instructions
                  if (a.instructions.isNotEmpty) ...[
                    const Text('Instructions & Guidelines', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(a.instructions, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Verified Completed Deliverables (Solution Files)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded, color: AppTheme.success, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Solution Deliverables (${solutionFiles.length})',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                          ),
                        ],
                      ),
                      if (widget.currentUser.isAllocator || widget.currentUser.isAdmin)
                        TextButton.icon(
                          onPressed: _showUploadDeliverableDialog,
                          icon: const Icon(Icons.upload_file_rounded, size: 16),
                          label: const Text('Upload File', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (solutionFiles.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppTheme.bg, borderRadius: BorderRadius.circular(8)),
                      child: const Text('No solution deliverables uploaded yet.', style: TextStyle(fontSize: 12, color: AppTheme.textDim)),
                    )
                  else
                    ...solutionFiles.map((f) => _buildFileTile(f, isSolution: true)),
                  const SizedBox(height: 16),

                  // Student Brief Materials
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Student Brief Materials (${briefFiles.length})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      if (widget.currentUser.isStudent)
                        TextButton.icon(
                          onPressed: _showStudentUploadBriefDialog,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add File', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (briefFiles.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppTheme.bg, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('No supplementary materials attached.', style: TextStyle(fontSize: 12, color: AppTheme.textDim)),
                          if (widget.currentUser.isStudent)
                            TextButton(
                              onPressed: _showStudentUploadBriefDialog,
                              child: const Text('Attach Files', style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                    )
                  else
                    ...briefFiles.map((f) => _buildFileTile(f)),
                  const SizedBox(height: 16),

                  // Assigned Expert Info (if present)
                  if (_detailData != null && _detailData!['allocation'] is Map) ...[
                    const Text('Assigned Expert', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryLight,
                            child: Icon(Icons.person, color: AppTheme.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (_detailData!['allocation'] as Map)['expert_name']?.toString() ?? 'Assigned Expert',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                (_detailData!['allocation'] as Map)['expert_email']?.toString() ?? '',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textDim),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Student Actions (Revision / Refund / Balance)
                  if (widget.currentUser.isStudent) ...[
                    const Text('Order Actions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _showRevisionDialog,
                          icon: const Icon(Icons.rate_review_outlined, size: 16),
                          label: const Text('Request Revision'),
                          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.warning),
                        ),
                        OutlinedButton.icon(
                          onPressed: _showRefundDialog,
                          icon: const Icon(Icons.currency_exchange_rounded, size: 16),
                          label: const Text('Request Refund'),
                          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger),
                        ),
                        if (balance > 0)
                          ElevatedButton.icon(
                            onPressed: () {
                              InvoiceViewDialog.show(
                                context,
                                assignment: a,
                                currentUser: widget.currentUser,
                                onPaymentSuccess: () {
                                  _loadDetail();
                                  widget.onStatusChanged?.call();
                                },
                              );
                            },
                            icon: const Icon(Icons.payment_rounded, size: 16),
                            label: Text('Pay Balance (${a.currency} ${balance.toStringAsFixed(2)})'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Allocator QA Review Controls
                  if (widget.currentUser.isAllocator) ...[
                    const Text('Allocator Workflow Control', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    const SizedBox(height: 8),

                    // Allocator Workflow Dialog
                    ElevatedButton.icon(
                      onPressed: _showAllocatorWorkflowDialog,
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Workflow & Allocation (Expert, Status, Notes)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _actionLoading ? null : _allocatorApprove,
                            icon: const Icon(Icons.check_circle_rounded, size: 18),
                            label: const Text('Approve QA'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _allocatorRevision,
                            icon: const Icon(Icons.replay_rounded, size: 18),
                            label: const Text('Need Revision'),
                            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.warning),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Admin Controls (Full Suite)
                  if (widget.currentUser.isAdmin) ...[
                    const Text('Executive Admin Controls', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    const SizedBox(height: 8),

                    // Workflow Overrides Button
                    ElevatedButton.icon(
                      onPressed: _showAdminOverrideDialog,
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Workflow Overrides (Price, Expert, Allocator, Status)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Official Invoice Button
                    OutlinedButton.icon(
                      onPressed: _openOfficialInvoice,
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      label: const Text('View / Print Official Invoice'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 42),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Quick Status Overrides
                    const Text('Quick Status Overrides', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildStatusButton('Confirmed', AppTheme.primary),
                        _buildStatusButton('In Progress', AppTheme.secondary),
                        _buildStatusButton('Under QA', AppTheme.warning),
                        _buildStatusButton('Completed', AppTheme.success),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Final Admin Release
                    ElevatedButton.icon(
                      onPressed: _actionLoading ? null : _adminRelease,
                      icon: const Icon(Icons.verified_rounded, size: 18),
                      label: const Text('Final Admin Release to Student'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Soft Delete & Permanent Wipe
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _adminSoftDelete,
                            icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: AppTheme.warning),
                            label: const Text('Move to Trash', style: TextStyle(color: AppTheme.warning, fontSize: 12)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.warning)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _adminPermanentWipe,
                            icon: const Icon(Icons.delete_forever_rounded, size: 16, color: AppTheme.danger),
                            label: const Text('Wipe Everywhere', style: TextStyle(color: AppTheme.danger, fontSize: 12)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.danger)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Close
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifecycleStepper(String currentStatus) {
    final stages = ['Submitted', 'Allocated', 'In Progress', 'Under QA', 'Completed'];
    int currentIndex = 0;
    final s = currentStatus.toLowerCase();
    if (s.contains('completed') || s.contains('delivered')) {
      currentIndex = 4;
    } else if (s.contains('qa') || s.contains('quality') || s.contains('approval')) {
      currentIndex = 3;
    } else if (s.contains('progress') || s.contains('working') || s.contains('revision')) {
      currentIndex = 2;
    } else if (s.contains('allocated')) {
      currentIndex = 1;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: stages.asMap().entries.map((e) {
          final idx = e.key;
          final name = e.value;
          final isPastOrCurr = idx <= currentIndex;
          final isCurr = idx == currentIndex;

          return Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isCurr
                      ? AppTheme.primary
                      : isPastOrCurr
                          ? AppTheme.success
                          : AppTheme.border,
                  child: Icon(
                    isPastOrCurr ? Icons.check : Icons.circle,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isCurr ? FontWeight.bold : FontWeight.w500,
                    color: isCurr ? AppTheme.primary : AppTheme.textDim,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFileTile(AssignmentFileModel f, {bool isSolution = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSolution ? AppTheme.success.withValues(alpha: 0.08) : AppTheme.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSolution ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSolution ? Icons.task_alt_rounded : Icons.insert_drive_file_outlined,
            color: isSolution ? AppTheme.success : AppTheme.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.fileName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  '${f.fileStage.toUpperCase()} • ${f.uploadedBy}',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textDim),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Open / Download File',
            icon: const Icon(Icons.download_rounded, size: 20, color: AppTheme.primary),
            onPressed: () => _openFile(f.path),
          ),
          if (widget.currentUser.isAllocator || widget.currentUser.isAdmin)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppTheme.textDim),
              onSelected: (val) {
                if (val == 'toggle') {
                  _toggleFileStage(f);
                } else if (val == 'delete') {
                  _deleteFile(f);
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      const Icon(Icons.swap_horiz_rounded, size: 16, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text(f.fileStage.toLowerCase() == 'complete' ? 'Set as Draft' : 'Set as Complete', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 16, color: AppTheme.danger),
                      SizedBox(width: 8),
                      Text('Delete File', style: TextStyle(fontSize: 12, color: AppTheme.danger)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSpecTile(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textDim)),
                  Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(String status, Color color) {
    final isCurrent = widget.assignment.status.toLowerCase() == status.toLowerCase();
    return OutlinedButton(
      onPressed: isCurrent ? null : () => _changeStatus(status),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: isCurrent ? 2 : 1),
        backgroundColor: isCurrent ? color.withValues(alpha: 0.1) : null,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        visualDensity: VisualDensity.compact,
      ),
      child: Text(isCurrent ? '✓ $status' : status, style: const TextStyle(fontSize: 11)),
    );
  }
}
