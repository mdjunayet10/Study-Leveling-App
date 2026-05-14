import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = AppColors.primary,
    this.hoverColor = AppColors.primaryLight,
    this.foregroundColor = AppColors.textPrimary,
    this.leading,
    this.isExpanded = false,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
  });

  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color hoverColor;
  final Color foregroundColor;
  final Widget? leading;
  final bool isExpanded;
  final TextStyle? textStyle;
  final EdgeInsets padding;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    Widget label = Text(
      widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (widget.textStyle ?? AppTextStyles.body).copyWith(
        color: widget.foregroundColor,
        fontSize: widget.textStyle?.fontSize ?? 14.5,
        fontWeight: FontWeight.w800,
        height: 1.15,
      ),
    );

    if (widget.isExpanded) {
      label = Flexible(
        child: FittedBox(fit: BoxFit.scaleDown, child: label),
      );
    }

    final bool disabled = widget.onPressed == null;
    final bool usesDefaultGradient =
        widget.backgroundColor == AppColors.primary &&
        widget.hoverColor == AppColors.primaryLight;
    final Color activeColor = _hovered
        ? widget.hoverColor
        : widget.backgroundColor;

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onPressed,
        onHover: (value) => setState(() => _hovered = value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: disabled
                ? AppColors.cardElevated.withValues(alpha: 0.65)
                : usesDefaultGradient
                ? null
                : activeColor.withValues(alpha: _hovered ? 0.95 : 0.88),
            gradient: disabled
                ? null
                : usesDefaultGradient
                ? (_hovered
                      ? AppColors.actionGradient
                      : AppColors.primaryGradient)
                : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: disabled
                  ? AppColors.divider
                  : (_hovered ? AppColors.accentBright : activeColor),
              width: 1,
            ),
            boxShadow: disabled
                ? const <BoxShadow>[]
                : <BoxShadow>[
                    BoxShadow(
                      color: (_hovered ? widget.hoverColor : activeColor)
                          .withValues(alpha: _hovered ? 0.24 : 0.16),
                      blurRadius: _hovered ? 24 : 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: widget.isExpanded
                ? MainAxisSize.max
                : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (widget.leading != null) ...<Widget>[
                IconTheme(
                  data: IconThemeData(color: widget.foregroundColor),
                  child: widget.leading!,
                ),
                const SizedBox(width: 8),
              ],
              label,
            ],
          ),
        ),
      ),
    );

    if (widget.isExpanded) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
