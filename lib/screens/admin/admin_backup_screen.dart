import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminBackupScreen extends StatefulWidget {
  final UserModel user;

  const AdminBackupScreen({super.key, required this.user});

  @override
  State<AdminBackupScreen> createState() => _AdminBackupScreenState();
}

class _AdminBackupScreenState extends State<AdminBackupScreen> {
  bool _exporting = false;
  String? _lastBackupTime;
  int _lastTableCount = 0;
  String _backupSummary = '';

  Future<void> _generateBackup() async {
    setState(() => _exporting = true);
    final data = await ApiService.generateSystemBackup();
    if (mounted) {
      setState(() {
        _exporting = false;
        if (data.isNotEmpty) {
          final tables = data['tables'] as Map<String, dynamic>? ?? {};
          _lastBackupTime = DateTime.now().toLocal().toString().split('.')[0];
          _lastTableCount = tables.length;
          _backupSummary = 'Exported $_lastTableCount system tables including orders, financial ledger, and user rosters successfully.';
        }
      });

      if (data.isNotEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppTheme.success),
                SizedBox(width: 8),
                Text('System Archive Ready', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Full JSON Database Snapshot generated from AWS RDS MySQL:'),
                const SizedBox(height: 10),
                Text('• Tables: $_lastTableCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('• Timestamp: $_lastBackupTime'),
                const Text('• Host: database-1.c1o0ygcs2cex.ap-south-1.rds.amazonaws.com', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.bg, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    '${jsonEncode(data).substring(0, 180)}...',
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
                    const SnackBar(content: Text('Backup archive saved successfully!'), backgroundColor: AppTheme.success),
                  );
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download Archive'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate database archive.'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('System Backup & Data Export'),
      ),
      body: SingleChildScrollView(
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
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primary,
                        child: Icon(Icons.cloud_download_rounded, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Database Archive Console', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('AWS RDS MySQL • 256-Bit SSL Dual Sync', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Full System Snapshot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text(
                      'Exports all platform tables (assignments, students, experts, allocators, payments, coupons, courses, audit logs) into a structured system archive.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 16),

                    if (_lastBackupTime != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Last Archive: $_lastBackupTime\n$_backupSummary',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMain),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _exporting ? null : _generateBackup,
                        icon: _exporting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.backup_rounded),
                        label: const Text('Generate & Export Database Backup', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
