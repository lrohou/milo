import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/shared/widgets/neo_brutal_container.dart';

/// Bouton d'action néo-brutaliste avec retour haptique.
class NeoBrutalButton extends StatelessWidget {
  const NeoBrutalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor = AppColors.yellowVivid,
    this.foregroundColor = AppColors.backgroundDeep,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = NeoBrutalContainer(
      backgroundColor: onPressed == null
          ? backgroundColor.withValues(alpha: 0.4)
          : backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      shadowColor: AppColors.yellowGold,
      child: InkWell(
        onTap: onPressed == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onPressed!();
              },
        child: Row(
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: foregroundColor, size: 22),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foregroundColor,
                  ),
            ),
          ],
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
