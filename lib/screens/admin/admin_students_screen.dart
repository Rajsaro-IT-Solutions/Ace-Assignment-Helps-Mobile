import 'package:flutter/material.dart';
import '../../core/models/portal_models.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminStudentsScreen extends StatefulWidget {
  final UserModel user;

  const AdminStudentsScreen({super.key, required this.user});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  bool _loading = true;
  List<StudentDirectoryModel> _students = [];
  final _searchCtrl = TextEditingController();
  String _selectedStatusFilter = 'All';

  final List<String> _countries = [
    'United Kingdom',
    'United States',
    'Australia',
    'Ireland',
    'Canada',
    'India',
    'New Zealand',
    'Singapore',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    final list = await ApiService.getStudents();
    if (mounted) {
      setState(() {
        _students = list;
        _loading = false;
      });
    }
  }

  Future<void> _toggleStatus(StudentDirectoryModel s) async {
    final newStatus = s.status.toLowerCase() == 'active' ? 'Blocked' : 'Active';
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ApiService.toggleUserStatus(
      targetRole: 'Student',
      targetId: s.studentId,
      status: newStatus,
    );
    if (!mounted) return;
    if (ok) {
      _loadStudents();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Student ${s.name} is now $newStatus.'),
          backgroundColor: newStatus == 'Active' ? AppTheme.success : AppTheme.danger,
        ),
      );
    }
  }

  void _showStudentDialog({StudentDirectoryModel? student}) {
    final isEdit = student != null;
    final nameCtrl = TextEditingController(text: student?.name ?? '');
    final emailCtrl = TextEditingController(text: student?.email ?? '');
    final phoneCtrl = TextEditingController(text: student?.phone ?? '');
    String selectedCountry = (student != null && _countries.contains(student.country))
        ? student.country
        : _countries.first;
    final uniCtrl = TextEditingController(text: student?.university ?? '');
    final courseCtrl = TextEditingController(text: student?.course ?? '');
    final pwdCtrl = TextEditingController(text: isEdit ? '' : 'password');
    String selectedStatus = student?.status ?? 'Active';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(isEdit ? Icons.manage_accounts_rounded : Icons.person_add_alt_1_rounded,
                  color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                isEdit ? 'Edit Student Profile' : 'Register New Student',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'e.g. John Smith',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                if (!isEdit)
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address *',
                      hintText: 'student@university.edu',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                if (!isEdit) const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone / WhatsApp',
                    hintText: '+44 7911 123456',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCountry,
                  decoration: const InputDecoration(
                    labelText: 'Country / Jurisdiction',
                    prefixIcon: Icon(Icons.public_outlined),
                  ),
                  items: _countries.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedCountry = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: uniCtrl,
                  decoration: const InputDecoration(
                    labelText: 'University / College',
                    hintText: 'e.g. King’s College London',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: courseCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Course / Major',
                    hintText: 'e.g. Computer Science BSc',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pwdCtrl,
                  decoration: InputDecoration(
                    labelText: isEdit ? 'Change Password (Leave blank to keep)' : 'Initial Password *',
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Account Status',
                    prefixIcon: Icon(Icons.shield_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Active', child: Text('Active (Login Allowed)')),
                    DropdownMenuItem(value: 'Blocked', child: Text('Blocked (Access Restricted)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedStatus = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final email = emailCtrl.text.trim();
                      if (name.isEmpty || (!isEdit && email.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all required fields'), backgroundColor: AppTheme.warning),
                        );
                        return;
                      }

                      setDlgState(() => saving = true);
                      bool ok = false;
                      if (isEdit) {
                        ok = await ApiService.updateStudent(
                          studentId: student.studentId,
                          name: name,
                          phone: phoneCtrl.text.trim(),
                          country: selectedCountry,
                          university: uniCtrl.text.trim(),
                          course: courseCtrl.text.trim(),
                          password: pwdCtrl.text.trim().isNotEmpty ? pwdCtrl.text.trim() : null,
                          status: selectedStatus,
                        );
                      } else {
                        ok = await ApiService.createStudent(
                          name: name,
                          email: email,
                          password: pwdCtrl.text.trim().isNotEmpty ? pwdCtrl.text.trim() : 'password',
                          phone: phoneCtrl.text.trim(),
                          country: selectedCountry,
                          university: uniCtrl.text.trim(),
                          course: courseCtrl.text.trim(),
                          status: selectedStatus,
                        );
                      }

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);

                      if (ok) {
                        _loadStudents();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit ? 'Student updated successfully!' : 'Student account registered!'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Operation failed. Please verify connection.'), backgroundColor: AppTheme.danger),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? 'Save Changes' : 'Register Student'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteStudent(StudentDirectoryModel student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student Account'),
        content: Text(
          'Are you sure you want to permanently delete ${student.name} (${student.studentId})?\nThis will remove their profile and credentials.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete Student'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await ApiService.deleteStudent(student.studentId);
    if (mounted) {
      if (ok) {
        _loadStudents();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student ${student.name} deleted successfully.'), backgroundColor: AppTheme.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete student account.'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  List<StudentDirectoryModel> get _filteredStudents {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _students.where((s) {
      final matchesQuery = query.isEmpty ||
          s.name.toLowerCase().contains(query) ||
          s.email.toLowerCase().contains(query) ||
          s.studentId.toLowerCase().contains(query) ||
          s.university.toLowerCase().contains(query);

      final matchesStatus = _selectedStatusFilter == 'All' ||
          s.status.toLowerCase() == _selectedStatusFilter.toLowerCase();

      return matchesQuery && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Registered Students'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadStudents),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStudentDialog(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('Register Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStudents,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search by name, email, or student ID...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _searchCtrl.clear()),
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Filter:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                        const SizedBox(width: 8),
                        Wrap(
                          spacing: 6,
                          children: ['All', 'Active', 'Blocked'].map((st) {
                            final isSel = _selectedStatusFilter == st;
                            return ChoiceChip(
                              label: Text(st, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : AppTheme.textMain)),
                              selected: isSel,
                              selectedColor: AppTheme.primary,
                              onSelected: (_) => setState(() => _selectedStatusFilter = st),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All Registered Students (${_filteredStudents.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                    const SizedBox(height: 12),
                    if (_filteredStudents.isEmpty)
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
                            Icon(Icons.person_off_outlined, size: 48, color: AppTheme.textDim),
                            SizedBox(height: 12),
                            Text('No students found', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredStudents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final s = _filteredStudents[i];
                          final isActive = s.status.toLowerCase() == 'active';

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
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppTheme.primaryLight,
                                      child: Text(
                                        s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                          Text(s.email, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                          if (s.phone.isNotEmpty)
                                            Text('📞 ${s.phone}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                          if (s.university.isNotEmpty)
                                            Text('🏫 ${s.university}', style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isActive ? AppTheme.successBg : AppTheme.dangerBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        s.status,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isActive ? AppTheme.success : AppTheme.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Orders: ${s.totalOrders} • Spent: \$${s.totalSpent.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                                        ),
                                        Text('ID: ${s.studentId}', style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary),
                                          tooltip: 'Edit Profile',
                                          onPressed: () => _showStudentDialog(student: s),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.danger),
                                          tooltip: 'Delete Student',
                                          onPressed: () => _confirmDeleteStudent(s),
                                        ),
                                        OutlinedButton(
                                          onPressed: () => _toggleStatus(s),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: isActive ? AppTheme.danger : AppTheme.success),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          ),
                                          child: Text(
                                            isActive ? 'Block' : 'Unblock',
                                            style: TextStyle(fontSize: 12, color: isActive ? AppTheme.danger : AppTheme.success),
                                          ),
                                        ),
                                      ],
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
