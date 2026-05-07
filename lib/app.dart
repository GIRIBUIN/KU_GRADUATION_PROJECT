import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/debug/ecampus_login_debug_screen.dart';

class KuTaskApp extends StatelessWidget {
  const KuTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KU Todo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const EcampusLoginDebugScreen(),
    );
  }
}
