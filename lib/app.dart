import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/management/management_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/task/task_list_screen.dart';

class KuTaskApp extends StatelessWidget {
  const KuTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KU Task',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _screens = [
    HomeScreen(),
    TaskListScreen(),
    ManagementScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Icons.home_rounded),
            icon: Icon(Icons.home_outlined),
            label: '홈',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.format_list_bulleted_rounded),
            icon: Icon(Icons.format_list_bulleted_outlined),
            label: '목록',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.folder_rounded),
            icon: Icon(Icons.folder_outlined),
            label: '관리',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.settings_rounded),
            icon: Icon(Icons.settings_outlined),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
