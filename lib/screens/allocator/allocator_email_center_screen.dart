import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/assignment_model.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class AllocatorEmailCenterScreen extends StatefulWidget {
  final UserModel user;

  const AllocatorEmailCenterScreen({super.key, required this.user});

  @override
  State<AllocatorEmailCenterScreen> createState() => _AllocatorEmailCenterScreenState();
}

class _AllocatorEmailCenterScreenState extends State<AllocatorEmailCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  bool _sending = false;
  List<AssignmentModel> _assignments = [];
  List<Map<String, dynamic>> _emailHistory = [];

  // Form State
  String? _selectedAssignmentId;
  String _selectedTemplate = 'Expert Allocation Notification';
  String _selectedRecipient = 'Student';
  final _customNoteCtrl = TextEditingController();

  final List<String> _templates = [
    'Expert Allocation Notification',
    'Assignment Submitted Confirmation',
    'Milestone / Progress Update',
    'Urgent SLA / Deadline Alert',
    'Draft Solution Ready for Review',
    'Final Deliverable Dispatched',
    'QA Revision Request',
  ];

  final List<String> _recipients = ['Student', 'Expert', 'Both'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final asg = await ApiService.getAssignments(role: 'Allocator', userId: widget.user.id);
    final history = await ApiService.getEmailHistory();
    if (mounted) {
      setState(() {
        _assignments = asg;
        if (_assignments.isNotEmpty && _selectedAssignmentId == null) {
          _selectedAssignmentId = _assignments.first.assignmentId;
        }
        _emailHistory = history;
        _loading = false;
      });
    }
  }

  Future<void> _sendEmail() async {
    if (_selectedAssignmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an assignment target.'), backgroundColor: AppTheme.danger),
      );
      return;
    }

    setState(() => _sending = true);
    final ok = await ApiService.sendAutomatedEmail(
      assignmentId: _selectedAssignmentId!,
      template: _selectedTemplate,
      recipient: _selectedRecipient,
      senderId: widget.user.id,
      senderName: widget.user.name,
      customMessage: _customNoteCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _sending = false);
      if (ok) {
        _customNoteCtrl.clear();
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Automated email dispatched successfully to $_selectedRecipient!'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send email. Check connection.'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Email Center'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textDim,
          tabs: const [
            Tab(icon: Icon(Icons.send_rounded, size: 18), text: 'Compose Dispatch'),
            Tab(icon: Icon(Icons.history_rounded, size: 18), text: 'Outbox History'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildComposeTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildComposeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF334155)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.mail_lock_rounded, color: Colors.white, size: 32),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Automated Notification Engine',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Dispatch official system email templates to students or assigned experts.',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Target Assignment
          const Text('Target Assignment *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedAssignmentId,
                isExpanded: true,
                items: _assignments.map((a) {
                  return DropdownMenuItem(
                    value: a.assignmentId,
                    child: Text(
                      '${a.assignmentId} - ${a.title} (${a.status})',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedAssignmentId = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Template Selection
          const Text('Email Notification Template *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTemplate,
                isExpanded: true,
                items: _templates.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTemplate = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recipient Audience
          const Text('Recipient Audience *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: _recipients.map((r) {
              final isSel = _selectedRecipient == r;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(r == 'Both' ? 'Both (Student & Expert)' : r),
                  selected: isSel,
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(color: isSel ? Colors.white : AppTheme.textMain, fontWeight: FontWeight.bold, fontSize: 12),
                  onSelected: (_) => setState(() => _selectedRecipient = r),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Custom Remarks
          const Text('Additional Guidance / Custom Remarks (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _customNoteCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter specific guidelines, deadline reminders, or requirements for the recipient...',
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
            ),
          ),
          const SizedBox(height: 24),

          // Send Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _sendEmail,
              icon: _sending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(_sending ? 'Dispatching...' : 'Dispatch Automated Email'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_emailHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_read_outlined, size: 48, color: AppTheme.textDim),
            SizedBox(height: 12),
            Text('No automated emails logged yet', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _emailHistory.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final item = _emailHistory[i];
        final dt = item['timestamp']?.toString() ?? '';
        DateTime? parsed = DateTime.tryParse(dt);
        final dtFormatted = parsed != null ? DateFormat('MMM d, yyyy • HH:mm').format(parsed) : dt;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
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
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item['action'] ?? 'EMAIL_DISPATCHED',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ),
                  Text(dtFormatted, style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item['details'] ?? '',
                style: const TextStyle(fontSize: 13, height: 1.3),
              ),
              const SizedBox(height: 4),
              Text(
                'Dispatched by: ${item['user_id'] ?? "Staff"} (${item['user_role'] ?? "Allocator"})',
                style: const TextStyle(fontSize: 11, color: AppTheme.textDim),
              ),
            ],
          ),
        );
      },
    );
  }
}
