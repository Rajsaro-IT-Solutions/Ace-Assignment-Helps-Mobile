import 'package:flutter/material.dart';
import '../../core/models/assignment_model.dart';
import '../../core/models/dashboard_stats_model.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/assignment_card.dart';
import '../../widgets/server_config_dialog.dart';
import '../../widgets/stat_card.dart';
import '../common/assignment_detail_sheet.dart';
import '../login_screen.dart';
import 'admin_students_screen.dart';
import 'admin_payments_screen.dart';
import 'admin_coupons_screen.dart';
import '../allocator/allocator_experts_screen.dart';

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

  final List<String> _statusFilters = ['All', 'Pending', 'In Progress', 'Under QA', 'Completed'];

  @override
  void initState() {
    super.initState();
    _fetchData();
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
      MaterialPageRoute(builder: (_) => AllocatorExpertsScreen(user: widget.user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 26, width: 26),
            const SizedBox(width: 8),
            const Text('Executive Admin'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Server Settings',
            icon: const Icon(Icons.dns_outlined, color: AppTheme.textMuted),
            onPressed: () => ServerConfigDialog.show(context),
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: AppTheme.textMuted),
            title: const Text('Server Settings'),
            onTap: () {
              Navigator.pop(context);
              ServerConfigDialog.show(context);
            },
          ),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Master Assignment Manager',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          _buildAssignmentsList(),
        ],
      ),
    );
  }

  Widget _buildAssignmentsList() {
    if (_assignments.isEmpty) {
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
      itemCount: _assignments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final a = _assignments[i];
        return AssignmentCard(
          assignment: a,
          onTap: () {
            AssignmentDetailSheet.show(
              context,
              assignment: a,
              currentUser: widget.user,
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
