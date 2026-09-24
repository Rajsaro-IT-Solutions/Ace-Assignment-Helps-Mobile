import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  final UserModel user;

  const AdminSettingsScreen({super.key, required this.user});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _siteNameCtrl = TextEditingController(text: 'Ace Assignment Helps');
  final _phoneCtrl = TextEditingController(text: '+44 7911 123456');
  final _waCtrl = TextEditingController(text: '+91 8233432123');
  final _emailCtrl = TextEditingController(text: 'support@aceassignmenthelps.com');
  final _currencyCtrl = TextEditingController(text: 'USD');
  final _wordRateCtrl = TextEditingController(text: '0.045');
  final _depositCtrl = TextEditingController(text: '20');
  final _slaHoursCtrl = TextEditingController(text: '24');
  bool _turnitinPolicy = true;

  bool _loading = true;
  bool _saving = false;
  String _dbStatus = 'Checking...';

  @override
  void initState() {
    super.initState();
    _fetchSettings();
    _checkDb();
  }

  @override
  void dispose() {
    _siteNameCtrl.dispose();
    _phoneCtrl.dispose();
    _waCtrl.dispose();
    _emailCtrl.dispose();
    _currencyCtrl.dispose();
    _wordRateCtrl.dispose();
    _depositCtrl.dispose();
    _slaHoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkDb() async {
    final res = await ApiService.checkHealth();
    if (mounted) {
      setState(() {
        _dbStatus = res.success ? 'Connected (AWS RDS MySQL Online)' : 'Disconnected';
      });
    }
  }

  Future<void> _fetchSettings() async {
    setState(() => _loading = true);
    final data = await ApiService.getSiteSettings();
    if (mounted) {
      setState(() {
        if (data != null) {
          if (data['site_name'] != null) _siteNameCtrl.text = data['site_name'].toString();
          if (data['support_phone'] != null) _phoneCtrl.text = data['support_phone'].toString();
          if (data['whatsapp_number'] != null) _waCtrl.text = data['whatsapp_number'].toString();
          if (data['support_email'] != null) _emailCtrl.text = data['support_email'].toString();
          if (data['default_currency'] != null) _currencyCtrl.text = data['default_currency'].toString();
          if (data['price_per_word'] != null) _wordRateCtrl.text = data['price_per_word'].toString();
          if (data['min_deposit_percent'] != null) _depositCtrl.text = data['min_deposit_percent'].toString();
          if (data['sla_buffer_hours'] != null) _slaHoursCtrl.text = data['sla_buffer_hours'].toString();
          if (data['turnitin_policy'] != null) _turnitinPolicy = data['turnitin_policy'] == '1';
        }
        _loading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final ok = await ApiService.updateSiteSettings({
      'site_name': _siteNameCtrl.text.trim(),
      'support_phone': _phoneCtrl.text.trim(),
      'whatsapp_number': _waCtrl.text.trim(),
      'support_email': _emailCtrl.text.trim(),
      'default_currency': _currencyCtrl.text.trim(),
      'price_per_word': _wordRateCtrl.text.trim(),
      'min_deposit_percent': _depositCtrl.text.trim(),
      'sla_buffer_hours': _slaHoursCtrl.text.trim(),
      'turnitin_policy': _turnitinPolicy ? '1' : '0',
    });

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Site settings updated successfully!' : 'Failed to save settings.'),
          backgroundColor: ok ? AppTheme.success : AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Platform Global Settings'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchSettings),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Infrastructure Status Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.dns_rounded, color: AppTheme.success, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Database Infrastructure', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(_dbStatus, style: const TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            onPressed: _checkDb,
                            tooltip: 'Test Database Connectivity',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Brand & Support
                    const Text('Brand & Support Contacts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                    const SizedBox(height: 12),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _siteNameCtrl,
                              decoration: const InputDecoration(labelText: 'Platform Name *', prefixIcon: Icon(Icons.business_outlined)),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailCtrl,
                              decoration: const InputDecoration(labelText: 'Support Email *', prefixIcon: Icon(Icons.email_outlined)),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneCtrl,
                              decoration: const InputDecoration(labelText: 'Support Phone', prefixIcon: Icon(Icons.phone_outlined)),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _waCtrl,
                              decoration: const InputDecoration(labelText: 'WhatsApp Desk Number', prefixIcon: Icon(Icons.chat_outlined)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pricing & Policies
                    const Text('Pricing & Service Policies', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                    const SizedBox(height: 12),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _currencyCtrl,
                                    decoration: const InputDecoration(labelText: 'Default Currency', prefixIcon: Icon(Icons.money_rounded)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _wordRateCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Price Per Word', prefixIcon: Icon(Icons.edit_note_rounded)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _depositCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Min Deposit (%)', prefixIcon: Icon(Icons.percent_rounded)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _slaHoursCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'SLA Buffer (Hrs)', prefixIcon: Icon(Icons.schedule_rounded)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SwitchListTile(
                              title: const Text('100% Turnitin Plagiarism Guarantee Badge', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: const Text('Enforce free AI / Turnitin scan report with all solutions', style: TextStyle(fontSize: 11)),
                              value: _turnitinPolicy,
                              onChanged: (val) => setState(() => _turnitinPolicy = val),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveSettings,
                        icon: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_rounded),
                        label: const Text('Save Platform Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
