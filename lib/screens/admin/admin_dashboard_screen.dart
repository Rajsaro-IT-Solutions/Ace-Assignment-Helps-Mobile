import 'package:flutter/material.dart';
import '../../core/models/assignment_model.dart';
import '../../core/models/dashboard_stats_model.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/assignment_card.dart';
import '../../widgets/stat_card.dart';
import '../common/assignment_detail_sheet.dart';
import '../login_screen.dart';
import 'admin_backup_screen.dart';
import 'admin_blogs_screen.dart';
import 'admin_courses_screen.dart';
import 'admin_coupons_screen.dart';
import 'admin_experts_screen.dart';
import 'admin_history_screen.dart';
import 'admin_logs_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_payments_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_staff_screen.dart';
import 'admin_students_screen.dart';
import 'admin_whatsapp_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserModel user;

  const AdminDashboardScreen({super.key, required this.user});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentBottomNav = 0;
  bool _loading = true;
  DashboardData? _dashboard;
  List<AssignmentModel> _assignments = [];
  String _selectedStatus = 'All';
  String _selectedPriority = 'All';
  final _searchCtrl = TextEditingController();

  final List<String> _statusFilters = ['All', 'Pending', 'In Progress', 'Under QA', 'Completed'];
  final List<String> _priorityFilters = ['All', 'Standard', 'Urgent', 'Express 24h'];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);

    final dashboardFuture = ApiService.getDashboard(
      role: 'Admin',
      userId: widget.user.id,
    );

    final assignmentsFuture = ApiService.getAssignments(
      role: 'Admin',
      userId: widget.user.id,
      status: _selectedStatus,
    );

    final results = await Future.wait([dashboardFuture, assignmentsFuture]);

    if (mounted) {
      setState(() {
        _dashboard = results[0] as DashboardData?;
        _assignments = results[1] as List<AssignmentModel>;
        _loading = false;
      });
    }
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to sign out of the executive portal?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  void _openStudentsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminStudentsScreen(user: widget.user)),
    );
  }

  void _openPaymentsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminPaymentsScreen(user: widget.user)),
    );
  }

  void _openCouponsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminCouponsScreen(user: widget.user)),
    );
  }

  void _openExpertsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminExpertsScreen(user: widget.user)),
    );
  }

  void _openStaffScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminStaffScreen(user: widget.user)),
    );
  }

  void _openWhatsAppScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminWhatsAppScreen(user: widget.user)),
    );
  }

  void _openCoursesScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminCoursesScreen(user: widget.user)),
    );
  }

  void _openBlogsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminBlogsScreen(user: widget.user)),
    );
  }

  void _openLogsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminLogsScreen(user: widget.user)),
    );
  }

  void _openSettingsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminSettingsScreen(user: widget.user)),
    );
  }

  void _openHistoryScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminHistoryScreen(user: widget.user)),
    );
  }

  void _openReportsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminReportsScreen(user: widget.user)),
    );
  }

  void _openBackupScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminBackupScreen(user: widget.user)),
    );
  }

  void _openNotificationsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminNotificationsScreen(user: widget.user)),
    );
  }

  void _showCreateOrderDialog() {
    final titleCtrl = TextEditingController();
    final studentIdCtrl = TextEditingController(text: 'STU-1001');
    final subjectCtrl = TextEditingController(text: 'Computer Science');
    final wordsCtrl = TextEditingController(text: '2000');
    final priceCtrl = TextEditingController(text: '90.00');
    final instructionsCtrl = TextEditingController();
    String selectedType = 'Assignment';
    String selectedPriority = 'Standard';
    bool creating = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.add_shopping_cart_rounded, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Create New Assignment Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Assignment Title *', hintText: 'e.g. Machine Learning Classifier'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: studentIdCtrl,
                  decoration: const InputDecoration(labelText: 'Student ID or Email *', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: subjectCtrl,
                        decoration: const InputDecoration(labelText: 'Subject *', prefixIcon: Icon(Icons.book_outlined)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const [
                          DropdownMenuItem(value: 'Assignment', child: Text('Assignment')),
                          DropdownMenuItem(value: 'Essay', child: Text('Essay')),
                          DropdownMenuItem(value: 'Dissertation', child: Text('Dissertation')),
                          DropdownMenuItem(value: 'Case Study', child: Text('Case Study')),
                          DropdownMenuItem(value: 'Programming', child: Text('Programming')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDlgState(() => selectedType = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: wordsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Word Count', prefixIcon: Icon(Icons.format_size_rounded)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Price (USD \$) *', prefixIcon: Icon(Icons.attach_money_rounded)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: const InputDecoration(labelText: 'Priority / Urgency', prefixIcon: Icon(Icons.timer_outlined)),
                  items: const [
                    DropdownMenuItem(value: 'Standard', child: Text('Standard (5-7 Days)')),
                    DropdownMenuItem(value: 'Urgent', child: Text('Urgent (2-3 Days)')),
                    DropdownMenuItem(value: 'Express', child: Text('Express 24h Delivery')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedPriority = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: instructionsCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Instructions / Brief', hintText: 'Specific requirements, referencing style...'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: creating
                  ? null
                  : () async {
                      final title = titleCtrl.text.trim();
                      final sid = studentIdCtrl.text.trim();
                      final sub = subjectCtrl.text.trim();
                      final pr = double.tryParse(priceCtrl.text.trim()) ?? 50.0;
                      final wc = int.tryParse(wordsCtrl.text.trim()) ?? 1500;

                      if (title.isEmpty || sid.isEmpty || sub.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all required fields'), backgroundColor: AppTheme.warning),
                        );
                        return;
                      }

                      setDlgState(() => creating = true);
                      final res = await ApiService.submitAssignment(
                        studentId: sid,
                        title: title,
                        subject: sub,
                        assignmentType: selectedType,
                        deadline: DateTime.now().add(const Duration(days: 5)).toIso8601String(),
                        wordCount: wc,
                        referenceStyle: 'APA 7th Edition',
                        description: instructionsCtrl.text.trim(),
                        currency: 'USD',
                        price: pr,
                      );

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);

                      if (res.success) {
                        _fetchData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('New order placed & booked successfully!'), backgroundColor: AppTheme.success),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to book assignment.'), backgroundColor: AppTheme.danger),
                          );
                        }
                      }
                    },
              child: creating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Book Order'),
            ),
          ],
        ),
      ),
    );
  }

  List<AssignmentModel> get _filteredAssignments {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _assignments.where((a) {
      final matchesQuery = query.isEmpty ||
          a.assignmentId.toLowerCase().contains(query) ||
          a.title.toLowerCase().contains(query) ||
          a.studentId.toLowerCase().contains(query) ||
          a.subject.toLowerCase().contains(query);

      final matchesPriority = _selectedPriority == 'All' ||
          a.priority.toLowerCase().contains(_selectedPriority.toLowerCase());

      return matchesQuery && matchesPriority;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: 26, width: 26),
            const SizedBox(width: 8),
            const Flexible(
              child: Text('Executive Admin', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notification Center',
            icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.primary),
            onPressed: _openNotificationsScreen,
          ),
          IconButton(
            tooltip: 'Live Support Console',
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366)),
            onPressed: _openWhatsAppScreen,
          ),
          IconButton(
            tooltip: 'Platform Settings',
            icon: const Icon(Icons.tune_rounded, color: AppTheme.primary),
            onPressed: _openSettingsScreen,
          ),
          IconButton(
            tooltip: 'Financial Ledger',
            icon: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.textMuted),
            onPressed: _openPaymentsScreen,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: _buildCurrentView(),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentBottomNav,
        onTap: (i) {
          if (i == 2) {
            _openStudentsScreen();
          } else if (i == 3) {
            _openPaymentsScreen();
          } else {
            setState(() => _currentBottomNav = i);
          }
        },
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textDim,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'Executive',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_shared_outlined),
            label: 'Assignments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.paid_outlined),
            label: 'Financials',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    if (_currentBottomNav == 1) {
      return _buildMasterAssignmentsView();
    }
    return _buildOverview();
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(widget.user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            accountEmail: Text(widget.user.email, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppTheme.primary,
              child: Text(widget.user.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('EXECUTIVE ADMIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textDim)),
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined, color: AppTheme.primary),
            title: const Text('Executive Dashboard'),
            selected: _currentBottomNav == 0,
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentBottomNav = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_shared_outlined, color: AppTheme.primary),
            title: const Text('Master Assignments'),
            selected: _currentBottomNav == 1,
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentBottomNav = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_edu_rounded, color: AppTheme.primary),
            title: const Text('Assignment History & Trash'),
            onTap: () {
              Navigator.pop(context);
              _openHistoryScreen();
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_rounded, color: AppTheme.primary),
            title: const Text('Courses & Subjects'),
            onTap: () {
              Navigator.pop(context);
              _openCoursesScreen();
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_outlined, color: AppTheme.primary),
            title: const Text('Registered Students'),
            onTap: () {
              Navigator.pop(context);
              _openStudentsScreen();
            },
          ),
          ListTile(
            leading: const Icon(Icons.school_outlined, color: AppTheme.primary),
            title: const Text('Expert Roster'),
            onTap: () {
              Navigator.pop(context);
              _openExpertsScreen();
            },
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined, color: AppTheme.primary),
            title: const Text('Staff (Admins & Allocators)'),
            onTap: () {
              Navigator.pop(context);
              _openStaffScreen();
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('FINANCE & MARKETING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textDim)),
          ),
          ListTile(
            leading: const Icon(Icons.paid_outlined, color: AppTheme.primary),
            title: const Text('Financial Logs'),
            onTap: () {
              Navigator.pop(context);
              _openPaymentsScreen();
            },
          ),
          ListTile(
            leading: const Icon(Icons.confirmation_number_outlined, color: AppTheme.primary),
            title: const Text('Coupons System'),
            onTap: () {
              Navigator.pop(context);
              _openCouponsScreen();
            },
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined, color: AppTheme.primary),
            title: const Text('Blog Articles'),
            onTap: () {
              Navigator.pop(context);
              _openBlogsScreen();
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366)),
            title: const Text('WhatsApp Broadcast Desk'),
            onTap: () {
              Navigator.pop(context);
              _openWhatsAppScreen();
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('SYSTEM & ANALYTICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textDim)),
          ),
          ListTile(
            leading: const Icon(Icons.insert_chart_outlined_rounded, color: AppTheme.primary),
            title: const Text('Analytics & CSV Reports'),
            onTap: () {
              Navigator.pop(context);
              _openReportsScreen();
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined, color: AppTheme.primary),
            title: const Text('Platform Notifications'),
            onTap: () {
              Navigator.pop(context);
              _openNotificationsScreen();
            },
          ),
          ListTile(
            leading: const Icon(Icons.security_rounded, color: AppTheme.primary),
            title: const Text('Audit Trail & Logs'),
            onTap: () {
              Navigator.pop(context);
              _openLogsScreen();
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined, color: AppTheme.primary),
            title: const Text('System Backup & Export'),
            onTap: () {
              Navigator.pop(context);
              _openBackupScreen();
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune_rounded, color: AppTheme.primary),
            title: const Text('Platform Settings'),
            onTap: () {
              Navigator.pop(context);
              _openSettingsScreen();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.danger),
            title: const Text('Sign Out', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    final stats = _dashboard?.stats ?? {};
    final totalAssignments = stats['total_assignments']?.toString() ?? '0';
    final totalRevenue = stats['total_revenue'] != null
        ? '\$${double.tryParse(stats['total_revenue'].toString())?.toStringAsFixed(2) ?? '0.00'}'
        : '\$0.00';
    final activeOrders = stats['active_orders']?.toString() ?? '0';
    final totalStudents = stats['total_students']?.toString() ?? '0';
    final totalExperts = stats['total_experts']?.toString() ?? '0';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Executive Command Portal',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary),
                      ),
                      child: const Text('Admin Access', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Connected to AWS RDS MySQL. Real-time platform synchronization active.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildAdminActionBtn('Students ($totalStudents)', Icons.people_outline, _openStudentsScreen),
                    _buildAdminActionBtn('Experts ($totalExperts)', Icons.school_outlined, _openExpertsScreen),
                    _buildAdminActionBtn('Coupons', Icons.confirmation_number_outlined, _openCouponsScreen),
                    _buildAdminActionBtn('History & Trash', Icons.history_edu_rounded, _openHistoryScreen),
                    _buildAdminActionBtn('Analytics CSV', Icons.insert_chart_outlined_rounded, _openReportsScreen),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // KPI Cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Platform Revenue',
                  value: totalRevenue,
                  icon: Icons.payments_rounded,
                  color: AppTheme.success,
                  subtitle: 'Total processed payments',
                  onTap: _openPaymentsScreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Total Orders',
                  value: totalAssignments,
                  icon: Icons.folder_shared_rounded,
                  color: AppTheme.primary,
                  subtitle: 'Global assignments',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Active Orders',
                  value: activeOrders,
                  icon: Icons.pending_actions_rounded,
                  color: AppTheme.accent,
                  subtitle: 'In production / QA',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Total Students',
                  value: totalStudents,
                  icon: Icons.person_pin_circle_rounded,
                  color: AppTheme.warning,
                  subtitle: 'Registered accounts',
                  onTap: _openStudentsScreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Master Assignments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Global Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textMain),
              ),
              TextButton(
                onPressed: () => setState(() => _currentBottomNav = 1),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _buildAssignmentsList(),
        ],
      ),
    );
  }

  Widget _buildMasterAssignmentsView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Master Assignments',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateOrderDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Place Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search bar
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by ID, title, student, or subject...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () => setState(() => _searchCtrl.clear()))
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),

          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((s) {
                final isSel = _selectedStatus == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s),
                    selected: isSel,
                    selectedColor: AppTheme.primaryLight,
                    onSelected: (_) {
                      setState(() => _selectedStatus = s);
                      _fetchData();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Priority filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Priority:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                const SizedBox(width: 8),
                ..._priorityFilters.map((p) {
                  final isSel = _selectedPriority == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(p, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : AppTheme.textMain)),
                      selected: isSel,
                      selectedColor: AppTheme.primary,
                      onSelected: (_) => setState(() => _selectedPriority = p),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildAssignmentsList(),
        ],
      ),
    );
  }

  Widget _buildAssignmentsList() {
    final list = _currentBottomNav == 1 ? _filteredAssignments : _assignments;

    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Column(
          children: [
            Icon(Icons.folder_off_outlined, size: 48, color: AppTheme.textDim),
            SizedBox(height: 12),
            Text('No assignments found', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final a = list[i];
        return AssignmentCard(
          assignment: a,
          onTap: () {
            AssignmentDetailSheet.show(
              context,
              assignment: a,
              currentUser: widget.user,
              onStatusChanged: _fetchData,
            );
          },
        );
      },
    );
  }

  Widget _buildAdminActionBtn(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
