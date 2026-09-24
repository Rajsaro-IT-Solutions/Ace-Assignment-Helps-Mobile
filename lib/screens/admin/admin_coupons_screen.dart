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

  void _showCouponDialog({CouponModel? coupon}) {
    final isEdit = coupon != null;
    final codeCtrl = TextEditingController(text: coupon?.code ?? '');
    final discountCtrl = TextEditingController(text: coupon?.discountPercent.toString() ?? '15');
    final usesCtrl = TextEditingController(text: coupon?.maxUses.toString() ?? '100');
    String selectedStatus = coupon?.status ?? 'Active';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.confirmation_number_outlined, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  isEdit ? 'Edit Coupon' : 'Create Discount Coupon',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
                  if (isEdit) ...[
                    const SizedBox(height: 12),
                    const Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      items: const [
                        DropdownMenuItem(value: 'Active', child: Text('Active')),
                        DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDlgState(() => selectedStatus = val);
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        final code = codeCtrl.text.trim();
                        final discount = int.tryParse(discountCtrl.text) ?? 10;
                        final uses = int.tryParse(usesCtrl.text) ?? 100;
                        if (code.isEmpty) return;

                        setDlgState(() => saving = true);
                        final navigator = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);

                        bool ok = false;
                        if (isEdit) {
                          ok = await ApiService.updateCoupon(
                            couponId: coupon.couponId,
                            code: code,
                            discountPercent: discount,
                            maxUses: uses,
                            status: selectedStatus,
                          );
                        } else {
                          ok = await ApiService.createCoupon(
                            code: code,
                            discountPercent: discount,
                            maxUses: uses,
                            expiresAt: DateTime.now().add(const Duration(days: 30)).toIso8601String(),
                          );
                        }

                        if (!mounted) return;
                        navigator.pop();
                        if (ok) {
                          _loadCoupons();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(isEdit ? 'Coupon updated!' : 'Coupon created successfully!'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Failed to save coupon'), backgroundColor: AppTheme.danger),
                          );
                        }
                      },
                child: saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isEdit ? 'Save Changes' : 'Create Coupon'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteCoupon(CouponModel coupon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Coupon'),
        content: Text('Are you sure you want to delete promo code "${coupon.code}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await ApiService.deleteCoupon(coupon.couponId);
    if (mounted) {
      if (ok) {
        _loadCoupons();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coupon ${coupon.code} deleted'), backgroundColor: AppTheme.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete coupon'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  void _toggleCoupon(CouponModel coupon) async {
    final newStatus = coupon.status.toLowerCase() == 'active' ? 'Inactive' : 'Active';
    final ok = await ApiService.toggleCouponStatus(coupon.couponId, newStatus);
    if (mounted && ok) {
      _loadCoupons();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coupon ${coupon.code} is now $newStatus'), backgroundColor: AppTheme.success),
      );
    }
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
        onPressed: () => _showCouponDialog(),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Coupon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCoupons,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Discount Coupons (${_coupons.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                    const SizedBox(height: 12),
                    if (_coupons.isEmpty)
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
                            Icon(Icons.confirmation_number_outlined, size: 48, color: AppTheme.textDim),
                            SizedBox(height: 12),
                            Text('No coupons found', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _coupons.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final c = _coupons[i];
                          final isActive = c.status.toLowerCase() == 'active';

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Column(
                              children: [
                                Row(
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
                                                child: Text(
                                                  '${c.discountPercent}% OFF',
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success),
                                                ),
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
                                    InkWell(
                                      onTap: () => _toggleCoupon(c),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isActive ? AppTheme.successBg : AppTheme.dangerBg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          c.status,
                                          style: TextStyle(
                                            color: isActive ? AppTheme.success : AppTheme.danger,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 18),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _showCouponDialog(coupon: c),
                                      icon: const Icon(Icons.edit_outlined, size: 16),
                                      label: const Text('Edit'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () => _confirmDeleteCoupon(c),
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.danger),
                                      label: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
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
