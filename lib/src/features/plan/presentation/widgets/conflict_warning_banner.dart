import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Reusable warning banner displaying scheduling conflict information.
class ConflictWarningBanner extends StatelessWidget {
  final String description;

  const ConflictWarningBanner({
    super.key,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.pausedAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.pausedAmber.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: AppColors.pausedAmber,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.pausedAmber,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
