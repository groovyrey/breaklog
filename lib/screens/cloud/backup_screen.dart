import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../config.dart';
import '../../services/media_backup.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// Copies attachment files into a `BreakLog` folder in the user's own Drive.
/// Sign in happens at the app root, so an account is always present here.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;
  String _status = '';

  Future<void> _run() async {
    final state = context.read<AppState>();
    setState(() {
      _busy = true;
      _status = 'Looking for files to send';
    });
    try {
      final report = await MediaBackup(
        moves: state.moves,
        accessToken: state.auth.driveAccessToken,
      ).run(
        onProgress: (done, total, name) {
          if (!mounted) return;
          setState(() => _status = 'Sending ${done + 1} of $total: $name');
        },
      );
      if (!mounted) return;
      setState(() => _status = _summary(report));
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _status = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _summary(BackupReport report) {
    if (report.failed > 0) {
      final detail = report.firstError ?? '';
      return '${report.uploaded} uploaded, ${report.failed} failed. $detail';
    }
    if (report.uploaded == 0) return 'Everything is already in Drive';
    return '${report.uploaded} uploaded';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppState>().auth;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            BrkHeader(
              title: 'Media backup',
              leading: Icons.arrow_back,
              onLeading: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                children: [
                  BrkCard(
                    child: Column(
                      children: [
                        BrkRow(label: 'Account', value: auth.email),
                        const Divider(height: 1, color: AppColors.outline),
                        BrkRow(
                            label: 'Folder', value: AppConfig.driveFolderName),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  BrkButton(
                    label: 'Back up now',
                    icon: Icons.cloud_upload,
                    loading: _busy,
                    onPressed: _run,
                  ),
                  if (_status.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(_status, style: context.appTextTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
