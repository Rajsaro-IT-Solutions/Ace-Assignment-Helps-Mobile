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
import 'expert_completed_screen.dart';
import 'expert_messages_screen.dart';
import 'expert_profile_screen.dart';
import 'expert_solution_upload_dialog.dart';

class ExpertDashboardScreen extends StatefulWidget {
  final UserModel user;

  const ExpertDashboardScreen({super.key, required this.user});

  @override
  State<ExpertDashboardScreen> createState() => _ExpertDashboardScreenState();
}

class _ExpertDashboardScreenState extends State<ExpertDashboardScreen> {
  int _currentBottomNav = 0;
  bool _loading = true;
  DashboardData? _dashboard;
  List<AssignmentModel> _assignments = [];
  String _selectedStatus = 'All';

  final List<String> _statusFilters = ['All', 'In Progress', 'Under QA', 'Completed'];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);

    final dashboardFuture = ApiService.getDashboard(
      role: 'Expert',
      userId: widget.user.id,
    );

    final assignmentsFuture = ApiService.getAssignments(
      role: 'Expert',
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
        content: const Text('Are you sure you want to sign out of the expert workspace?'),
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

  void _showTaskActionSheet(AssignmentModel a) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task Actions: ${a.assignmentId}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(a.title, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded, color: AppTheme.primary),
              title: const Text('Start Working on Task'),
              subtitle: const Text('Mark status as "In Progress"'),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await ApiService.expertAction(
                  assignmentId: a.assignmentId,
                  actionType: 'start',
                  expertId: widget.user.id,
                );
                if (ok) _fetchData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_rounded, color: AppTheme.success),
              title: const Text('Submit Solution Package (QA)'),
              subtitle: const Text('Upload deliverable file, notes & Turnitin report'),
              onTap: () {
                Navigator.pop(ctx);
                ExpertSolutionUploadDialog.show(
                  context,
                  assignment: a,
                  currentUser: widget.user,
                  onUploaded: _fetchData,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppTheme.textMuted),
              title: const Text('View Full Assignment Brief'),
              onTap: () {
                Navigator.pop(ctx);
                AssignmentDetailSheet.show(
                  context,
                  assignment: a,
                  currentUser: widget.user,
                );
              },
            ),
          ],
        ),
      ),
    );
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
              child: Text(
                'Expert Workspace',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Communications & Chat',
            icon: const Icon(Icons.forum_outlined, color: AppTheme.primary),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ExpertMessagesScreen(user: widget.user)),
            ),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline_rounded, color: AppTheme.textMuted),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ExpertProfileScreen(user: widget.user)),
            ),
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
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ExpertCompletedScreen(user: widget.user)),
            );
          } else if (i == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ExpertProfileScreen(user: widget.user)),
            );
          } else {
            setState(() => _currentBottomNav = i);
          }
        },
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textDim,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Assigned Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline_rounded),
            label: 'Completed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    if (_currentBottomNav == 1) {
      return _buildAssignedTasksView();
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
              backgroundColor: AppTheme.success,
              child: Text(widget.user.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('EXPERT WORKSPACE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textDim)),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_rounded, color: AppTheme.primary),
            title: const Text('Dashboard Overview'),
            selected: _currentBottomNav == 0,
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentBottomNav = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment_outlined, color: AppTheme.primary),
            title: const Text('My Assigned Tasks'),
            selected: _currentBottomNav == 1,
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentBottomNav = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.success),
            title: const Text('Completed Solutions'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ExpertCompletedScreen(user: widget.user)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.forum_outlined, color: AppTheme.primary),
            title: const Text('Communications & Support'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ExpertMessagesScreen(user: widget.user)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded, color: AppTheme.primary),
            title: const Text('Profile & Remittance Payouts'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ExpertProfileScreen(user: widget.user)),
              );
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
    final totalAllocated = stats['total_allocated']?.toString() ?? '0';
    final inProgress = stats['in_progress']?.toString() ?? '0';
    final underQa = stats['under_qa']?.toString() ?? '0';
    final completed = stats['completed']?.toString() ?? '0';

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
                colors: [Color(0xFF065F46), Color(0xFF047857)],
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
                      'Welcome, ${widget.user.name.split(' ').first}!',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.user.id,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Review assigned briefs, deliver milestone drafts, and meet strict SLA deadlines.',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
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
                  title: 'Assigned',
                  value: totalAllocated,
                  icon: Icons.assignment_outlined,
                  color: AppTheme.primary,
                  subtitle: 'Total tasks assigned',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Writing',
                  value: inProgress,
                  icon: Icons.edit_note_rounded,
                  color: AppTheme.accent,
                  subtitle: 'Drafts in progress',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Under QA',
                  value: underQa,
                  icon: Icons.fact_check_outlined,
                  color: AppTheme.warning,
                  subtitle: 'Awaiting allocator check',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Delivered',
                  value: completed,
                  icon: Icons.check_circle_outline_rounded,
                  color: AppTheme.success,
                  subtitle: 'Completed solutions',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ExpertCompletedScreen(user: widget.user)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Active Assignments Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Active Tasks',
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

  Widget _buildAssignedTasksView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Assigned Coursework Tasks',
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
            Icon(Icons.assignment_turned_in_outlined, size: 48, color: AppTheme.textDim),
            SizedBox(height: 12),
            Text('No tasks in this view', style: TextStyle(fontWeight: FontWeight.bold)),
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
        return InkWell(
          onLongPress: () => _showTaskActionSheet(a),
          child: AssignmentCard(
            assignment: a,
            onTap: () => _showTaskActionSheet(a),
          ),
        );
      },
    );
  }
}
