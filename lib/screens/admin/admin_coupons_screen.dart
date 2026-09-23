import 'package:flutter/material.dart';
import '../../core/models/portal_models.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminCouponsScreen extends StatefulWidget {
  final UserModel user;

  const AdminCouponsScreen({super.key, required this.user});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  bool _loading = true;
  List<CouponModel> _coupons = [];

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() => _loading = true);
    final list = await ApiService.getCoupons();
    if (mounted) {
      setState(() {
        _coupons = list;
        _loading = false;
      });
    }
  }

  void _showCreateCouponDialog() {
    final codeCtrl = TextEditingController();
    final discountCtrl = TextEditingController(text: '15');
    final usesCtrl = TextEditingController(text: '100');
    bool creating = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.confirmation_number_outlined, color: AppTheme.primary),
                SizedBox(width: 8),
                Text('Create Discount Coupon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Coupon Promo Code *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(hintText: 'e.g. FALL25 or ACE20'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Discount Percentage (%) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: discountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '15'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Maximum Usage Limit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: usesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '100'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: creating
                    ? null
                    : () async {
                        final code = codeCtrl.text.trim();
                        final discount = int.tryParse(discountCtrl.text) ?? 10;
                        final uses = int.tryParse(usesCtrl.text) ?? 100;
                        if (code.isEmpty) return;

                        setDlgState(() => creating = true);
                        final navigator = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await ApiService.createCoupon(
                          code: code,
                          discountPercent: discount,
                          maxUses: uses,
                          expiresAt: DateTime.now().add(const Duration(days: 30)).toIso8601String(),
                        );
                        if (!mounted) return;
                        navigator.pop();
                        if (ok) {
                          _loadCoupons();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Coupon created successfully!'), backgroundColor: AppTheme.success),
                          );
                        }
                      },
                child: creating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create Coupon'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Coupons & Discounts'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadCoupons),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCouponDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Coupon'),
        backgroundColor: AppTheme.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCoupons,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Discount Coupons (${_coupons.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _coupons.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final c = _coupons[i];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.percent_rounded, color: AppTheme.primary, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          c.code,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.successBg,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text('${c.discountPercent}% OFF', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Uses: ${c.currentUses} / ${c.maxUses} • ID: ${c.couponId}',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
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
