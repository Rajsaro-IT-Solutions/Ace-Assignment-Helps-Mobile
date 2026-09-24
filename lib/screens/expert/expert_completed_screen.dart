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
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCompleted();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  int get _totalWordsAuthored => _completedList.fold(0, (sum, a) => sum + a.wordCount);

  List<AssignmentModel> get _filteredList {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _completedList.where((a) {
      if (q.isNotEmpty) {
        return a.assignmentId.toLowerCase().contains(q) ||
            a.title.toLowerCase().contains(q) ||
            a.subject.toLowerCase().contains(q);
      }
      return true;
    }).toList();
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
                    // Summary Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF065F46), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.verified_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_completedList.length} Verified Solutions',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Passed Turnitin 0% originality check & QA verification.',
                                      style: TextStyle(fontSize: 12, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildPill('$_totalWordsAuthored Words Authored', Colors.white.withValues(alpha: 0.2)),
                              _buildPill('Turnitin Verified', const Color(0xFF34D399).withValues(alpha: 0.25)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search Field
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search completed solutions...',
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
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Solution Archive (${_filteredList.length})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_filteredList.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(36),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textDim),
                            const SizedBox(height: 12),
                            Text(
                              _searchCtrl.text.isNotEmpty ? 'No solutions match "${_searchCtrl.text.trim()}"' : 'No completed solutions yet',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchCtrl.text.isNotEmpty
                                  ? 'Try adjusting your search keywords.'
                                  : 'When your submitted solution packages pass QA verification, they will be archived here.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final a = _filteredList[i];
                          return AssignmentCard(
                            assignment: a,
                            onTap: () {
                              AssignmentDetailSheet.show(
                                context,
                                assignment: a,
                                currentUser: widget.user,
                                onStatusChanged: _loadCompleted,
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

  Widget _buildPill(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
