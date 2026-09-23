import 'package:flutter/material.dart';
import '../../core/models/assignment_model.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/assignment_card.dart';
import '../common/assignment_detail_sheet.dart';

class ExpertCompletedScreen extends StatefulWidget {
  final UserModel user;

  const ExpertCompletedScreen({super.key, required this.user});

  @override
  State<ExpertCompletedScreen> createState() => _ExpertCompletedScreenState();
}

class _ExpertCompletedScreenState extends State<ExpertCompletedScreen> {
  bool _loading = true;
  List<AssignmentModel> _completedList = [];

  @override
  void initState() {
    super.initState();
    _loadCompleted();
  }

  Future<void> _loadCompleted() async {
    setState(() => _loading = true);
    final all = await ApiService.getAssignments(
      role: 'Expert',
      userId: widget.user.id,
      status: 'Completed',
    );
    if (mounted) {
      setState(() {
        _completedList = all;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Completed Solutions'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadCompleted),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCompleted,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF065F46), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, color: Colors.white, size: 36),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_completedList.length} Solutions Delivered',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Archived solutions that successfully passed QA verification.',
                                  style: TextStyle(fontSize: 12, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_completedList.isEmpty)
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
                            Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textDim),
                            SizedBox(height: 12),
                            Text('No completed solutions yet', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('When your submitted work passes allocator QA, it will appear here.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _completedList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final a = _completedList[i];
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
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
