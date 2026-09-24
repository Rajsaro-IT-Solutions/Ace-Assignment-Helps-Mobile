import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

class ExpertProfileScreen extends StatefulWidget {
  final UserModel user;

  const ExpertProfileScreen({super.key, required this.user});

  @override
  State<ExpertProfileScreen> createState() => _ExpertProfileScreenState();
}

class _ExpertProfileScreenState extends State<ExpertProfileScreen> {
  final _profileKey = GlobalKey<FormState>();
  final _pwdKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  final _currPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  final _bankNameCtrl = TextEditingController();
  final _accHolderCtrl = TextEditingController();
  final _accNoCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _paypalCtrl = TextEditingController();

  bool _obscureCurr = true;
  bool _obscureNew = true;
  bool _savingProfile = false;
  bool _changingPwd = false;
  bool _savingPayout = false;

  String _status = 'Available';
  double _rating = 4.95;
  int _completedCount = 0;
  List<String> _subjects = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _accHolderCtrl.text = widget.user.name;
    _loadExpertDetails();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _currPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    _bankNameCtrl.dispose();
    _accHolderCtrl.dispose();
    _accNoCtrl.dispose();
    _ifscCtrl.dispose();
    _paypalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExpertDetails() async {
    final details = await ApiService.getExpertProfileDetails(expertId: widget.user.id);
    if (mounted && details != null) {
      setState(() {
        _status = details['status']?.toString() ?? 'Available';
        _rating = double.tryParse(details['rating']?.toString() ?? '4.95') ?? 4.95;
        _completedCount = int.tryParse(details['completed_count']?.toString() ?? '0') ?? 0;

        final rawSubs = details['subjects'];
        if (rawSubs is String && rawSubs.isNotEmpty) {
          try {
            final parsed = jsonDecode(rawSubs);
            if (parsed is List) {
              _subjects = parsed.map((e) => e.toString()).toList();
            }
          } catch (_) {
            _subjects = rawSubs.split(',').map((e) => e.trim()).toList();
          }
        }
      });
    }
  }

