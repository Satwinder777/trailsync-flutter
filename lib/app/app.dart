import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';

class TrailSyncApp extends StatelessWidget {
  const TrailSyncApp({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TrailSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      onGenerateTitle: (_) => 'TrailSync',
    );
  }
}
