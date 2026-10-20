import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/cooldown_notice.dart';

/// Profile. The details the user battles under, kept on this device and, when
/// signed in, on the account.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _alias;
  late final TextEditingController _why;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _alias = TextEditingController(text: state.alias);
    _why = TextEditingController(text: state.why);
    _startedAt = state.startedAt;
  }

  @override
  void dispose() {
    _alias.dispose();
    _why.dispose();
    super.dispose();
  }

  Future<void> _pickStarted() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startedAt ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _startedAt = picked);
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    final outcome = await state.saveProfile(
      alias: _alias.text,
      startedAt: _startedAt,
      why: _why.text,
    );
    if (!mounted) return;
    if (outcome == ProfileSaveOutcome.busy) return;
    final ends = state.profileLockEndsAt;
    switch (outcome) {
      case ProfileSaveOutcome.saved:
        showBrkToast(context, 'Profile saved to your account',
            icon: Icons.check_circle_outline);
      case ProfileSaveOutcome.localOnly:
        showBrkToast(context, 'Saved here. Your account catches up next sign in.',
            icon: Icons.cloud_off_outlined);
      case ProfileSaveOutcome.tooSoon:
        showBrkToast(
          context,
          ends == null
              ? 'Profile can only be updated once a week'
              : cooldownNotice(ends),
          icon: Icons.lock_outline,
        );
      case ProfileSaveOutcome.busy:
        break;
    }
  }

  Future<void> _signOut() async {
    final navigator = Navigator.of(context);
    await context.read<AppState>().auth.signOut();
    if (!mounted) return;
    showBrkToast(context, 'Signed out', icon: Icons.logout);
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final auth = state.auth;
    final lockEnds = state.profileLockEndsAt;
    // Inside the weekly window the whole form is read only, so nothing can be
    // typed that the account will not take.
    final frozen = state.profileLocked || state.profileSaving;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            BrkHeader(
              title: 'Profile',
              mark: const BrkBrandMark(),
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
                    readOnly: frozen,
                  ),
                  const SizedBox(height: 20),
                  _label('Started breaking'),
                  const SizedBox(height: 10),
                  BrkCard(
                    onTap: frozen ? null : _pickStarted,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 15),
                    child: Row(
                      children: [
                        const Icon(Icons.event_outlined,
                            size: 19, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Text(
                          _startedAt == null
                              ? 'Pick a date'
                              : DateFormat.yMMMd().format(_startedAt!),
                          style: context.appTextTheme.titleSmall?.copyWith(
                            color: _startedAt == null
                                ? AppColors.onSurfaceVariant
                                : AppColors.onSurface,
                          ),
                        ),
                        const Spacer(),
                        if (!frozen)
                          const Icon(Icons.chevron_right,
                              size: 18, color: AppColors.onSurfaceVariant),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  BrkField(
                    controller: _why,
                    label: 'Why you break',
                    hint: 'What keeps you going',
                    maxLines: 3,
                    readOnly: frozen,
                  ),
                  const SizedBox(height: 24),
                  BrkButton(
                    label: 'Save profile',
                    variant: BrkButtonVariant.secondary,
                    loading: state.profileSaving,
                    onPressed: frozen ? null : _save,
                  ),
                  if (lockEnds != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      cooldownNotice(lockEnds),
                      style: context.appTextTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 28),
                  BrkButton(
                    label: 'Sign out',
                    variant: BrkButtonVariant.secondary,
                    icon: Icons.logout,
                    onPressed: _signOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text.toUpperCase(),
        style: context.appTextTheme.labelSmall
            ?.copyWith(color: AppColors.onSurfaceVariant),
      );
}