  Future<void> _toggleAvailability(bool isAvailable) async {
    final newStatus = isAvailable ? 'Available' : 'Busy';
    setState(() => _status = newStatus);

    final ok = await ApiService.toggleExpertAvailability(
      expertId: widget.user.id,
      status: newStatus,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Roster status updated to $newStatus' : 'Failed to update roster status'),
          backgroundColor: ok ? AppTheme.success : AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _updatePayout() async {
    setState(() => _savingPayout = true);
    final ok = await ApiService.updateExpertPayout(
      expertId: widget.user.id,
      bankName: _bankNameCtrl.text.trim(),
      accountHolder: _accHolderCtrl.text.trim(),
      accountNumber: _accNoCtrl.text.trim(),
      ifscSwift: _ifscCtrl.text.trim(),
      paypalEmail: _paypalCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _savingPayout = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Payout details updated successfully!' : 'Failed to update payout details.'),
        backgroundColor: ok ? AppTheme.success : AppTheme.danger,
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (!_profileKey.currentState!.validate()) return;
    setState(() => _savingProfile = true);

    final ok = await ApiService.updateProfile(
      userId: widget.user.id,
      role: 'Expert',
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _savingProfile = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Profile updated successfully!' : 'Failed to update profile.'),
        backgroundColor: ok ? AppTheme.success : AppTheme.danger,
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_pwdKey.currentState!.validate()) return;
    if (_newPwdCtrl.text != _confirmPwdCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match.'), backgroundColor: AppTheme.danger),
      );
      return;
    }

    setState(() => _changingPwd = true);

    final res = await ApiService.changePassword(
      userId: widget.user.id,
      role: 'Expert',
      currentPassword: _currPwdCtrl.text.trim(),
      newPassword: _newPwdCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _changingPwd = false);

    if (res.success) {
      _currPwdCtrl.clear();
      _newPwdCtrl.clear();
      _confirmPwdCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully!'), backgroundColor: AppTheme.success),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message.isNotEmpty ? res.message : 'Password change failed.'), backgroundColor: AppTheme.danger),
      );
    }
  }

  void _handleLogout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = _status.toLowerCase() == 'available';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Expert Profile & Security'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.successBg,
                        child: Text(
                          widget.user.initials,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.success),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                            ),
                            Text(
                              widget.user.email,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.successBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ID: ${widget.user.id} • PhD Academic Expert',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Metrics Row (Rating & Completed)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  _rating.toStringAsFixed(2),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text('Quality Rating', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: AppTheme.border),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '$_completedCount',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                            ),
                            const SizedBox(height: 2),
                            const Text('Solutions Authored', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: AppTheme.border),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              _status,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isAvailable ? AppTheme.success : AppTheme.warning,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text('Roster Status', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Availability Toggle Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Roster Availability',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAvailable ? 'Currently accepting new coursework briefs' : 'Roster marked busy; no new tasks allocated',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  Switch(
                    value: isAvailable,
                    activeColor: AppTheme.success,
                    onChanged: (v) => _toggleAvailability(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Academic Disciplines / Subjects
            if (_subjects.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.school_rounded, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Text('Academic Subject Domains', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _subjects.map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Profile Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Form(
                key: _profileKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Expert Profile Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text('Full Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline, size: 20)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
                    ),
                    const SizedBox(height: 14),
                    const Text('Contact Phone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined, size: 20)),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _savingProfile ? null : _updateProfile,
                        child: _savingProfile
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save Profile Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payout Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primary, size: 20),
                      SizedBox(width: 8),
                      Text('Remittance & Payout Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Direct deposit bank details or PayPal for solution compensation.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(height: 16),
                  const Text('Bank Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _bankNameCtrl,
                    decoration: const InputDecoration(hintText: 'e.g. Barclays / Chase / HDFC', prefixIcon: Icon(Icons.account_balance_outlined, size: 20)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Account Beneficiary Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _accHolderCtrl,
                    decoration: const InputDecoration(hintText: 'e.g. Dr. Michael Zhang', prefixIcon: Icon(Icons.badge_outlined, size: 20)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Account Number / IBAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _accNoCtrl,
                    decoration: const InputDecoration(hintText: 'Enter bank account number', prefixIcon: Icon(Icons.numbers_outlined, size: 20)),
                  ),
                  const SizedBox(height: 12),
                  const Text('IFSC / SWIFT / Routing Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _ifscCtrl,
                    decoration: const InputDecoration(hintText: 'e.g. BARCGB22', prefixIcon: Icon(Icons.qr_code_scanner_outlined, size: 20)),
                  ),
                  const SizedBox(height: 12),
                  const Text('PayPal Remittance Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _paypalCtrl,
                    decoration: const InputDecoration(hintText: 'e.g. michael.zhang@paypal.me', prefixIcon: Icon(Icons.payment_outlined, size: 20)),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savingPayout ? null : _updatePayout,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF047857)),
                      child: _savingPayout
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Update Payout Settings'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Password Change Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Form(
                key: _pwdKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Text('Change Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Current Password *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _currPwdCtrl,
                      obscureText: _obscureCurr,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_clock_outlined, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurr ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                          onPressed: () => setState(() => _obscureCurr = !_obscureCurr),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Please enter current password' : null,
                    ),
                    const SizedBox(height: 14),
                    const Text('New Password *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _newPwdCtrl,
                      obscureText: _obscureNew,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.key_outlined, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? 'Must be at least 6 characters' : null,
                    ),
                    const SizedBox(height: 14),
                    const Text('Confirm New Password *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmPwdCtrl,
                      obscureText: _obscureNew,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.key_rounded, size: 20)),
                      validator: (v) => (v == null || v.isEmpty) ? 'Please confirm password' : null,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _changingPwd ? null : _changePassword,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
                        child: _changingPwd
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Update Password'),
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
