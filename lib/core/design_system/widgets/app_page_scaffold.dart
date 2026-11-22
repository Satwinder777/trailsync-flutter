import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';

class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    required this.title,
    required this.body,
    this.actions,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        toolbarHeight: 68,
        title: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const SizedBox(
                width: 34,
                height: 34,
                child: Icon(
                  Icons.route_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(title),
          ],
        ),
        actions: actions,
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}
