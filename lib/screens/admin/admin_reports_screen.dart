import 'package:flutter/material.dart';
import '../../core/models/assignment_model.dart';
import '../../core/models/portal_models.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminReportsScreen extends StatefulWidget {
  final UserModel user;

  const AdminReportsScreen({super.key, required this.user});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _loading = true;
  List<AssignmentModel> _assignments = [];
  List<PaymentModel> _payments = [];
  List<StudentDirectoryModel> _students = [];
  List<ExpertModel> _experts = [];
  String _selectedPeriod = 'All Time';

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    setState(() => _loading = true);
    final aFuture = ApiService.getAssignments(role: 'Admin', userId: widget.user.id);
    final pFuture = ApiService.getPayments();
    final sFuture = ApiService.getStudents();
    final eFuture = ApiService.getExperts();

    final results = await Future.wait([aFuture, pFuture, sFuture, eFuture]);

    if (mounted) {
      setState(() {
        _assignments = results[0] as List<AssignmentModel>;
        _payments = results[1] as List<PaymentModel>;
        _students = results[2] as List<StudentDirectoryModel>;
        _experts = results[3] as List<ExpertModel>;
        _loading = false;
      });
    }
  }

  double get _totalRevenue =>
      _payments.where((p) => p.status.toLowerCase() == 'paid' || p.status.toLowerCase() == 'completed').fold(0.0, (s, p) => s + p.amount);

  void _exportCsv(String type) {
    String csvData = '';
    if (type == 'Assignments') {
      csvData = 'Assignment ID,Student ID,Title,Subject,Type,Price,Status,Deadline\n';
      for (var a in _assignments) {
        csvData += '"${a.assignmentId}","${a.studentId}","${a.title.replaceAll('"', '""')}","${a.subject}","${a.assignmentType}","${a.price}","${a.status}","${a.deadline}"\n';
      }
    } else if (type == 'Payments') {
      csvData = 'Payment ID,Assignment ID,Student ID,Amount,Currency,Status,Method,Date\n';
      for (var p in _payments) {
        csvData += '"${p.paymentId}","${p.assignmentId}","${p.studentId}","${p.amount}","${p.currency}","${p.status}","${p.paymentMethod}","${p.paymentDate}"\n';
      }
    } else if (type == 'Students') {
      csvData = 'Student ID,Name,Email,Phone,University,Country,Status\n';
      for (var s in _students) {
        csvData += '"${s.studentId}","${s.name}","${s.email}","${s.phone}","${s.university}","${s.country}","${s.status}"\n';
      }
    } else if (type == 'Experts') {
      csvData = 'Expert ID,Name,Email,Phone,Subjects,Status,Active Load\n';
      for (var e in _experts) {
        csvData += '"${e.expertId}","${e.name}","${e.email}","${e.phone}","${e.subjects}","${e.status}","${e.activeTasks}"\n';
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.download_done_rounded, color: AppTheme.success),
            const SizedBox(width: 8),
            Text('Export $type CSV', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generated ${type.toLowerCase()} dataset with ${csvData.split('\n').length - 1} records ready for download/export.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.bg, borderRadius: BorderRadius.circular(8)),
              child: Text(
                '${csvData.split('\n').take(4).join('\n')}\n...',
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$type CSV data ready and exported!'), backgroundColor: AppTheme.success),
              );
            },
            icon: const Icon(Icons.file_download_rounded),
            label: const Text('Download CSV'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, int> countryCounts = {
      'United Kingdom': _assignments.where((a) => a.country.toLowerCase().contains('uk') || a.country.toLowerCase().contains('king')).length,
      'United States': _assignments.where((a) => a.country.toLowerCase().contains('us') || a.country.toLowerCase().contains('stat')).length,
      'Australia': _assignments.where((a) => a.country.toLowerCase().contains('australia')).length,
      'Ireland': _assignments.where((a) => a.country.toLowerCase().contains('ireland')).length,
      'Canada': _assignments.where((a) => a.country.toLowerCase().contains('canada')).length,
      'India': _assignments.where((a) => a.country.toLowerCase().contains('india')).length,
    };

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Analytics & CSV Reports'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchReportData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchReportData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period selector
                    Row(
                      children: [
                        const Text('Reporting Window:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Wrap(
                          spacing: 6,
                          children: ['Last 7 Days', 'Last 30 Days', 'All Time'].map((p) {
                            final isSel = _selectedPeriod == p;
                            return ChoiceChip(
                              label: Text(p, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : AppTheme.textMain)),
                              selected: isSel,
                              selectedColor: AppTheme.primary,
                              onSelected: (_) => setState(() => _selectedPeriod = p),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Top KPIs
                    Row(
                      children: [
                        Expanded(
                          child: _buildReportCard('Gross Revenue', '\$${_totalRevenue.toStringAsFixed(2)}', Icons.payments_rounded, AppTheme.success),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildReportCard('Total Orders', '${_assignments.length}', Icons.assignment_rounded, AppTheme.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildReportCard('Active Students', '${_students.length}', Icons.people_outline, AppTheme.warning),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildReportCard('Active Experts', '${_experts.length}', Icons.school_outlined, AppTheme.accent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // CSV Data Exporter Section
                    const Text('Export System CSVs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildExportBtn('Assignments CSV', Icons.file_present_rounded, () => _exportCsv('Assignments')),
                        _buildExportBtn('Payments CSV', Icons.receipt_long_rounded, () => _exportCsv('Payments')),
                        _buildExportBtn('Students CSV', Icons.people_rounded, () => _exportCsv('Students')),
                        _buildExportBtn('Experts CSV', Icons.badge_outlined, () => _exportCsv('Experts')),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Country Demographics
                    const Text('International Order Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                    const SizedBox(height: 12),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: countryCounts.entries.map((e) {
                            final total = _assignments.isNotEmpty ? _assignments.length : 1;
                            final percent = (e.value / total).clamp(0.0, 1.0);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                      Text('${e.value} orders', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value: percent > 0 ? percent : 0.05,
                                    backgroundColor: AppTheme.bg,
                                    color: AppTheme.primary,
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReportCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildExportBtn(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
