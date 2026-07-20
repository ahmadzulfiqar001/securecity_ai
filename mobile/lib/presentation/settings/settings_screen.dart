import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_notifier.dart';
import '../widgets/danger_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_header.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late bool _notificationsEnabled;
  late bool _shakeDetectionEnabled;
  late bool _voiceActivationEnabled;
  late int _sosCountdownSeconds;

  @override
  void initState() {
    super.initState();
    final storage = ref.read(storageServiceProvider);
    _notificationsEnabled = storage.getNotificationsEnabled();
    _shakeDetectionEnabled = storage.getShakeDetectionEnabled();
    _voiceActivationEnabled = storage.getVoiceActivationEnabled();
    _sosCountdownSeconds = storage.getSosCountdownSeconds();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionHeader(title: 'Appearance'),
          const SizedBox(height: 12),
          GlassCard(
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (selection) {
                ref.read(themeModeProvider.notifier).setThemeMode(selection.first);
              },
            ),
          ),
          const SizedBox(height: 32),

          const SectionHeader(title: 'Safety & Alerts'),
          const SizedBox(height: 12),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Crime, weather, and emergency alerts'),
                  value: _notificationsEnabled,
                  activeThumbColor: AppColors.accentCyan,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                    ref.read(storageServiceProvider).saveNotificationsEnabled(value);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Shake for SOS'),
                  subtitle: const Text('Trigger an SOS by shaking your phone'),
                  value: _shakeDetectionEnabled,
                  activeThumbColor: AppColors.accentCyan,
                  onChanged: (value) {
                    setState(() => _shakeDetectionEnabled = value);
                    ref.read(storageServiceProvider).saveShakeDetectionEnabled(value);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Voice-Activated SOS'),
                  subtitle: const Text('Trigger an SOS with a voice command'),
                  value: _voiceActivationEnabled,
                  activeThumbColor: AppColors.accentCyan,
                  onChanged: (value) {
                    setState(() => _voiceActivationEnabled = value);
                    ref.read(storageServiceProvider).saveVoiceActivationEnabled(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SOS Countdown: $_sosCountdownSeconds seconds',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  'Time before an SOS alert is sent automatically',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Slider(
                  value: _sosCountdownSeconds.toDouble(),
                  min: 1,
                  max: AppConstants.sosMaxCountdownSeconds.toDouble(),
                  divisions: AppConstants.sosMaxCountdownSeconds - 1,
                  label: '$_sosCountdownSeconds s',
                  activeColor: AppColors.accentCyan,
                  onChanged: (value) {
                    setState(() => _sosCountdownSeconds = value.round());
                  },
                  onChangeEnd: (value) {
                    ref.read(storageServiceProvider).saveSosCountdownSeconds(value.round());
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          const SectionHeader(title: 'Legal'),
          const SizedBox(height: 12),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _openUrl(AppConstants.privacyPolicyUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _openUrl(AppConstants.termsOfServiceUrl),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          DangerButton(
            label: 'Sign Out',
            icon: Icons.logout,
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
