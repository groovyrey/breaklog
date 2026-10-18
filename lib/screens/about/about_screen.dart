import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config.dart';
import '../../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About', style: context.appTextTheme.headlineSmall),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text('BreakLog', style: context.appTextTheme.displayLarge),
          const SizedBox(height: 4),
          Text('A personal bboy move log.',
              style: context.appTextTheme.bodyLarge),
          const SizedBox(height: 24),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) => Text(
              'Version ${snap.data?.version ?? '…'} '
              '(build ${snap.data?.buildNumber ?? '…'})',
              style: context.appTextTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          Text('What it does', style: context.appTextTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Log every toprock, footwork, power, freeze, and combo you are '
            'working on. Rate difficulty, keep drill notes, attach reference '
            'videos, and watch your library grow.',
            style: context.appTextTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Text('Where your data lives', style: context.appTextTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Everything is stored locally on this device. No account, no '
            'server, no analytics.',
            style: context.appTextTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(AppConfig.githubUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.code, size: 18),
            label: const Text('Source on GitHub'),
          ),
        ],
      ),
    );
  }
}
