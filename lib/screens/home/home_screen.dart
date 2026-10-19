import 'package:flutter/material.dart';

import '../../components/index.dart';
import '../../theme/app_theme.dart';
import '../top_actions.dart';

/// Home feed. Not built yet.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const BrkHeader(title: 'Home', actions: [TopBarActions()]),
            const Expanded(
              child: BrkEmptyState(
                icon: Icons.home_outlined,
                title: 'Coming soon',
                message: 'Home is not built yet.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
