import 'package:flutter/material.dart';

import '../../../../core/design_system/widgets/feature_placeholder_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Settings',
      icon: Icons.settings_outlined,
      message: 'Preferences and privacy controls are not wired yet.',
    );
  }
}
