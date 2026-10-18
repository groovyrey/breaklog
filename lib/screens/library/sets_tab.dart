import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../sets/set_builder_screen.dart';
import '../sets/set_detail_screen.dart';

/// Sets half of the library tab: saved routine groups, with the build action
/// on the tab's own row.
class SetsTab extends StatelessWidget {
  const SetsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sets = state.sets.sets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 12, 4),
          child: Row(
            children: [
              Text(
                sets.isEmpty ? 'No sets yet' : '${sets.length} saved',
                style: context.appTextTheme.bodyMedium,
              ),
              const Spacer(),
              BrkIconButton(
                icon: Icons.add,
                accent: true,
                tooltip: 'New set',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SetBuilderScreen()),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: sets.isEmpty
              ? const BrkEmptyState(
                  icon: Icons.queue_music_outlined,
                  title: 'No sets yet',
                  message:
                      'Group vocabulary moves into a routine you can run on the floor.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                  itemCount: sets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final set = sets[i];
                    return BrkCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => SetDetailScreen(setId: set.id)),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  set.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.appTextTheme.titleLarge
                                      ?.copyWith(
                                          color: AppColors.onSurface,
                                          fontSize: 19),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${set.moveIds.length} moves   '
                                  '${set.createdAt.toLocal().toString().split(' ').first}',
                                  style: context.appTextTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right,
                              size: 20, color: AppColors.onSurfaceVariant),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
