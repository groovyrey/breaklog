import '../shell.dart';
import 'package:flutter/material.dart';

import '../../components/index.dart';
import '../../theme/app_theme.dart';
import '../top_actions.dart';
import 'all_tab.dart';
import 'today_tab.dart';

/// Home: Today's journal and every note, with one search field shared by both
/// tabs. The add action lives in the shell's floating bar and writes a note
/// from here.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Builder(
                builder: (ctx) => BrkHeader(
                  title: 'Home',
                  mark: const BrkBrandMark(),
                  onMenu: () {
                    final state = ctx.findAncestorStateOfType<AppShellState>();
                    state?.openDrawer(ctx);
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
                    Tab(text: 'Today'),
                    Tab(text: 'All'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: BrkField(
                  controller: _search,
                  hint: 'Search notes',
                  suffix: _search.text.isEmpty
                      ? const Icon(Icons.search,
                          size: 18, color: AppColors.onSurfaceVariant)
                      : BrkIconButton(
                          icon: Icons.close,
                          size: 34,
                          onTap: () {
                            _search.clear();
                            setState(() {});
                          },
                        ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    TodayTab(query: _search.text),
                    AllTab(query: _search.text),
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
