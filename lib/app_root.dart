import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'components/index.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/shell.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

/// Picks what the app shows at the root.
///
/// The library is behind Google sign in, so signing out or an expired session
/// lands back on the wall instead of on local data.
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.inited) return const _Loading();
    if (!state.auth.configured) return const _NeedsClientId();
    if (!state.auth.signedIn) return const SignInScreen();
    return const AppShell();
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrkSpinner(size: 22, stroke: 2),
            const SizedBox(height: 14),
            Text('Opening your log', style: context.appTextTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _NeedsClientId extends StatelessWidget {
  const _NeedsClientId();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BrkEmptyState(
          icon: Icons.key_off_outlined,
          title: 'Sign in is not available',
          message: 'This build has no Google client id, so accounts cannot open.',
        ),
      ),
    );
  }
}
