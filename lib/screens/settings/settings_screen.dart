import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../components/index.dart';
import '../../config.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../about/about_screen.dart';
import '../updates/update_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _checkResult = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final updates = state.updateNotifier;
    final status = _checkResult.isNotEmpty
        ? _checkResult
        : updates.checked
            ? (state.hasUpdate
                ? 'Update available'
                : 'You are on the latest build')
            : 'Not checked yet';
    final available =
        _checkResult == 'Update available' ||
        (_checkResult.isEmpty && state.hasUpdate);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            BrkHeader(
              title: 'Settings',
              leading: Icons.arrow_back,
              onLeading: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                children: [
                  if (state.hasUpdate)
                    _UpdateBanner(
                      version: updates.latest?.version ?? '',
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const UpdateScreen()),
                      ),
                    ),
                  _Section('Updates'),
                  BrkCard(
                    padding: const EdgeInsets.fromLTRB(16, 6, 14, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Beta channel',
                                  style: context.appTextTheme.titleSmall
                                      ?.copyWith(color: AppColors.onSurface)),
                              const SizedBox(height: 3),
                              Text('Include pre-release builds',
                                  style: context.appTextTheme.bodySmall),
                            ],
                          ),
                        ),
                        BrkSwitch(
                          value: state.betaChannel,
                          onChanged: state.setBetaChannel,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  BrkCard(
                    onTap: () async {
                      await state.checkForUpdates(force: true);
                      if (!mounted) return;
                      setState(() => _checkResult = state.hasUpdate
                          ? 'Update available'
                          : 'You are on the latest build');
                    },
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      children: [
                        const Icon(Icons.refresh,
                            size: 19, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Check for updates',
                                  style: context.appTextTheme.titleSmall
                                      ?.copyWith(color: AppColors.onSurface)),
                              const SizedBox(height: 3),
                              Text(
                                status,
                                style: context.appTextTheme.bodySmall
                                    ?.copyWith(
                                  color: available
                                      ? AppColors.accent
                                      : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 18, color: AppColors.onSurfaceVariant),
                      ],
                    ),

                  ),
                  const SizedBox(height: 24),
                  _Section('About'),
                  BrkCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 19, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BreakLog',
                                  style: context.appTextTheme.titleSmall
                                      ?.copyWith(color: AppColors.onSurface)),
                              const SizedBox(height: 3),
                              FutureBuilder<PackageInfo>(
                                future: PackageInfo.fromPlatform(),
                                builder: (context, snap) => Text(
                                  'Version ${snap.data?.version ?? '…'}',
                                  style: context.appTextTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 18, color: AppColors.onSurfaceVariant),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  BrkCard(
                    onTap: () => launchUrl(Uri.parse(AppConfig.githubUrl),
                        mode: LaunchMode.externalApplication),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      children: [
                        const Icon(Icons.code,
                            size: 19, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Source on GitHub',
                              style: context.appTextTheme.titleSmall
                                  ?.copyWith(color: AppColors.onSurface)),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 18, color: AppColors.onSurfaceVariant),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text.toUpperCase(),
            style: context.appTextTheme.labelSmall
                ?.copyWith(color: AppColors.onSurfaceVariant)),
      );
}

class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({required this.version, required this.onOpen});

  final String version;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
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
          BrkButton(
            label: 'View',
            variant: BrkButtonVariant.secondary,
            expand: false,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}
