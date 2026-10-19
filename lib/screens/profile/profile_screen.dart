import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// Account and identity settings: who is signed in and the name they battle
/// under. Reached from the top bar, so this always has a signed in account.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _alias;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _alias = TextEditingController(text: context.read<AppState>().alias);
  }

  @override
  void dispose() {
    _alias.dispose();
    super.dispose();
  }

  Future<void> _saveAlias() async {
    await context.read<AppState>().setAlias(_alias.text);
    if (!mounted) return;
    setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final auth = state.auth;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            BrkHeader(
              title: 'Profile',
              leading: Icons.arrow_back,
              onLeading: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                children: [
                  Row(
                    children: [
                      BrkAvatar(photoUrl: auth.photoUrl, size: 64),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.displayName,
                              style: context.appTextTheme.titleMedium
                                  ?.copyWith(color: AppColors.onSurface),
                            ),
                            const SizedBox(height: 3),
                            Text(auth.email,
                                style: context.appTextTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  BrkField(
                    controller: _alias,
                    label: 'Breaking alias',
                    hint: 'The name you battle under',
                    onChanged: (_) {
                      if (_saved) setState(() => _saved = false);
                    },
                  ),
                  const SizedBox(height: 14),
                  BrkButton(
                    label: 'Save alias',
                    variant: BrkButtonVariant.secondary,
                    onPressed: _saveAlias,
                  ),
                  if (_saved) ...[
                    const SizedBox(height: 10),
                    Text(
                      state.aliasPending
                          ? 'Saved here. Your account catches up next sign in.'
                          : 'Alias saved to your account',
                      style: context.appTextTheme.bodySmall?.copyWith(
                        color: state.aliasPending
                            ? AppColors.onSurfaceVariant
                            : AppColors.accent,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  BrkButton(
                    label: 'Sign out',
                    variant: BrkButtonVariant.secondary,
                    icon: Icons.logout,
                    onPressed: auth.signOut,
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
