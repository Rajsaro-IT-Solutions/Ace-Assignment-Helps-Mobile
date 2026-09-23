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
import 'allocator_pending_screen.dart';
import 'allocator_experts_screen.dart';

class AllocatorDashboardScreen extends StatefulWidget {
  final UserModel user;

  const AllocatorDashboardScreen({super.key, required this.user});

  @override
  State<AllocatorDashboardScreen> createState() => _AllocatorDashboardScreenState();
}

class _AllocatorDashboardScreenState extends State<AllocatorDashboardScreen> {
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
      role: 'Allocator',
      userId: widget.user.id,
    );

    final assignmentsFuture = ApiService.getAssignments(
      role: 'Allocator',
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
        content: const Text('Are you sure you want to sign out of the allocator portal?'),
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

  void _openPendingQueue() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AllocatorPendingScreen(user: widget.user)),
    );
    _fetchData();
  }

  void _openExpertRoster() {
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
            const Text('Allocator Center'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pending Queue',
            icon: const Icon(Icons.hourglass_top_rounded, color: AppTheme.warning),
            onPressed: _openPendingQueue,
          ),
          IconButton(
            tooltip: 'Server Settings',
            icon: const Icon(Icons.dns_outlined, color: AppTheme.textMuted),
            onPressed: () => ServerConfigDialog.show(context),
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
          if (i == 1) {
            _openPendingQueue();
          } else if (i == 3) {
            _openExpertRoster();
          } else {
            setState(() => _currentBottomNav = i);
          }
        },
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textDim,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.speed_rounded),
            label: 'Command',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hourglass_top_rounded),
            label: 'Pending Queue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in_outlined),
            label: 'Active Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            label: 'Experts',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    if (_currentBottomNav == 2) {
      return _buildActiveTasksView();
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
              backgroundColor: AppTheme.warning,
              child: Text(widget.user.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('ALLOCATION CONTROL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textDim)),
          ),
          ListTile(
            leading: const Icon(Icons.speed_rounded, color: AppTheme.primary),
            title: const Text('Command Center'),
            selected: _currentBottomNav == 0,
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentBottomNav = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.hourglass_top_rounded, color: AppTheme.warning),
            title: const Text('Pending Queue'),
            onTap: () {
              Navigator.pop(context);
              _openPendingQueue();
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment_turned_in_outlined, color: AppTheme.primary),
            title: const Text('Allocated & Active'),
            selected: _currentBottomNav == 2,
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentBottomNav = 2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.school_outlined, color: AppTheme.primary),
            title: const Text('Expert Roster'),
            onTap: () {
              Navigator.pop(context);
              _openExpertRoster();
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
    final unallocated = stats['unallocated']?.toString() ?? '0';
    final inProgress = stats['in_progress']?.toString() ?? '0';
    final underQa = stats['under_qa']?.toString() ?? '0';
    final activeExperts = stats['active_experts']?.toString() ?? '0';

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
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
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
                    Text(
                      'Welcome, ${widget.user.name.split(' ').first}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.warning),
                      ),
                      child: const Text('Allocator Portal', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Manage PhD allocation workload, monitor expert milestones, and review QA.',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _openPendingQueue,
                      icon: const Icon(Icons.bolt_rounded, size: 16),
                      label: Text('Pending Queue ($unallocated)'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _openExpertRoster,
                      icon: const Icon(Icons.people_outline, size: 16, color: Colors.white),
                      label: const Text('Roster', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38)),
                    ),
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
                  title: 'Unallocated',
                  value: unallocated,
                  icon: Icons.hourglass_top_rounded,
                  color: AppTheme.warning,
                  subtitle: 'Pending assignment',
                  onTap: _openPendingQueue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'In Progress',
                  value: inProgress,
                  icon: Icons.autorenew_rounded,
                  color: AppTheme.primary,
                  subtitle: 'Being written by experts',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Ready for QA',
                  value: underQa,
                  icon: Icons.fact_check_outlined,
                  color: AppTheme.accent,
                  subtitle: 'Solutions submitted',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Expert Roster',
                  value: activeExperts,
                  icon: Icons.groups_outlined,
                  color: AppTheme.success,
                  subtitle: 'Active PhD specialists',
                  onTap: _openExpertRoster,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Assignments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Allocation Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textMain),
              ),
              TextButton(
                onPressed: () => setState(() => _currentBottomNav = 2),
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

  Widget _buildActiveTasksView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Allocated & Active Master Tasks',
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
            Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textDim),
            SizedBox(height: 12),
            Text('No assignments matching filter', style: TextStyle(fontWeight: FontWeight.bold)),
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
}
