import 'package:flutter/material.dart';
import 'package:milo/core/theme/app_colors.dart';

/// Ombre néo-brutaliste décalée (hard shadow).
class NeoBrutalShadow extends StatelessWidget {
  const NeoBrutalShadow({
    super.key,
    required this.child,
    this.offset = const Offset(6, 6),
    this.color = AppColors.yellowVivid,
    this.borderRadius = 16,
    this.borderWidth = 3,
  });

  final Widget child;
  final Offset offset;
  final Color color;
  final double borderRadius;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: offset.dx,
          top: offset.dy,
          right: -offset.dx,
          bottom: -offset.dy,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: AppColors.border, width: borderWidth),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Conteneur néo-brutaliste avec bordure noire épaisse.
class NeoBrutalContainer extends StatelessWidget {
  const NeoBrutalContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.backgroundColor = AppColors.cream,
    this.borderRadius = 16,
    this.withShadow = true,
    this.shadowColor = AppColors.yellowVivid,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color backgroundColor;
  final double borderRadius;
  final bool withShadow;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border, width: 3),
      ),
      child: child,
    );

    if (!withShadow) return container;

    return NeoBrutalShadow(
      color: shadowColor,
      borderRadius: borderRadius,
      child: container,
    );
  }
}
