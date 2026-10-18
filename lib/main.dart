import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/shell.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BreakLogApp());
}

class BreakLogApp extends StatelessWidget {
  const BreakLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: MaterialApp(
        title: 'BreakLog',
        debugShowCheckedModeBanner: false,
        theme: buildDarkTheme(),
        home: const AppShell(),
      ),
    );
  }
}
