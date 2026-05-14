import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = EdgeInsets.zero,
    this.color = AppColors.card,
    this.borderColor = AppColors.border,
    this.borderWidth = 1,
    this.radius = 16,
    this.elevation = 1,
    this.useGradient = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final double radius;
  final double elevation;
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: useGradient ? null : color,
        gradient: useGradient ? AppColors.cardGradient : null,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.72),
          width: borderWidth,
        ),
        boxShadow: elevation <= 0
            ? const <BoxShadow>[]
            : <BoxShadow>[
                BoxShadow(
                  color: AppColors.primaryGlow.withValues(alpha: 0.10),
                  blurRadius: elevation * 20,
                  offset: Offset(0, elevation * 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.30),
                  blurRadius: elevation * 14,
                  offset: Offset(0, elevation * 6),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.035),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
