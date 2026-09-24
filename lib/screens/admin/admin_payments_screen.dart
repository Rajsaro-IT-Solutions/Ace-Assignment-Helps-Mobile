import 'package:flutter/material.dart';
import '../../core/models/portal_models.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../student/invoice_view_dialog.dart';
import '../../core/models/assignment_model.dart';

class AdminPaymentsScreen extends StatefulWidget {
  final UserModel user;

  const AdminPaymentsScreen({super.key, required this.user});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  bool _loading = true;
  List<PaymentModel> _payments = [];
  String _selectedStatusFilter = 'All';

  final List<String> _currencies = ['USD', 'GBP', 'AUD', 'EUR', 'CAD', 'INR'];
  final List<String> _methods = [
    'Stripe / Card',
    'PayPal',
    'Bank Wire / NEFT',
    'Western Union',
    'Manual Cash / Direct Transfer',
  ];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _loading = true);
    final list = await ApiService.getPayments();
    if (mounted) {
      setState(() {
        _payments = list;
        _loading = false;
      });
    }
  }

  double get _totalRevenue {
    return _payments
        .where((p) => p.status.toLowerCase() == 'paid' || p.status.toLowerCase() == 'completed')
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  double get _avgOrder {
    final paid = _payments.where((p) => p.status.toLowerCase() == 'paid' || p.status.toLowerCase() == 'completed');
    if (paid.isEmpty) return 0.0;
    return _totalRevenue / paid.length;
  }

  int get _refundedCount {
    return _payments.where((p) => p.status.toLowerCase().contains('refund')).length;
  }

  List<PaymentModel> get _filteredPayments {
    if (_selectedStatusFilter == 'All') return _payments;
    return _payments.where((p) {
      if (_selectedStatusFilter == 'Completed') {
        return p.status.toLowerCase() == 'completed' || p.status.toLowerCase() == 'paid';
      } else if (_selectedStatusFilter == 'Pending') {
        return p.status.toLowerCase() == 'pending';
      } else if (_selectedStatusFilter == 'Refunded') {
        return p.status.toLowerCase().contains('refund');
      }
      return true;
    }).toList();
  }

  void _showLogPaymentDialog() {
    final asmCtrl = TextEditingController();
    final studentCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final txnCtrl = TextEditingController();
    String selectedCurrency = 'USD';
    String selectedMethod = _methods.first;
    String selectedPlan = 'Full Payment';
    String selectedStatus = 'Completed';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.add_card_rounded, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Log Offline / Manual Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: asmCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Assignment ID *',
                    hintText: 'e.g. AAH-97991 or ACE-2026-000101',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: studentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Student ID *',
                    hintText: 'e.g. STU-1001 or email',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: amtCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount *',
                          hintText: '50.00',
                          prefixIcon: Icon(Icons.attach_money_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: selectedCurrency,
                        decoration: const InputDecoration(labelText: 'Currency'),
                        items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) setDlgState(() => selectedCurrency = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  decoration: const InputDecoration(labelText: 'Payment Method', prefixIcon: Icon(Icons.payment_outlined)),
                  items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedMethod = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: txnCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Transaction / Wire Reference ID',
                    hintText: 'e.g. WIRE-84839219',
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedPlan,
                  decoration: const InputDecoration(labelText: 'Milestone / Plan'),
                  items: const [
                    DropdownMenuItem(value: 'Full Payment', child: Text('Full Payment (100%)')),
                    DropdownMenuItem(value: 'Initial Deposit', child: Text('Initial Deposit (50%)')),
                    DropdownMenuItem(value: 'Remaining Milestone', child: Text('Remaining Milestone (50%)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedPlan = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Payment Status'),
                  items: const [
                    DropdownMenuItem(value: 'Completed', child: Text('Completed (Verified)')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending Clearance')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedStatus = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final aid = asmCtrl.text.trim();
                      final sid = studentCtrl.text.trim();
                      final amt = double.tryParse(amtCtrl.text.trim()) ?? 0.0;

                      if (aid.isEmpty || sid.isEmpty || amt <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill valid assignment, student, and amount'), backgroundColor: AppTheme.warning),
                        );
                        return;
                      }

                      setDlgState(() => saving = true);
                      final ok = await ApiService.createManualPayment(
                        assignmentId: aid,
                        studentId: sid,
                        amount: amt,
                        currency: selectedCurrency,
                        paymentMethod: selectedMethod,
                        transactionId: txnCtrl.text.trim(),
                        paymentPlan: selectedPlan,
                        status: selectedStatus,
                      );

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (ok) {
                        _loadPayments();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Manual payment transaction logged!'), backgroundColor: AppTheme.success),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to record payment transaction'), backgroundColor: AppTheme.danger),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }

  void _openInvoice(PaymentModel p) {
    final asm = AssignmentModel(
      assignmentId: p.assignmentId,
      studentId: p.studentId,
      title: 'Order ${p.assignmentId}',
      subject: 'Academic Support',
      assignmentType: 'Assignment',
      deadline: p.paymentDate,
      wordCount: 1500,
      price: p.amount,
      status: p.status,
      currency: p.currency,
      finalPrice: p.amount,
      paidAmount: p.amount,
      remainingBalance: 0.0,
      paymentStatus: p.status,
    );

    showDialog(
      context: context,
      builder: (_) => InvoiceViewDialog(assignment: asm, currentUser: widget.user),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Financial & Payments Ledger'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadPayments),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLogPaymentDialog,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_card_rounded, color: Colors.white),
        label: const Text('Log Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPayments,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Banner
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Gross Processed Revenue', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text(
                            '\$${_totalRevenue.toStringAsFixed(2)} USD',
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Avg Order: \$${_avgOrder.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                'Refunded: $_refundedCount',
                                style: TextStyle(color: _refundedCount > 0 ? AppTheme.warning : Colors.white70, fontSize: 12),
                              ),
                              Text(
                                '${_payments.length} Transactions',
                                style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filter chips
                    Row(
                      children: [
                        const Text('Status Filter:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                        const SizedBox(width: 8),
                        Wrap(
                          spacing: 6,
                          children: ['All', 'Completed', 'Pending', 'Refunded'].map((s) {
                            final isSel = _selectedStatusFilter == s;
                            return ChoiceChip(
                              label: Text(s, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : AppTheme.textMain)),
                              selected: isSel,
                              selectedColor: AppTheme.primary,
                              onSelected: (_) => setState(() => _selectedStatusFilter = s),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Transaction Ledger (${_filteredPayments.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                    const SizedBox(height: 12),

                    if (_filteredPayments.isEmpty)
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
                            Icon(Icons.credit_card_off_outlined, size: 48, color: AppTheme.textDim),
                            SizedBox(height: 12),
                            Text('No transactions found', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredPayments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final p = _filteredPayments[i];
                          final isPaid = p.status.toLowerCase() == 'completed' || p.status.toLowerCase() == 'paid';

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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isPaid ? AppTheme.successBg : AppTheme.warning.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
                                            color: isPaid ? AppTheme.success : AppTheme.warning,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${p.currency} \$${p.amount.toStringAsFixed(2)}',
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                                            ),
                                            Text('Order: ${p.assignmentId}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isPaid ? AppTheme.successBg : AppTheme.warning.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        p.status,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isPaid ? AppTheme.success : AppTheme.warning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 18),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Method: ${p.paymentMethod}', style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
                                        Text('Txn: ${p.transactionId}', style: const TextStyle(fontSize: 10, color: AppTheme.textDim)),
                                      ],
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () => _openInvoice(p),
                                      icon: const Icon(Icons.receipt_long_rounded, size: 14),
                                      label: const Text('Invoice', style: TextStyle(fontSize: 11)),
                                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
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
