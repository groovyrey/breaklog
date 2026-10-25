

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../shell.dart';
import '../top_actions.dart';
import 'crew_create_screen.dart';
import 'crew_settings_screen.dart';


String _fmtDate(dynamic v) {
  if (v == null) return '';
  final ms = v is int ? v : (int.tryParse(v.toString()) ?? 0);
  if (ms == 0) return '';
  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${dt.month}/${dt.day}/${dt.year}';
}

class CrewScreen extends StatelessWidget {
  const CrewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Builder(
                builder: (ctx) => BrkHeader(
                  title: 'Crew',
                  onMenu: () {
                    final state = ctx.findAncestorStateOfType<AppShellState>();
                    state?.toggleDrawer();
                  },
                  actions: const [TopBarActions()],
                ),
              ),
              Container(
                color: AppColors.surface,
                child: const TabBar(
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.onSurfaceVariant,
                  indicatorColor: AppColors.accent,
                  tabs: [
                    Tab(text: 'My Crew'),
                    Tab(text: 'Find Crews'),
                    Tab(text: 'Social'),
                  ],
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    _MyCrewTab(),
                    _FindCrewsTab(),
                    _SocialTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyCrewTab extends StatefulWidget {
  const _MyCrewTab();

  @override
  State<_MyCrewTab> createState() => _MyCrewTabState();
}

class _MyCrewTabState extends State<_MyCrewTab> {
  bool _loading = true;
  List<Map<String, dynamic>> _crews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      final state = context.read<AppState>();
      final token = await state.auth.idToken();
      if (token == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final res = await state.api.getMyCrews(token);
      if (mounted) {
        setState(() {
          _crews = (res['crews'] as List? ?? [])
              .cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      if (mounted) {
        showBrkToast(context, e.toString(), icon: Icons.error_outline);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: BrkSpinner());
    }
    if (_crews.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          BrkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No crew yet',
                  style: context.appTextTheme.titleMedium
                      ?.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create your own crew or find one to join.',
                  style: context.appTextTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: BrkButton(
                        label: 'Create crew',
                        icon: Icons.add,
                        onPressed: () async {
                          final created = await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const CrewCreateScreen()),
                          );
                          if (created == true) _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BrkButton(
                        label: 'Find crews',
                        variant: BrkButtonVariant.secondary,
                        onPressed: () {
                          DefaultTabController.of(context).animateTo(1);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        for (final crew in _crews) ...[
          BrkCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _CrewDetailScreen(crew: crew)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.surfaceVariant,
                  backgroundImage: crew['photo_url'] != null
                      ? NetworkImage(crew['photo_url'])
                      : null,
                  child: crew['photo_url'] == null
                      ? const Icon(Icons.groups, color: AppColors.onSurfaceVariant)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crew['name'] ?? '',
                        style: context.appTextTheme.titleSmall
                            ?.copyWith(color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        crew['role'] == 'founder' ? 'Founder' : 'Member',
                        style: context.appTextTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 6),
        BrkButton(
          label: 'Create crew',
          icon: Icons.add,
          onPressed: () async {
            final created = await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CrewCreateScreen()),
            );
            if (created == true) _load();
          },
        ),
      ],
    );
  }


}

class _CrewDetailScreen extends StatefulWidget {
  const _CrewDetailScreen({required this.crew});

  final Map<String, dynamic> crew;

  @override
  State<_CrewDetailScreen> createState() => _CrewDetailScreenState();
}

class _CrewDetailScreenState extends State<_CrewDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final state = context.read<AppState>();
      final token = await state.auth.idToken();
      if (token == null) return;
      final res = await state.api.getCrew(token, widget.crew['crew_id']);
      if (mounted) setState(() => _detail = res);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final crew = _detail?['crew'] ?? widget.crew;
    final members = (_detail?['members'] as List? ?? []).cast<Map<String, dynamic>>();
    final isMember = _detail?['isMember'] == true;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BrkHeader(
              title: crew['name'] ?? 'Crew',
              leading: Icons.arrow_back,
              onLeading: () => Navigator.of(context).pop(),
              actions: () {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                final isFounder = widget.crew['role'] == 'founder' ||
                    crew['founder_id'] == uid ||
                    _detail?['crew']?['founder_id'] == uid;
                if (!isFounder) return <Widget>[];
                return [
                  BrkIconButton(
                    icon: Icons.settings_outlined,
                    onTap: () async {
                      final changed = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CrewSettingsScreen(
                            crew: {...crew, ...widget.crew, ...(_detail?['crew'] ?? {})},
                          ),
                        ),
                      );
                      if (changed == true && mounted) _load();
                    },
                    size: 40,
                  )
                ];
              }(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                children: [
                  BrkCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.surfaceVariant,
                          backgroundImage: crew['photo_url'] != null
                              ? NetworkImage(crew['photo_url'])
                              : null,
                          child: crew['photo_url'] == null
                              ? const Icon(Icons.groups,
                                  color: AppColors.onSurfaceVariant)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                crew['name'] ?? '',
                                style: context.appTextTheme.titleLarge
                                    ?.copyWith(color: AppColors.onSurface),
                              ),
                              if ((crew['bio'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  crew['bio'],
                                  style: context.appTextTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Members',
                    style: context.appTextTheme.titleSmall
                        ?.copyWith(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 10),
                  if (_loading)
                    const Center(child: BrkSpinner())
                  else if (members.isEmpty)
                    BrkCard(
                      child: Text(
                        'Members hidden by settings',
                        style: context.appTextTheme.bodySmall,
                      ),
                    )
                  else
                    for (final m in members) ...[
                      BrkCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.surfaceVariant,
                              backgroundImage: m['picture'] != null
                                  ? NetworkImage(m['picture'])
                                  : null,
                              child: m['picture'] == null
                                  ? const Icon(Icons.person,
                                      color: AppColors.onSurfaceVariant)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m['alias']?.toString().isNotEmpty == true
                                        ? m['alias']
                                        : (m['name'] ?? 'Member'),
                                    style: context.appTextTheme.bodyMedium,
                                  ),
                                  if (m['joined_at'] != null)
                                    Text(
                                      'Joined ${_fmtDate(m['joined_at'])}',
                                      style: context.appTextTheme.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              m['role'] == 'founder' ? 'Founder' : 'Member',
                              style: context.appTextTheme.bodySmall
                                  ?.copyWith(color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  const SizedBox(height: 18),
                  if (!isMember)
                    BrkButton(
                      label: 'Join crew',
                      onPressed: () async {
                        try {
                          final state = context.read<AppState>();
                          final token = await state.auth.idToken();
                          if (token == null) return;
                          await state.api.joinCrew(token, crew['crew_id']);
                          _load();
                        } catch (e) {
                          if (mounted) {
                            showBrkToast(context, e.toString(),
                                icon: Icons.error_outline);
                          }
                        }
                      },
                    )
                  else if (widget.crew['role'] != 'founder')
                    BrkButton(
                      label: 'Leave crew',
                      variant: BrkButtonVariant.secondary,
                      onPressed: () async {
                        try {
                          final state = context.read<AppState>();
                          final token = await state.auth.idToken();
                          if (token == null) return;
                          await state.api.leaveCrew(token, crew['crew_id']);
                          if (mounted) Navigator.of(context).pop();
                        } catch (e) {
                          if (mounted) {
                            showBrkToast(context, e.toString(),
                                icon: Icons.error_outline);
                          }
                        }
                      },
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

class _FindCrewsTab extends StatefulWidget {
  const _FindCrewsTab();

  @override
  State<_FindCrewsTab> createState() => _FindCrewsTabState();
}

class _FindCrewsTabState extends State<_FindCrewsTab> {
  bool _loading = true;
  List<Map<String, dynamic>> _crews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final state = context.read<AppState>();
      final token = await state.auth.idToken();
      if (token == null) return;
      final res = await state.api.getCrews(token);
      if (mounted) {
        setState(() {
          _crews = (res['crews'] as List? ?? []).cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: BrkSpinner());
    if (_crews.isEmpty) {
      return const Center(
        child: BrkEmptyState(
          icon: Icons.search,
          title: 'No public crews',
          message: 'No crews to discover yet.',
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        for (final crew in _crews) ...[
          BrkCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _CrewDetailScreen(crew: crew)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.surfaceVariant,
                  backgroundImage: crew['photo_url'] != null
                      ? NetworkImage(crew['photo_url'])
                      : null,
                  child: crew['photo_url'] == null
                      ? const Icon(Icons.groups, color: AppColors.onSurfaceVariant)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crew['name'] ?? '',
                        style: context.appTextTheme.titleSmall
                            ?.copyWith(color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 4),
                              Text(
                                '${crew['member_count'] ?? 0} members • ${_fmtDate(crew['created_at'])}',
                                style: context.appTextTheme.bodySmall,
                              ),
                    ],
                  ),
                ),
                Text(
                  crew['joined'] == true ? 'Joined' : 'View',
                  style: context.appTextTheme.bodySmall
                      ?.copyWith(color: AppColors.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SocialTab extends StatelessWidget {
  const _SocialTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: BrkEmptyState(
        icon: Icons.diversity_3,
        title: 'Social Space',
        message: 'Find crews and connect with the community.',
      ),
    );
  }
}
