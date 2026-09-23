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

  List<StudentDirectoryModel> get _filteredStudents {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _students;
    return _students.where((s) => s.name.toLowerCase().contains(query) || s.email.toLowerCase().contains(query) || s.studentId.toLowerCase().contains(query)).toList();
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStudents,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search by name, email, or student ID...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchCtrl.clear()))
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All Registered Students (${_filteredStudents.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                    const SizedBox(height: 12),
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
                                      s.name.isNotEmpty ? s.name[0] : 'S',
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
                                  OutlinedButton(
                                    onPressed: () => _toggleStatus(s),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: isActive ? AppTheme.danger : AppTheme.success),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    ),
                                    child: Text(
                                      isActive ? 'Block Student' : 'Unblock',
                                      style: TextStyle(fontSize: 12, color: isActive ? AppTheme.danger : AppTheme.success),
                                    ),
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
