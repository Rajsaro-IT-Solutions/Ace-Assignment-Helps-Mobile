import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/assignment_model.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class InvoiceViewDialog extends StatefulWidget {
  final AssignmentModel assignment;
  final UserModel currentUser;
  final VoidCallback? onPaymentSuccess;

  const InvoiceViewDialog({
    super.key,
    required this.assignment,
    required this.currentUser,
    this.onPaymentSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required AssignmentModel assignment,
    required UserModel currentUser,
    VoidCallback? onPaymentSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InvoiceViewDialog(
        assignment: assignment,
        currentUser: currentUser,
        onPaymentSuccess: onPaymentSuccess,
      ),
    );
  }

  @override
  State<InvoiceViewDialog> createState() => _InvoiceViewDialogState();
}

class _InvoiceViewDialogState extends State<InvoiceViewDialog> {
  bool _loading = true;
  Map<String, dynamic>? _invoiceData;
  bool _processingPay = false;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    final data = await ApiService.getInvoiceDetail(widget.assignment.assignmentId);
    if (mounted) {
      setState(() {
        _invoiceData = data;
        _loading = false;
      });
    }
  }

  Future<void> _openWebInvoice() async {
    final urlStr = _invoiceData?['invoice_url'] ??
        'https://ace-assignment-helps-three.vercel.app/student/invoice.php?id=${widget.assignment.assignmentId}';
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open browser URL')),
        );
      }
    }
  }

  Future<void> _payRemainingBalance(double balance) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text('Pay remaining balance of ${widget.assignment.currency} ${balance.toStringAsFixed(2)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processingPay = true);

    final res = await ApiService.processPartialPayment(
      assignmentId: widget.assignment.assignmentId,
      studentId: widget.currentUser.id,
      amount: balance,
      paymentMethod: 'Stripe Online',
      currency: widget.assignment.currency,
    );

    if (mounted) {
      setState(() => _processingPay = false);
      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment processed successfully!'), backgroundColor: AppTheme.success),
        );
        _loadInvoice();
        widget.onPaymentSuccess?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message.isNotEmpty ? res.message : 'Payment failed'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    final total = a.finalPrice > 0 ? a.finalPrice : a.price;
    final balance = (total - a.paidAmount).clamp(0.0, double.infinity);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),

                // Top Banner
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tax Invoice',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textMain),
                        ),
                        Text(
                          'Order: ${a.assignmentId}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textDim, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: _openWebInvoice,
                      icon: const Icon(Icons.open_in_browser, size: 16),
                      label: const Text('Web / PDF'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 10),

                // Expanded Breakdown
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Student Details Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.bg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Billed To:', style: TextStyle(fontSize: 11, color: AppTheme.textDim, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(widget.currentUser.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(widget.currentUser.email, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              if (widget.currentUser.university.isNotEmpty)
                                Text(widget.currentUser.university, style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Itemized Table
                        const Text('Order Particulars', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            children: [
                              _buildRow('Topic / Title', a.title),
                              _buildRow('Discipline', a.subject),
                              _buildRow('Type', a.assignmentType),
                              _buildRow('Word Count', '${a.wordCount} words'),
                              _buildRow('Deadline', a.deadline),
                              const Divider(height: 20),
                              _buildRow('Total Investment', '${a.currency} ${total.toStringAsFixed(2)}', isBold: true),
                              _buildRow('Paid to Date', '${a.currency} ${a.paidAmount.toStringAsFixed(2)}', color: AppTheme.success, isBold: true),
                              _buildRow(
                                'Balance Due',
                                '${a.currency} ${balance.toStringAsFixed(2)}',
                                color: balance > 0 ? AppTheme.danger : AppTheme.success,
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Payment Status Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: balance <= 0 ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.warningBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: balance <= 0 ? AppTheme.success : AppTheme.warning),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                balance <= 0 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                color: balance <= 0 ? AppTheme.success : AppTheme.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  balance <= 0
                                      ? 'PAID IN FULL • Complete solution released upon expert completion'
                                      : 'PARTIALLY PAID • ${a.currency} ${balance.toStringAsFixed(2)} remaining',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: balance <= 0 ? AppTheme.success : AppTheme.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Pay Balance Button
                if (balance > 0 && widget.currentUser.isStudent)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _processingPay ? null : () => _payRemainingBalance(balance),
                        icon: const Icon(Icons.payment_rounded, size: 18),
                        label: _processingPay
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text('Pay Remaining Balance (${a.currency} ${balance.toStringAsFixed(2)})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textDim, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: color ?? AppTheme.textMain,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
