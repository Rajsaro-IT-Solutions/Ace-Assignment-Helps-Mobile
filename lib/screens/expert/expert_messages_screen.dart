import 'package:flutter/material.dart';
import '../../core/models/portal_models.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class ExpertMessagesScreen extends StatefulWidget {
  final UserModel user;

  const ExpertMessagesScreen({super.key, required this.user});

  @override
  State<ExpertMessagesScreen> createState() => _ExpertMessagesScreenState();
}

class _ExpertMessagesScreenState extends State<ExpertMessagesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _msgTextCtrl = TextEditingController();
  final _asmIdCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();

  List<ChatMessageModel> _activeChat = [];
  bool _chatLoading = false;
  String _selectedAsmId = '';
  List<String> _myOrderIds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExpertOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _msgTextCtrl.dispose();
    _asmIdCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExpertOrders() async {
    final list = await ApiService.getAssignments(role: 'Expert', userId: widget.user.id);
    if (mounted) {
      setState(() {
        _myOrderIds = list.map((a) => a.assignmentId).toList();
        if (_myOrderIds.isNotEmpty && _selectedAsmId.isEmpty) {
          _selectedAsmId = _myOrderIds.first;
          _loadChat(_selectedAsmId);
        }
      });
    }
  }

  Future<void> _loadChat(String asmId) async {
    setState(() => _chatLoading = true);
    final msgs = await ApiService.getChat(asmId);
    if (mounted) {
      setState(() {
        _activeChat = msgs;
        _chatLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgTextCtrl.text.trim();
    if (text.isEmpty || _selectedAsmId.isEmpty) return;

    _msgTextCtrl.clear();
    final ok = await ApiService.sendChat(
      assignmentId: _selectedAsmId,
      senderId: widget.user.id,
      senderRole: 'Expert',
      senderName: widget.user.name,
      message: text,
      expertId: widget.user.id,
    );

    if (ok) {
      _loadChat(_selectedAsmId);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  void _showComposeSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.headset_mic_rounded, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Support Inquiry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Subject Topic *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: _subjectCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Dataset question for Order #104',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Related Order ID (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: _asmIdCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. ACE-2026-000101',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Query / Message *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: _msgTextCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe your clarification or note for the allocator...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support ticket dispatched to Admin & Allocator!'), backgroundColor: AppTheme.success),
              );
              _subjectCtrl.clear();
              _asmIdCtrl.clear();
              _msgTextCtrl.clear();
            },
            child: const Text('Send Inquiry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Order Communications & Support'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppTheme.secondary,
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble_outline_rounded, size: 20), text: 'Order Chat'),
            Tab(icon: Icon(Icons.support_agent_rounded, size: 20), text: 'Allocation Desk'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Live Order Chat
          Column(
            children: [
              // Order selector bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.white,
                child: Row(
                  children: [
                    const Text('Order: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    if (_myOrderIds.isEmpty)
                      const Text('No active assignments', style: TextStyle(color: AppTheme.textMuted, fontSize: 13))
                    else
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedAsmId.isNotEmpty ? _selectedAsmId : null,
                            isExpanded: true,
                            hint: const Text('Select Order'),
                            items: _myOrderIds.map((id) => DropdownMenuItem(value: id, child: Text(id, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedAsmId = val);
                                _loadChat(val);
                              }
                            },
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20, color: AppTheme.primary),
                      onPressed: () => _selectedAsmId.isNotEmpty ? _loadChat(_selectedAsmId) : _loadExpertOrders(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Chat history
              Expanded(
                child: _chatLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _activeChat.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.forum_outlined, size: 54, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  _selectedAsmId.isEmpty ? 'Select an order above' : 'No messages logged yet for $_selectedAsmId',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _activeChat.length,
                            itemBuilder: (ctx, i) {
                              final msg = _activeChat[i];
                              final isMe = msg.senderRole == 'Expert' || msg.senderId == widget.user.id;

                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isMe ? AppTheme.primary : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                                      bottomRight: Radius.circular(isMe ? 4 : 16),
                                    ),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${msg.senderName} (${msg.senderRole})',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isMe ? Colors.white70 : AppTheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        msg.message,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isMe ? Colors.white : AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        msg.timestamp.length >= 16 ? msg.timestamp.substring(11, 16) : msg.timestamp,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isMe ? Colors.white60 : AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),

              // Chat input bar
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgTextCtrl,
                          decoration: InputDecoration(
                            hintText: _selectedAsmId.isEmpty ? 'Select order to chat' : 'Type message to student/allocator...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          enabled: _selectedAsmId.isNotEmpty,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: _selectedAsmId.isNotEmpty ? AppTheme.primary : Colors.grey.shade300,
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          onPressed: _selectedAsmId.isNotEmpty ? _sendMessage : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Tab 2: Allocation Desk Ticket Log
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.contact_support_rounded, color: AppTheme.primary),
                            SizedBox(width: 8),
                            Text('Allocation Team Communications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Have urgent questions regarding task brief files, deadlines, or pricing extensions? Submit a ticket directly to the allocator queue.',
                          style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showComposeSupportDialog,
                            icon: const Icon(Icons.add_comment_rounded),
                            label: const Text('Open Allocation Inquiry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Recent Inquiries', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE0F2FE),
                      child: Icon(Icons.assignment_turned_in_rounded, color: AppTheme.primary),
                    ),
                    title: const Text('Clarification on Statistical Tool', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Order: ACE-2026-000101 • Status: Open', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.info.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Open', style: TextStyle(color: AppTheme.info, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
