import 'package:flutter/material.dart';

import '../../components/index.dart';
import '../../theme/app_theme.dart';
import '../top_actions.dart';

/// Book. Not built yet.
class BookScreen extends StatelessWidget {
  const BookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const BrkHeader(
              title: 'Book',
              mark: BrkBrandMark(),
              actions: [TopBarActions()],
            ),
            const Expanded(
              child: BrkEmptyState(
                icon: Icons.menu_book_outlined,
                title: 'Coming soon',
                message: 'Book is not built yet.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
