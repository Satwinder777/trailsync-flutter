import 'package:flutter/material.dart';

import 'app_empty_state.dart';
import 'app_page_scaffold.dart';

class FeaturePlaceholderPage extends StatelessWidget {
  const FeaturePlaceholderPage({
    required this.title,
    required this.icon,
    required this.message,
    super.key,
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: title,
      body: AppEmptyState(
        icon: icon,
        title: '$title module scaffolded',
        message: message,
      ),
    );
  }
}
