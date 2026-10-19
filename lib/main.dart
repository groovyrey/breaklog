import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_root.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } on Exception {
    // A build without google-services fails here; the root then explains that
    // sign in is unavailable instead of showing an empty library.
  }
  runApp(const BreakLogApp());
}

class BreakLogApp extends StatelessWidget {
  const BreakLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const _Boot(),
    );
  }
}

/// Starts app state once, then hands the root to [AppRoot].
class _Boot extends StatefulWidget {
  const _Boot();

  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  @override
  void initState() {
    super.initState();
    context.read<AppState>().init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BreakLog',
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(),
      home: const AppRoot(),
    );
  }
}
