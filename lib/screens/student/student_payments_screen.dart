import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/models/portal_models.dart';
import '../../core/models/assignment_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import 'invoice_view_dialog.dart';

class StudentPaymentsScreen extends StatefulWidget {
  final UserModel user;

  const StudentPaymentsScreen({super.key, required this.user});

  @override
  State<StudentPaymentsScreen> createState() => _StudentPaymentsScreenState();
}

class _StudentPaymentsScreenState extends State<StudentPaymentsScreen> {
  bool _loading = true;
  List<PaymentModel> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _loading = true);
    final list = await ApiService.getPayments(studentId: widget.user.id);
    if (mounted) {
      setState(() {
        _payments = list;
        _loading = false;
      });
    }
  }

  double get _totalPaid {
    return _payments
        .where((p) => p.status.toLowerCase() == 'paid' || p.status.toLowerCase() == 'completed')
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Invoices & Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadPayments,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPayments,
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
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Financial Investment',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '\$${_totalPaid.toStringAsFixed(2)} USD',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildMetricPill(
                                '${_payments.length} Invoices',
                                Colors.white.withValues(alpha: 0.15),
                                Colors.white,
                              ),
                              const SizedBox(width: 8),
                              _buildMetricPill(
                                'AWS RDS Synced',
                                AppTheme.success.withValues(alpha: 0.25),
                                const Color(0xFF34D399),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment History (${_payments.length})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_payments.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textDim),
                            SizedBox(height: 12),
                            Text(
                              'No invoices found',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'When you submit assignments, invoice and payment logs will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _payments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final p = _payments[i];
                          final isPaid = p.status.toLowerCase() == 'paid' || p.status.toLowerCase() == 'completed';

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
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        p.paymentId,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isPaid ? AppTheme.successBg : AppTheme.warningBg,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: isPaid ? AppTheme.success : AppTheme.warning),
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
                                const SizedBox(height: 10),
                                Text(
                                  p.assignmentTitle,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Order ID: ${p.assignmentId} • ${p.assignmentSubject}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.paymentMethod,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDim),
                                        ),
                                        Text(
                                          p.paymentDate.split(' ')[0],
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textDim),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${p.amount.toStringAsFixed(2)} ${p.currency}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      final dummyAsm = AssignmentModel(
                                        assignmentId: p.assignmentId,
                                        studentId: p.studentId,
                                        title: p.assignmentTitle,
                                        subject: p.assignmentSubject,
                                        assignmentType: 'Assignment Order',
                                        status: p.status,
                                        deadline: p.paymentDate,
                                        wordCount: 1000,
                                        price: p.amount,
                                        finalPrice: p.amount,
                                        currency: p.currency,
                                        paidAmount: p.amount,
                                      );
                                      InvoiceViewDialog.show(
                                        context,
                                        assignment: dummyAsm,
                                        currentUser: widget.user,
                                        onPaymentSuccess: _loadPayments,
                                      );
                                    },
                                    icon: const Icon(Icons.receipt_long_rounded, size: 16),
                                    label: const Text('View Tax Invoice & Breakdown', style: TextStyle(fontSize: 12)),
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

  Widget _buildMetricPill(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textCol),
      ),
    );
  }
}
