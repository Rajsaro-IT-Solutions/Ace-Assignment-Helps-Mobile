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
import 'student_submit_assignment_screen.dart';
import 'student_payments_screen.dart';
import 'student_messages_screen.dart';
import 'student_profile_screen.dart';
import 'student_whatsapp_screen.dart';
import 'student_history_screen.dart';
import 'student_notifications_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  final UserModel user;

  const StudentDashboardScreen({super.key, required this.user});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _currentBottomNav = 0;
  bool _loading = true;
  DashboardData? _dashboard;
  List<AssignmentModel> _assignments = [];
  int _unreadNotifCount = 0;
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusFilters = ['All', 'In Progress', 'Under Review', 'Completed'];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);

    final dashboardFuture = ApiService.getDashboard(
      role: 'Student',
      userId: widget.user.id,
    );

    final assignmentsFuture = ApiService.getAssignments(
      role: 'Student',
      userId: widget.user.id,
      status: _selectedStatus,
      search: _searchController.text.trim(),
    );

    final notifsFuture = ApiService.getStudentNotifications(studentId: widget.user.id);

    final results = await Future.wait([dashboardFuture, assignmentsFuture, notifsFuture]);

    if (mounted) {
      final notifs = results[2] as List<NotificationModel>;
      setState(() {
        _dashboard = results[0] as DashboardData?;
        _assignments = results[1] as List<AssignmentModel>;
        _unreadNotifCount = notifs.where((n) => !n.isRead).length;
        _loading = false;
      });
    }
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to log out of your student portal?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Log Out'),
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

  void _openSubmitScreen() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => StudentSubmitAssignmentScreen(user: widget.user)),
    );
    if (submitted == true) {
      _fetchData();
    }
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
                'Ace Portal',
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
                tooltip: 'Notifications Center',
                icon: const Icon(Icons.notifications_outlined, color: AppTheme.textMuted),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => StudentNotificationsScreen(user: widget.user)),
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
            tooltip: 'Live WhatsApp & Support Chat',
            icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF10B981)),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => StudentWhatsAppScreen(user: widget.user)),
            ),
          ),
          IconButton(
            tooltip: 'Support Tickets',
            icon: const Icon(Icons.support_agent_rounded, color: AppTheme.textMuted),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => StudentMessagesScreen(user: widget.user)),
            ),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline_rounded, color: AppTheme.textMuted),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => StudentProfileScreen(user: widget.user)),
            ),
          ),
        ],
      ),
      drawer: _buildPortalDrawer(),
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
            _openSubmitScreen();
          } else if (i == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => StudentPaymentsScreen(user: widget.user)),
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
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded),
            label: 'Submit Order',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            label: 'Assignments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Invoices',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSubmitScreen,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Order'),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildCurrentView() {
    if (_currentBottomNav == 2) {
      return _buildAssignmentsViewOnly();
    }
    return _buildDashboardOverview();
  }

  Widget _buildPortalDrawer() {
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
            child: Text('STUDENT PORTAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textDim)),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined, color: AppTheme.primary),
            title: const Text('Dashboard Overview'),
            selected: _currentBottomNav == 0,
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentBottomNav = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.post_add_rounded, color: AppTheme.primary),
            title: const Text('Submit Assignment'),
            onTap: () {
              Navigator.pop(context);
              _openSubmitScreen();
            },
          ),
          ListTile(
            leading: const Icon(Icons.book_outlined, color: AppTheme.primary),
            title: const Text('My Assignments'),
            selected: _currentBottomNav == 2,
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentBottomNav = 2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF10B981)),
            title: const Text('WhatsApp & Live Chat Hub'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => StudentWhatsAppScreen(user: widget.user)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_edu_rounded, color: AppTheme.secondary),
            title: const Text('Assignment History & Archives'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => StudentHistoryScreen(user: widget.user)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.credit_card_outlined, color: AppTheme.primary),
            title: const Text('Invoices & Payments'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => StudentPaymentsScreen(user: widget.user)),
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
                MaterialPageRoute(builder: (_) => StudentNotificationsScreen(user: widget.user)),
              ).then((_) => _fetchData());
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_rounded, color: AppTheme.primary),
            title: const Text('Support Tickets & Chat'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => StudentMessagesScreen(user: widget.user)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded, color: AppTheme.primary),
            title: const Text('Profile Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => StudentProfileScreen(user: widget.user)),
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

  Widget _buildDashboardOverview() {
    final stats = _dashboard?.stats ?? {};
    final total = stats['total_assignments']?.toString() ?? '0';
    final inProgress = stats['in_progress']?.toString() ?? '0';
    final underReview = stats['under_review']?.toString() ?? '0';
    final completed = stats['completed']?.toString() ?? '0';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  blurRadius: 16,
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
                      'Welcome back, ${widget.user.name.split(' ').first}!',
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
                  'Track assignments, review expert solutions, and submit new briefs.',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildBannerActionBtn('Submit Brief', Icons.add_circle_outline, _openSubmitScreen),
                    _buildBannerActionBtn('Invoices', Icons.receipt_long_outlined, () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudentPaymentsScreen(user: widget.user)));
                    }),
                    _buildBannerActionBtn('Archives', Icons.history_edu_rounded, () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudentHistoryScreen(user: widget.user)));
                    }),
                    _buildBannerActionBtn('Support Chat', Icons.chat_bubble_outline, () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudentMessagesScreen(user: widget.user)));
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // KPI Stats Grid
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Orders',
                  value: total,
                  icon: Icons.folder_open_rounded,
                  color: AppTheme.primary,
                  subtitle: 'All time submissions',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'In Progress',
                  value: inProgress,
                  icon: Icons.pending_actions_rounded,
                  color: AppTheme.accent,
                  subtitle: 'Being written by expert',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Quality Check',
                  value: underReview,
                  icon: Icons.fact_check_outlined,
                  color: AppTheme.warning,
                  subtitle: 'Under review & QA',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Completed',
                  value: completed,
                  icon: Icons.check_circle_outline_rounded,
                  color: AppTheme.success,
                  subtitle: 'Ready for download',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section Title & Search
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Orders',
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

  Widget _buildAssignmentsViewOnly() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Assignments & Orders',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain),
          ),
          const SizedBox(height: 12),

          // Search Box
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by topic, subject, or order ID...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _fetchData();
                      },
                    )
                  : null,
            ),
            onSubmitted: (_) => _fetchData(),
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
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.folder_off_outlined, size: 48, color: AppTheme.textDim),
            const SizedBox(height: 12),
            const Text(
              'No assignments found',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain),
            ),
            const SizedBox(height: 4),
            const Text(
              'Submit a new order to get PhD assistance with your coursework.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openSubmitScreen,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Submit Assignment'),
            ),
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

  Widget _buildBannerActionBtn(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
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
