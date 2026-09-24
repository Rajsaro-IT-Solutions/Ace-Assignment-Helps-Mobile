import 'package:flutter/material.dart';
import '../../core/models/portal_models.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminExpertsScreen extends StatefulWidget {
  final UserModel user;

  const AdminExpertsScreen({super.key, required this.user});

  @override
  State<AdminExpertsScreen> createState() => _AdminExpertsScreenState();
}

class _AdminExpertsScreenState extends State<AdminExpertsScreen> {
  bool _loading = true;
  List<ExpertModel> _experts = [];
  List<ExpertModel> _filtered = [];
  final _searchCtrl = TextEditingController();
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchExperts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchExperts() async {
    setState(() => _loading = true);
    final list = await ApiService.getExperts();
    if (mounted) {
      setState(() {
        _experts = list;
        _applyFilter();
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = _experts.where((e) {
        final matchesQuery = query.isEmpty ||
            e.name.toLowerCase().contains(query) ||
            e.email.toLowerCase().contains(query) ||
            e.subjects.toLowerCase().contains(query) ||
            e.expertId.toLowerCase().contains(query);

        final matchesStatus = _selectedStatusFilter == 'All' ||
            e.status.toLowerCase() == _selectedStatusFilter.toLowerCase();

        return matchesQuery && matchesStatus;
      }).toList();
    });
  }

  void _showExpertDialog({ExpertModel? expert}) {
    final isEdit = expert != null;
    final nameCtrl = TextEditingController(text: expert?.name ?? '');
    final emailCtrl = TextEditingController(text: expert?.email ?? '');
    final phoneCtrl = TextEditingController(text: expert?.phone ?? '');
    final subjectsCtrl = TextEditingController(text: expert?.subjects ?? '');
    final pwdCtrl = TextEditingController(text: isEdit ? '' : 'password');
    String selectedStatus = expert?.status ?? 'Available';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(isEdit ? Icons.badge_outlined : Icons.person_add_alt_1_rounded, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                isEdit ? 'Edit Specialist' : 'Onboard New Expert',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name & Degree *',
                    hintText: 'Dr. Sarah Jenkins, PhD',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                if (!isEdit)
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address *',
                      hintText: 'expert@aceassign.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                if (!isEdit) const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone / WhatsApp',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: subjectsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subjects (comma-separated)',
                    hintText: 'Computer Science, AI, Finance',
                    prefixIcon: Icon(Icons.book_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pwdCtrl,
                  decoration: InputDecoration(
                    labelText: isEdit ? 'Change Password (Leave blank to keep)' : 'Initial Password *',
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Availability Status',
                    prefixIcon: Icon(Icons.toggle_on_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Available', child: Text('Available (Ready for Allocation)')),
                    DropdownMenuItem(value: 'Busy', child: Text('Busy (Max Capacity)')),
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
                      final email = emailCtrl.text.trim();
                      final subjects = subjectsCtrl.text.trim();
                      final pwd = pwdCtrl.text.trim();

                      if (name.isEmpty || (!isEdit && email.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all required fields'), backgroundColor: AppTheme.warning),
                        );
                        return;
                      }

                      setDlgState(() => saving = true);
                      bool ok = false;
                      if (isEdit) {
                        ok = await ApiService.updateExpert(
                          expertId: expert.expertId,
                          name: name,
                          phone: phoneCtrl.text.trim(),
                          subjects: subjects,
                          status: selectedStatus,
                          password: pwd.isNotEmpty ? pwd : null,
                        );
                      } else {
                        ok = await ApiService.createExpert(
                          name: name,
                          email: email,
                          password: pwd.isNotEmpty ? pwd : 'password',
                          phone: phoneCtrl.text.trim(),
                          subjects: subjects,
                        );
                      }

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (ok) {
                        _fetchExperts();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit ? 'Specialist details updated!' : 'Expert added to academic roster!'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to save expert details.'), backgroundColor: AppTheme.danger),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? 'Save Changes' : 'Add Specialist'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteExpert(String expertId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('De-register Specialist'),
        content: Text('Are you sure you want to remove $name ($expertId) from the active academic roster?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Remove Expert'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await ApiService.deleteExpert(expertId);
    if (mounted) {
      if (ok) {
        _fetchExperts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name removed successfully'), backgroundColor: AppTheme.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove expert.'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  void _toggleExpertStatus(ExpertModel e) async {
    final newStatus = e.status == 'Available' ? 'Busy' : 'Available';
    final ok = await ApiService.toggleExpertStatus(e.expertId, newStatus);
    if (mounted) {
      if (ok) {
        _fetchExperts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${e.name} is now $newStatus'), backgroundColor: AppTheme.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Academic Experts Roster'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchExperts),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpertDialog(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('Add Expert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _applyFilter(),
                  decoration: InputDecoration(
                    hintText: 'Search by expert name, email or subject...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchCtrl.clear();
                              _applyFilter();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Status Filter:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 6,
                      children: ['All', 'Available', 'Busy'].map((s) {
                        final isSel = _selectedStatusFilter == s;
                        return ChoiceChip(
                          label: Text(s, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : AppTheme.textMain)),
                          selected: isSel,
                          selectedColor: AppTheme.primary,
                          onSelected: (_) {
                            setState(() => _selectedStatusFilter = s);
                            _applyFilter();
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.school_outlined, size: 54, color: AppTheme.textDim),
                            const SizedBox(height: 12),
                            const Text('No experts found matching query', style: TextStyle(color: AppTheme.textMuted)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _showExpertDialog(),
                              icon: const Icon(Icons.person_add_alt_1_rounded),
                              label: const Text('Add Specialist'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) {
                          final e = _filtered[i];
                          final isAvail = e.status == 'Available';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: AppTheme.primaryLight,
                                        child: Text(
                                          e.name.isNotEmpty ? e.name[0].toUpperCase() : 'E',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 18),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(e.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            Text(e.email, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                            if (e.phone.isNotEmpty) Text('📞 ${e.phone}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _toggleExpertStatus(e),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isAvail ? AppTheme.success.withValues(alpha: 0.15) : AppTheme.warning.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            e.status,
                                            style: TextStyle(
                                              color: isAvail ? AppTheme.success : AppTheme.warning,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: e.subjects
                                        .split(',')
                                        .map((s) => s.trim())
                                        .where((s) => s.isNotEmpty)
                                        .map((s) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryLight,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(s, style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                                        ))
                                        .toList(),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Text(
                                        'Active Load: ${e.activeTasks} assignments',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary),
                                        tooltip: 'Edit Expert',
                                        onPressed: () => _showExpertDialog(expert: e),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.danger),
                                        tooltip: 'Remove Expert',
                                        onPressed: () => _confirmDeleteExpert(e.expertId, e.name),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
