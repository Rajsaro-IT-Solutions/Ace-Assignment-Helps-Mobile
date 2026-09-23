import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/models/portal_models.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class StudentMessagesScreen extends StatefulWidget {
  final UserModel user;

  const StudentMessagesScreen({super.key, required this.user});

  @override
  State<StudentMessagesScreen> createState() => _StudentMessagesScreenState();
}

class _StudentMessagesScreenState extends State<StudentMessagesScreen> {
  bool _loading = true;
  List<SupportTicketModel> _tickets = [];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _loading = true);
    final list = await ApiService.getSupportTickets(userId: widget.user.id, role: 'Student');
    if (mounted) {
      setState(() {
        _tickets = list;
        _loading = false;
      });
    }
  }

  void _showNewTicketDialog() {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String priority = 'Medium';
    bool submitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.support_agent_rounded, color: AppTheme.primary),
                SizedBox(width: 8),
                Text('New Support Ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Subject *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: subjectCtrl,
                    decoration: const InputDecoration(hintText: 'e.g. Question regarding citation format'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: priority,
                    items: ['Low', 'Medium', 'High', 'Urgent']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDlgState(() => priority = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Message / Inquiry *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: messageCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(hintText: 'Describe your query or request...'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: submitting
                    ? null
                    : () async {
                        if (subjectCtrl.text.trim().isEmpty || messageCtrl.text.trim().isEmpty) return;
                        setDlgState(() => submitting = true);
                        final navigator = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await ApiService.createSupportTicket(
                          userId: widget.user.id,
                          subject: subjectCtrl.text.trim(),
                          message: messageCtrl.text.trim(),
                          priority: priority,
                        );
                        if (!mounted) return;
                        navigator.pop();
                        if (ok) {
                          _loadTickets();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Support ticket created successfully!'), backgroundColor: AppTheme.success),
                          );
                        }
                      },
                child: submitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create Ticket'),
              ),
            ],
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
        title: const Text('Support & Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded),
            tooltip: 'New Ticket',
            onPressed: _showNewTicketDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTickets,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewTicketDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Ticket'),
        backgroundColor: AppTheme.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTickets,
              child: _tickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 56, color: AppTheme.textDim),
                          const SizedBox(height: 16),
                          const Text('No support tickets yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text('Have a question about your order? Open a ticket anytime.', style: TextStyle(color: AppTheme.textMuted)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showNewTicketDialog,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Create Support Ticket'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tickets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final t = _tickets[i];
                        final isOpen = t.status.toLowerCase() == 'open';

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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      t.ticketId,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isOpen ? AppTheme.successBg : AppTheme.border,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      t.status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isOpen ? AppTheme.success : AppTheme.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                t.subject,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                t.message,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Priority: ${t.priority}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textDim),
                                  ),
                                  Text(
                                    t.createdAt.split(' ')[0],
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textDim),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
