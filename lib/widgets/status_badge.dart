import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/models/order.dart';
import '../data/models/product.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  factory StatusBadge.stock(ProductResponse product) {
    switch (product.stockLevel) {
      case StockLevel.out:
        return const StatusBadge(
          label: 'Out of stock',
          foreground: AppColors.danger,
          background: AppColors.dangerBg,
        );
      case StockLevel.low:
        return const StatusBadge(
          label: 'Low stock',
          foreground: AppColors.warning,
          background: AppColors.warningBg,
        );
      case StockLevel.inStock:
        return const StatusBadge(
          label: 'In stock',
          foreground: AppColors.success,
          background: AppColors.successBg,
        );
    }
  }

  factory StatusBadge.active(bool active) => active
      ? const StatusBadge(
          label: 'Active',
          foreground: AppColors.info,
          background: AppColors.infoBg,
        )
      : const StatusBadge(
          label: 'Inactive',
          foreground: AppColors.neutral,
          background: AppColors.neutralBg,
        );

  factory StatusBadge.order(String status) {
    switch (status) {
      case OrderStatus.completed:
        return const StatusBadge(
          label: 'Completed',
          foreground: AppColors.success,
          background: AppColors.successBg,
        );
      case OrderStatus.cancelled:
        return const StatusBadge(
          label: 'Cancelled',
          foreground: AppColors.danger,
          background: AppColors.dangerBg,
        );
      case OrderStatus.pending:
        return const StatusBadge(
          label: 'Pending',
          foreground: AppColors.warning,
          background: AppColors.warningBg,
        );
      default:
        return StatusBadge(
          label: status,
          foreground: AppColors.neutral,
          background: AppColors.neutralBg,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: foreground),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
