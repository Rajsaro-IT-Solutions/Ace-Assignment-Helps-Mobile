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
import 'expert_notifications_screen.dart';

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
  int _unreadNotifCount = 0;
  String _availabilityStatus = 'Available';
  final _searchCtrl = TextEditingController();

  final List<String> _statusFilters = ['All', 'In Progress', 'Under QA', 'Completed'];

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
      role: 'Expert',
      userId: widget.user.id,
    );

    final assignmentsFuture = ApiService.getAssignments(
      role: 'Expert',
      userId: widget.user.id,
      status: _selectedStatus,
    );

    final notifsFuture = ApiService.getExpertNotifications(expertId: widget.user.id);
    final profileFuture = ApiService.getExpertProfileDetails(expertId: widget.user.id);

    final results = await Future.wait([dashboardFuture, assignmentsFuture, notifsFuture, profileFuture]);

    if (mounted) {
      final notifs = results[2] as List<NotificationModel>;
      final profile = results[3] as Map<String, dynamic>?;

      setState(() {
        _dashboard = results[0] as DashboardData?;
        _assignments = results[1] as List<AssignmentModel>;
        _unreadNotifCount = notifs.where((n) => !n.isRead).length;
        if (profile != null && profile['status'] != null) {
          _availabilityStatus = profile['status'].toString();
        }
        _loading = false;
      });
    }
  }

  Future<void> _toggleAvailability() async {
    final nextStatus = _availabilityStatus.toLowerCase() == 'available' ? 'Busy' : 'Available';
    setState(() => _availabilityStatus = nextStatus);

    final ok = await ApiService.toggleExpertAvailability(
      expertId: widget.user.id,
      status: nextStatus,
    );

    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Roster availability updated: $nextStatus'),
            backgroundColor: nextStatus == 'Available' ? AppTheme.success : AppTheme.warning,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update availability status.'), backgroundColor: AppTheme.danger),
        );
      }
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Task Actions: ${a.assignmentId}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(a.status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(a.title, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            const SizedBox(height: 16),
            if (a.status.toLowerCase() == 'pending' || a.status.toLowerCase() == 'allocated')
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
              leading: const Icon(Icons.assignment_rounded, color: AppTheme.secondary),
              title: const Text('View Full Assignment Brief'),
              subtitle: const Text('Access student files, requirements, and reference notes'),
              onTap: () {
                Navigator.pop(ctx);
                AssignmentDetailSheet.show(
                  context,
                  assignment: a,
                  currentUser: widget.user,
                  onStatusChanged: _fetchData,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<AssignmentModel> get _filteredAssignedTasks {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _assignments.where((a) {
      if (q.isNotEmpty) {
        final matchesQuery = a.assignmentId.toLowerCase().contains(q) ||
            a.title.toLowerCase().contains(q) ||
            a.subject.toLowerCase().contains(q);
        if (!matchesQuery) return false;
      }
      return true;
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
              child: Text(
                'Expert Workspace',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Alerts & Notifications',
                icon: const Icon(Icons.notifications_outlined, color: AppTheme.textMuted),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ExpertNotificationsScreen(user: widget.user)),
                  );
                  _fetchData();
                },
              ),
              if (_unreadNotifCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.danger,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_unreadNotifCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
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
            leading: const Icon(Icons.notifications_outlined, color: AppTheme.primary),
            title: const Text('Notifications Center'),
            trailing: _unreadNotifCount > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.danger,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_unreadNotifCount',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                : null,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ExpertNotificationsScreen(user: widget.user)),
              ).then((_) => _fetchData());
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
    final isAvailable = _availabilityStatus.toLowerCase() == 'available';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner with Availability Status Toggle (Mirroring /expert/index.php)
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
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF047857).withValues(alpha: 0.2),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
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
                const SizedBox(height: 16),

                // Availability Status Pill & Toggle Action Button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isAvailable ? AppTheme.success.withValues(alpha: 0.25) : AppTheme.warning.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isAvailable ? const Color(0xFF34D399) : const Color(0xFFFBBF24)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAvailable ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                            size: 14,
                            color: isAvailable ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAvailable ? 'Available for Tasks' : 'Status: Busy',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isAvailable ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: _toggleAvailability,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isAvailable ? 'Switch to Busy' : 'Switch to Available',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4 KPI Cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Assigned',
                  value: totalAllocated,
                  icon: Icons.assignment_outlined,
                  color: AppTheme.primary,
                  subtitle: 'Total tasks assigned',
                  onTap: () => setState(() => _currentBottomNav = 1),
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
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'In Progress';
                      _currentBottomNav = 1;
                    });
                    _fetchData();
                  },
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
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'Under QA';
                      _currentBottomNav = 1;
                    });
                    _fetchData();
                  },
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

          // Active Assignments Header
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

          // Search Box
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search tasks by order ID, title, subject...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                    )
                  : null,
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((s) {
                final isSel = _selectedStatus == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s),
                    selected: isSel,
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
    final list = _filteredAssignedTasks;
    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.assignment_turned_in_outlined, size: 48, color: AppTheme.textDim),
            const SizedBox(height: 12),
            Text(
              _searchCtrl.text.isNotEmpty ? 'No tasks match "${_searchCtrl.text.trim()}"' : 'No tasks in this view',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _searchCtrl.text.isNotEmpty
                  ? 'Try clearing the search query or changing filters.'
                  : 'New assignment allocations will appear here.',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
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
