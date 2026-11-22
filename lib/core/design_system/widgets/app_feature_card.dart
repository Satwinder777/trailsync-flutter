import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import 'app_card.dart';

class AppFeatureCard extends StatelessWidget {
  const AppFeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, color: AppColors.forest),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
