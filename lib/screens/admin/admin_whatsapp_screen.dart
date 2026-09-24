import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/portal_models.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminWhatsAppScreen extends StatefulWidget {
  final UserModel user;

  const AdminWhatsAppScreen({super.key, required this.user});

  @override
  State<AdminWhatsAppScreen> createState() => _AdminWhatsAppScreenState();
}

class _AdminWhatsAppScreenState extends State<AdminWhatsAppScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Broadcast Tab Controllers
  String _selectedAudience = 'All Registered Students';
  final _phoneCtrl = TextEditingController(text: '+44 7911 123456');
  final _broadcastMsgCtrl = TextEditingController();
  String _selectedTemplate = 'Custom Message';

  final Map<String, String> _templates = {
    'Custom Message': '',
    'Order Status Update':
        'Hello! Your assignment draft has been updated by your allocated academic expert. Please login to your student dashboard to review the progress.',
    'Special Discount Promo':
        'Great news! Ace Assignment Helps is offering an exclusive 20% discount on all dissertation and essay orders this week with code ACE20.',
    'Payment Milestone Reminder':
        'Friendly reminder from Ace Assignment Helps accounts: Your 50% milestone payment is pending to unlock the final verified solution files.',
    'Solution Ready for Download':
        'Congratulations! Your assignment solution has successfully passed QA inspection and Turnitin plagiarism scan and is ready for download in your portal.',
  };

  // Support Desk Controllers
  final _chatMsgCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController(text: 'STU-1001');
  List<ChatMessageModel> _chatMessages = [];
  bool _chatLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchChat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneCtrl.dispose();
    _broadcastMsgCtrl.dispose();
    _chatMsgCtrl.dispose();
    _studentIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchChat() async {
    setState(() => _chatLoading = true);
    final msgs = await ApiService.getChatMessages(studentId: _studentIdCtrl.text.trim());
    if (mounted) {
      setState(() {
        _chatMessages = msgs;
        _chatLoading = false;
      });
    }
  }

  Future<void> _sendChatMessage() async {
    final text = _chatMsgCtrl.text.trim();
    if (text.isEmpty) return;

    _chatMsgCtrl.clear();
    final res = await ApiService.sendChatMessage(
      senderId: widget.user.id,
      senderRole: 'Admin',
      senderName: widget.user.name,
      studentId: _studentIdCtrl.text.trim(),
      message: text,
    );

    if (res != null) {
      _fetchChat();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send admin reply'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<void> _dispatchWhatsApp() async {
    final text = _broadcastMsgCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a message to dispatch'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    final phone = _phoneCtrl.text.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(text)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WhatsApp dispatched to $phone!'), backgroundColor: AppTheme.success),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp for $phone'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('WhatsApp & Support Console'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textDim,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Broadcast Dispatch', icon: Icon(Icons.send_to_mobile_rounded, size: 20)),
            Tab(text: 'Live Student Desk', icon: Icon(Icons.forum_outlined, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBroadcastTab(),
          _buildSupportDeskTab(),
        ],
      ),
    );
  }

  Widget _buildBroadcastTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFF25D366),
                  radius: 22,
                  child: Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WhatsApp Broadcast Desk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Direct outbound dispatches & client notification templates', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Target Audience', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedAudience,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.group_outlined)),
                    items: const [
                      DropdownMenuItem(value: 'All Registered Students', child: Text('All Registered Students')),
                      DropdownMenuItem(value: 'All Academic Experts', child: Text('All Academic Experts')),
                      DropdownMenuItem(value: 'Staff Allocators', child: Text('Staff Allocators')),
                      DropdownMenuItem(value: 'Specific Student Phone', child: Text('Specific Student / Phone Number')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedAudience = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  const Text('Recipient Phone / WhatsApp *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: '+44 7911 123456 or +91 8233432123',
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Pre-set Message Template', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedTemplate,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.format_quote_rounded)),
                    items: _templates.keys.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedTemplate = val;
                          if (val != 'Custom Message') {
                            _broadcastMsgCtrl.text = _templates[val] ?? '';
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  const Text('Message Body Content *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _broadcastMsgCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Type your message or edit template text here...',
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _dispatchWhatsApp,
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      label: const Text('Launch WhatsApp Dispatch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportDeskTab() {
    return Column(
      children: [
        // Target Student bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Row(
            children: [
              const Text('Student ID:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _studentIdCtrl,
                  decoration: const InputDecoration(
                    hintText: 'STU-1001',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _fetchChat,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                child: const Text('Load'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Chat conversation
        Expanded(
          child: _chatLoading
              ? const Center(child: CircularProgressIndicator())
              : _chatMessages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppTheme.textDim),
                          const SizedBox(height: 8),
                          Text('No messages with ${_studentIdCtrl.text}', style: const TextStyle(color: AppTheme.textMuted)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _chatMessages.length,
                      itemBuilder: (ctx, i) {
                        final m = _chatMessages[i];
                        final isAdmin = m.senderRole.toLowerCase() == 'admin';

                        return Align(
                          alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            decoration: BoxDecoration(
                              color: isAdmin ? AppTheme.primary : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isAdmin ? AppTheme.primary : AppTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.senderName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isAdmin ? Colors.white70 : AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  m.message,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isAdmin ? Colors.white : AppTheme.textMain,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  m.createdAt,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isAdmin ? Colors.white60 : AppTheme.textDim,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),

        // Bottom send box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatMsgCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Type admin response...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onSubmitted: (_) => _sendChatMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppTheme.primary),
                onPressed: _sendChatMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
