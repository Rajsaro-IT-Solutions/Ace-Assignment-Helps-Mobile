import 'package:flutter/material.dart';
import '../core/config/api_config.dart';
import '../core/theme/app_theme.dart';
import '../services/api_service.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late TextEditingController _urlController;
  bool _testing = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });

    final currentUrl = ApiConfig.baseUrl;
    await ApiConfig.setBaseUrl(_urlController.text);

    final res = await ApiService.checkHealth();

    setState(() {
      _testing = false;
      _testSuccess = res.success;
      if (res.success && res.data != null) {
        _testResult = '${res.message}\nDatabase: ${res.data!['database']}';
      } else {
        _testResult = res.message;
        // Revert back if failed
        ApiConfig.setBaseUrl(currentUrl);
      }
    });
  }

  Future<void> _saveAndClose() async {
    await ApiConfig.setBaseUrl(_urlController.text);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server URL updated to: ${ApiConfig.baseUrl}'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppTheme.surface,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.dns_rounded, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'Backend Server',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configure the REST API endpoint used for authenticating and syncing data with AWS RDS MySQL.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),

            // Text input
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Base Server URL',
                hintText: 'http://10.0.2.2:8000',
                prefixIcon: Icon(Icons.link, size: 20),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),

            // Quick Preset Chips
            const Text(
              'Quick Presets:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textDim),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildPresetChip('Cloud Endpoint (Recommended)', ApiConfig.cloudUrl),
                _buildPresetChip('Android Emulator', ApiConfig.emulatorUrl),
                _buildPresetChip('Local Wi-Fi', ApiConfig.lanUrl),
                _buildPresetChip('Localhost', ApiConfig.localhostUrl),
              ],
            ),
            const SizedBox(height: 16),

            // Test Connection Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _testing ? null : _testConnection,
                icon: _testing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.network_check_rounded, size: 18),
                label: Text(_testing ? 'Testing Connection...' : 'Test Server Connection'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            if (_testResult != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testSuccess ? AppTheme.successBg : AppTheme.dangerBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _testSuccess ? AppTheme.success : AppTheme.danger,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _testSuccess ? Icons.check_circle : Icons.error,
                      color: _testSuccess ? AppTheme.success : AppTheme.danger,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _testSuccess ? AppTheme.success : AppTheme.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveAndClose,
          child: const Text('Save & Apply'),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, String url) {
    final isSelected = _urlController.text == url;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: AppTheme.primaryLight,
      onSelected: (_) {
        setState(() {
          _urlController.text = url;
        });
      },
    );
  }
}
