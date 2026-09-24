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

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _accHolderCtrl.text = widget.user.name;
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
              child: Row(
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
            ),
            const SizedBox(height: 20),

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
                    const Text('Expert Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                            : const Text('Save Details'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

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
                  const Text('Set up your direct deposit bank account or PayPal for completed solution earnings.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
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
                    decoration: const InputDecoration(hintText: 'e.g. Michael Zhang', prefixIcon: Icon(Icons.badge_outlined, size: 20)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Account Number / IBAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _accNoCtrl,
                    decoration: const InputDecoration(hintText: 'e.g. GB29NWBK60161331926819', prefixIcon: Icon(Icons.numbers_outlined, size: 20)),
                  ),
                  const SizedBox(height: 12),
                  const Text('SWIFT / BIC / IFSC Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _ifscCtrl,
                    decoration: const InputDecoration(hintText: 'e.g. NWBKGB2L', prefixIcon: Icon(Icons.code_rounded, size: 20)),
                  ),
                  const SizedBox(height: 12),
                  const Text('PayPal Address (Alternative)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _paypalCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'payouts@expert.com', prefixIcon: Icon(Icons.payment_rounded, size: 20)),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savingPayout ? null : _updatePayout,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                      child: _savingPayout
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Payout Account'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Password Card
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
                    const Text('Security & Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text('Current Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _currPwdCtrl,
                      obscureText: _obscureCurr,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurr ? Icons.visibility : Icons.visibility_off, size: 18),
                          onPressed: () => setState(() => _obscureCurr = !_obscureCurr),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter current password' : null,
                    ),
                    const SizedBox(height: 14),
                    const Text('New Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _newPwdCtrl,
                      obscureText: _obscureNew,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_reset, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off, size: 18),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 14),
                    const Text('Confirm New Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmPwdCtrl,
                      obscureText: _obscureNew,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.check_circle_outline, size: 20)),
                      validator: (v) => (v == null || v.isEmpty) ? 'Confirm new password' : null,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _changingPwd ? null : _changePassword,
                        child: _changingPwd
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Update Password'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
                label: const Text('Log Out of Expert Workspace', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
