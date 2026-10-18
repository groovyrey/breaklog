import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../about/about_screen.dart';
import '../updates/update_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final updates = state.updateNotifier;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: context.appTextTheme.headlineSmall),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (state.hasUpdate)
            _UpdateBanner(
              version: updates.latest?.version ?? '',
              onOpen: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UpdateScreen()),
              ),
            ),
          Text('Updates', style: context.appTextTheme.titleMedium),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            value: state.betaChannel,
            onChanged: state.setBetaChannel,
            activeThumbColor: AppColors.accent,
            contentPadding: EdgeInsets.zero,
            title: const Text('Beta channel'),
            subtitle: Text(
              'Include pre-release builds in update checks.',
              style: context.appTextTheme.bodyMedium,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.refresh, color: AppColors.onSurfaceVariant),
            title: const Text('Check for updates'),
            subtitle: Text(
              updates.checked
                  ? updates.hasUpdate
                      ? 'Update available'
                      : 'You are on the latest build'
                  : 'Not checked yet',
              style: context.appTextTheme.bodyMedium,
            ),
            onTap: () async {
              await state.checkForUpdates(force: true);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.hasUpdate
                        ? 'Update available'
                        : 'You are on the latest build'),
                  ),
                );
              }
            },
          ),
          const Divider(height: 32),
          Text('About', style: context.appTextTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline,
                color: AppColors.onSurfaceVariant),
            title: const Text('BreakLog'),
            subtitle: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snap) => Text(
                'Version ${snap.data?.version ?? '…'}',
                style: context.appTextTheme.bodyMedium,
              ),
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                const Icon(Icons.code, color: AppColors.onSurfaceVariant),
            title: const Text('Source on GitHub'),
            onTap: () => launchUrl(Uri.parse(AppConfig.githubUrl),
                mode: LaunchMode.externalApplication),
          ),
        ],
      ),
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({required this.version, required this.onOpen});

  final String version;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.accent),
      ),
      child: Row(
        children: [
          const Icon(Icons.system_update, color: AppColors.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Version $version is out',
              style: context.appTextTheme.titleSmall
                  ?.copyWith(color: AppColors.onSurface),
            ),
          ),
          TextButton(onPressed: onOpen, child: const Text('View')),
        ],
      ),
    );
  }
}
