import 'package:flutter/material.dart';
import '../../core/models/portal_models.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class AllocatorExpertsScreen extends StatefulWidget {
  final UserModel user;

  const AllocatorExpertsScreen({super.key, required this.user});

  @override
  State<AllocatorExpertsScreen> createState() => _AllocatorExpertsScreenState();
}

class _AllocatorExpertsScreenState extends State<AllocatorExpertsScreen> {
  bool _loading = true;
  List<ExpertModel> _experts = [];

  @override
  void initState() {
    super.initState();
    _loadExperts();
  }

  Future<void> _loadExperts() async {
    setState(() => _loading = true);
    final list = await ApiService.getExperts();
    if (mounted) {
      setState(() {
        _experts = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Expert Roster'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadExperts),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadExperts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Academic Experts Directory (${_experts.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _experts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final e = _experts[i];
                        final isBusy = e.activeTasks > 2;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppTheme.primaryLight,
                                    child: Text(
                                      e.name.isNotEmpty ? e.name[0] : 'E',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(e.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                        Text(e.email, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isBusy ? AppTheme.warningBg : AppTheme.successBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isBusy ? 'Busy (${e.activeTasks} tasks)' : 'Available',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isBusy ? AppTheme.warning : AppTheme.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: AppTheme.warning, size: 18),
                                      const SizedBox(width: 4),
                                      Text('${e.rating} Rating', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Text(
                                    '${e.completedCount} Solutions Delivered',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                  Text(
                                    'ID: ${e.expertId}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDim),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
