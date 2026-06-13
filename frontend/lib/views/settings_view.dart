import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final _apiUrlController = TextEditingController();
  final _wsUrlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _apiUrlController.text = settings.apiUrl;
    _wsUrlController.text = settings.wsUrl;
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _wsUrlController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final api = _apiUrlController.text.trim();
    final ws = _wsUrlController.text.trim();

    await ref.read(settingsProvider.notifier).updateSettings(apiUrl: api, wsUrl: ws);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection URLs updated successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  void _reset() async {
    await ref.read(settingsProvider.notifier).resetSettings();
    final settings = ref.read(settingsProvider);
    setState(() {
      _apiUrlController.text = settings.apiUrl;
      _wsUrlController.text = settings.wsUrl;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings restored to factory defaults.'),
          backgroundColor: Color(0xFF6366F1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backend Settings',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure host connections for the trading core server.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _apiUrlController,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'API Base Server URL',
                      labelStyle: const TextStyle(color: Color(0xFF64748B)),
                      helperText: 'REST server URL endpoint (e.g. login, orders, holdings)',
                      helperStyle: const TextStyle(color: Color(0xFF64748B)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'URL is required' : null,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _wsUrlController,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'WebSocket URL',
                      labelStyle: const TextStyle(color: Color(0xFF64748B)),
                      helperText: 'WS protocol server endpoint (e.g. ws://localhost:8000)',
                      helperStyle: const TextStyle(color: Color(0xFF64748B)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'URL is required' : null,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: _reset,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: BorderSide(color: Theme.of(context).dividerColor),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        ),
                        child: const Text('Reset Defaults'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
