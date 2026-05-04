import 'package:flutter/material.dart';

class ManagementScreen extends StatelessWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관리')),
      body: const Center(child: Text('관리')),
    );
  }
}
