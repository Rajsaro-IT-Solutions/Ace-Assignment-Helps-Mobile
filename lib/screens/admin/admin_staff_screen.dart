import 'package:flutter/material.dart';
import '../../core/models/portal_models.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminStaffScreen extends StatefulWidget {
  final UserModel user;

  const AdminStaffScreen({super.key, required this.user});

  @override
  State<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends State<AdminStaffScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<AdminStaffModel> _admins = [];
  List<AllocatorStaffModel> _allocators = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchStaff();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchStaff() async {
    setState(() => _loading = true);
    final adminsFuture = ApiService.getAdmins();
    final allocatorsFuture = ApiService.getAllocators();

    final results = await Future.wait([adminsFuture, allocatorsFuture]);

    if (mounted) {
      setState(() {
        _admins = results[0] as List<AdminStaffModel>;
        _allocators = results[1] as List<AllocatorStaffModel>;
        _loading = false;
      });
    }
  }

  void _showAddStaffDialog(bool isAllocator) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final pwdCtrl = TextEditingController(text: 'password');
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(isAllocator ? Icons.support_agent_rounded : Icons.shield_rounded, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(isAllocator ? 'Add New Allocator' : 'Add New Admin',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address *', prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone / WhatsApp', prefixIcon: Icon(Icons.phone_outlined)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pwdCtrl,
                  decoration: const InputDecoration(labelText: 'Password *', prefixIcon: Icon(Icons.lock_outline)),
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
                      final name = nameCtrl.text.trim();
                      final email = emailCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();
                      final pwd = pwdCtrl.text.trim();

                      if (name.isEmpty || email.isEmpty || pwd.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all required fields'), backgroundColor: AppTheme.warning),
                        );
                        return;
                      }

                      setDlgState(() => saving = true);

                      final ok = isAllocator
                          ? await ApiService.createAllocator(name: name, email: email, password: pwd, phone: phone)
                          : await ApiService.createAdmin(name: name, email: email, password: pwd, phone: phone);

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (ok) {
                        _fetchStaff();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('${isAllocator ? "Allocator" : "Admin"} created successfully!'),
                                backgroundColor: AppTheme.success),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to add staff member.'), backgroundColor: AppTheme.danger),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Add Staff'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStaffDialog({
    required bool isAllocator,
    required String id,
    required String initialName,
    required String initialPhone,
    required String initialStatus,
  }) {
    final nameCtrl = TextEditingController(text: initialName);
    final phoneCtrl = TextEditingController(text: initialPhone);
    final pwdCtrl = TextEditingController();
    String selectedStatus = initialStatus;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.edit_note_rounded, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(isAllocator ? 'Edit Allocator' : 'Edit Admin',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone / WhatsApp', prefixIcon: Icon(Icons.phone_outlined)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pwdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Change Password (Leave blank to keep)',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Account Status', prefixIcon: Icon(Icons.shield_outlined)),
                  items: const [
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedStatus = val);
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
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;

                      setDlgState(() => saving = true);
                      final pwd = pwdCtrl.text.trim().isNotEmpty ? pwdCtrl.text.trim() : null;

                      final ok = isAllocator
                          ? await ApiService.updateAllocator(
                              allocatorId: id,
                              name: name,
                              phone: phoneCtrl.text.trim(),
                              status: selectedStatus,
                              password: pwd,
                            )
                          : await ApiService.updateAdmin(
                              adminId: id,
                              name: name,
                              phone: phoneCtrl.text.trim(),
                              status: selectedStatus,
                              password: pwd,
                            );

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (ok) {
                        _fetchStaff();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Staff details updated!'), backgroundColor: AppTheme.success),
                          );
                        }
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

  void _confirmDeleteStaff(bool isAllocator, String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${isAllocator ? "Allocator" : "Admin"}'),
        content: Text('Are you sure you want to remove $name ($id) from system staff?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Remove Staff'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = isAllocator ? await ApiService.deleteAllocator(id) : await ApiService.deleteAdmin(id);

    if (mounted) {
      if (ok) {
        _fetchStaff();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name removed successfully'), backgroundColor: AppTheme.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove staff member.'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  void _toggleStaff(bool isAllocator, String id, String currentStatus) async {
    final newStatus = currentStatus.toLowerCase() == 'active' ? 'Inactive' : 'Active';
    final ok = await ApiService.toggleStaffStatus(isAllocator ? 'Allocator' : 'Admin', id, newStatus);
    if (mounted && ok) {
      _fetchStaff();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status changed to $newStatus'), backgroundColor: AppTheme.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Platform Staff Roster'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textDim,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Allocators (${_allocators.length})', icon: const Icon(Icons.support_agent_rounded, size: 20)),
            Tab(text: 'Admins (${_admins.length})', icon: const Icon(Icons.shield_outlined, size: 20)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStaffDialog(_tabController.index == 0),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'Add Allocator' : 'Add Admin',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllocatorsTab(),
                _buildAdminsTab(),
              ],
            ),
    );
  }

  Widget _buildAllocatorsTab() {
    if (_allocators.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.support_agent_rounded, size: 54, color: AppTheme.textDim),
            const SizedBox(height: 12),
            const Text('No allocators registered', style: TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () => _showAddStaffDialog(true), child: const Text('Add First Allocator')),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _allocators.length,
      itemBuilder: (ctx, i) {
        final a = _allocators[i];
        final isActive = a.status.toLowerCase() == 'active';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.warning.withValues(alpha: 0.15),
                      child: const Icon(Icons.support_agent_rounded, color: AppTheme.warning),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(a.email, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          if (a.phone.isNotEmpty) Text('📞 ${a.phone}', style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _toggleStaff(true, a.allocatorId, a.status),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.successBg : AppTheme.dangerBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          a.status,
                          style: TextStyle(
                            color: isActive ? AppTheme.success : AppTheme.danger,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ID: ${a.allocatorId}', style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary),
                          tooltip: 'Edit Allocator',
                          onPressed: () => _showEditStaffDialog(
                            isAllocator: true,
                            id: a.allocatorId,
                            initialName: a.name,
                            initialPhone: a.phone,
                            initialStatus: a.status,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.danger),
                          tooltip: 'Remove Allocator',
                          onPressed: () => _confirmDeleteStaff(true, a.allocatorId, a.name),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminsTab() {
    if (_admins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, size: 54, color: AppTheme.textDim),
            const SizedBox(height: 12),
            const Text('No admins found', style: TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () => _showAddStaffDialog(false), child: const Text('Add Administrator')),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _admins.length,
      itemBuilder: (ctx, i) {
        final a = _admins[i];
        final isActive = a.status.toLowerCase() == 'active';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryLight,
                      child: const Icon(Icons.shield_rounded, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(a.email, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          if (a.phone.isNotEmpty) Text('📞 ${a.phone}', style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _toggleStaff(false, a.adminId, a.status),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.successBg : AppTheme.dangerBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          a.status,
                          style: TextStyle(
                            color: isActive ? AppTheme.success : AppTheme.danger,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ID: ${a.adminId}', style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary),
                          tooltip: 'Edit Admin',
                          onPressed: () => _showEditStaffDialog(
                            isAllocator: false,
                            id: a.adminId,
                            initialName: a.name,
                            initialPhone: a.phone,
                            initialStatus: a.status,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.danger),
                          tooltip: 'Remove Admin',
                          onPressed: () => _confirmDeleteStaff(false, a.adminId, a.name),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
