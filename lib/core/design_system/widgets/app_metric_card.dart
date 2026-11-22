import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import 'app_card.dart';

class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.detail,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? detail;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.forest),
        const SizedBox(height: AppSpacing.md),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        if (detail != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(detail!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    ),
  );
}
