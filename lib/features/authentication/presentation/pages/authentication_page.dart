import 'package:flutter/material.dart';

import '../../../../core/design_system/widgets/feature_placeholder_page.dart';

class AuthenticationPage extends StatelessWidget {
  const AuthenticationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Authentication',
      icon: Icons.person_outline,
      message: 'Account access and profile flows will be added in this module.',
    );
  }
}
