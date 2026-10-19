import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// The wall in front of the library. One way in: a Google account.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppState>().auth;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BreakLog',
                style: context.appTextTheme.headlineMedium
                    ?.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to open your library.',
                style: context.appTextTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              BrkButton(
                label: 'Continue with Google',
                icon: Icons.login,
                loading: auth.busy,
                onPressed: () => auth.signIn(),
              ),
              if (auth.error != null) ...[
                const SizedBox(height: 14),
                Text(
                  auth.error!,
                  style: context.appTextTheme.bodySmall
                      ?.copyWith(color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
