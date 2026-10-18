import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/version_checker.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final updates = state.updateNotifier;

    return Scaffold(
      appBar: AppBar(
        title: Text('Updates', style: context.appTextTheme.headlineSmall),
      ),
      body: FutureBuilder<List<ReleaseInfo>>(
        future: updates.checker
            .releases(includePrerelease: state.betaChannel),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final releases = snap.data ?? const <ReleaseInfo>[];
          final installed = updates.installed;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                installed.isEmpty
                    ? 'Installed version unknown'
                    : 'Installed: $installed',
                style: context.appTextTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (releases.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text('No releases found yet.',
                      style: context.appTextTheme.bodyMedium),
                ),
              for (final r in releases)
                _ReleaseCard(
                  release: r,
                  installedVersion: installed,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard({required this.release, required this.installedVersion});

  final ReleaseInfo release;
  final String installedVersion;

  @override
  Widget build(BuildContext context) {
    final current = release.version == installedVersion;
    final notes = release.notes.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: current ? AppColors.accent : AppColors.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('v${release.version}',
                  style: context.appTextTheme.titleLarge),
              if (release.prerelease) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('BETA',
                      style: context.appTextTheme.labelSmall
                          ?.copyWith(color: AppColors.accent)),
                ),
              ],
              const Spacer(),
              if (release.publishedAt != null)
                Text(
                  DateFormat('MMM d, y').format(release.publishedAt!),
                  style: context.appTextTheme.bodySmall,
                ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(notes, style: context.appTextTheme.bodyMedium),
          ],
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(release.url),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Open release'),
          ),
        ],
      ),
    );
  }
}
