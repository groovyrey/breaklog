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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Text(
                'BreakLog',
                style: context.appTextTheme.displayLarge
                    ?.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: 14),
              Text(
                'A personal log for your bboy moves.',
                style: context.appTextTheme.bodyLarge
                    ?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const Spacer(flex: 3),
              BrkButton(
                label: 'Continue with Google',
                variant: BrkButtonVariant.light,
                leading: Image.asset(
                  'assets/images/google_g.png',
                  width: 18,
                  height: 18,
                ),
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
              const SizedBox(height: 20),
              Text(
                'Presented to you by',
                style: context.appTextTheme.bodySmall
                    ?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              BrkCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/partner_logo.png', height: 30),
                    const SizedBox(width: 12),
                    Text(
                      'BreakSmiths Crew',
                      style: context.appTextTheme.titleSmall
                          ?.copyWith(color: AppColors.onSurface),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
