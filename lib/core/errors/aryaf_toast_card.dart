import 'package:flutter/material.dart';

class AryafToastCard extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final dynamic color;
  final Color? shadowColor;
  final Function()? onTap;
  final bool showCloseButton;
  final VoidCallback? onClose;
  const AryafToastCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.color,
    this.shadowColor,
    this.trailing,
    this.onTap,
    this.showCloseButton = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 900;
    final horizontalMargin = isDesktop ? 24.0 : 16.0;
    final maxWidth = isDesktop ? 460.0 : screenWidth - (horizontalMargin * 2);
    final effectiveTrailing =
        trailing ??
        (showCloseButton
            ? IconButton(
              splashRadius: 18,
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
              onPressed: onClose,
              tooltip: 'Close',
            )
            : null);

    return Container(
      margin: EdgeInsets.fromLTRB(horizontalMargin, 10, horizontalMargin, 0),
      decoration: BoxDecoration(
        color: color is Color ? color : null,
        gradient: color is Gradient ? color : null,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            blurRadius: isDesktop ? 26 : 14,
            spreadRadius: 0,
            offset: const Offset(0, 8),
            color: shadowColor ?? Colors.black.withValues(alpha: 0.15),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          minHeight: isDesktop ? 86 : 72,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 14),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 16 : 12,
                vertical: isDesktop ? 14 : 10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null)
                    Container(
                      width: isDesktop ? 40 : 36,
                      height: isDesktop ? 40 : 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Center(child: leading),
                    ),
                  if (leading != null) const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        title,
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          subtitle!,
                        ],
                      ],
                    ),
                  ),
                  if (effectiveTrailing != null) ...[
                    const SizedBox(width: 8),
                    effectiveTrailing,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
