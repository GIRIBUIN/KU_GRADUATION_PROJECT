import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

class KuTaskApp extends StatelessWidget {
  const KuTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KU Task',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const BackendPlaceholderScreen(),
    );
  }
}

class BackendPlaceholderScreen extends StatelessWidget {
  const BackendPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KU Task')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.task_alt_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                '백엔드 기능 구현 중',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '기존 목업 UI는 실제 데이터 모델 연결 전까지 빌드 대상에서 제외합니다.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
