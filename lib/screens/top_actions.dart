import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/index.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'profile/profile_screen.dart';
import 'settings/settings_screen.dart';

/// Profile and settings entries that sit in the top bar of the root screens.
class TopBarActions extends StatelessWidget {
  const TopBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!state.online) ...[
          const Tooltip(
            message: 'Offline. Your library still works and syncs later.',
            child: Icon(Icons.cloud_off_outlined,
                size: 18, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: 6),
          Text(
            'Offline',
            style: context.appTextTheme.labelMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
        ],
        GestureDetector(
          onTap: () => _open(context, const ProfileScreen()),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: BrkAvatar(photoUrl: state.auth.photoUrl),
          ),
        ),
        BrkIconButton(
          icon: Icons.settings_outlined,
          tooltip: 'Settings',
          badge: state.hasUpdate,
          onTap: () => _open(context, const SettingsScreen()),
        ),
      ],
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}
