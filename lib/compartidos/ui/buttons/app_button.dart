import 'package:flutter/material.dart';
import 'button_base.dart';

class AppButton extends BaseButton {
  const AppButton({
    super.key,
    super.text,
    super.child,
    super.onPressed,
    super.variant = ButtonVariant.primary,
    super.size = ButtonSize.medium,
    super.isLoading = false,
    super.isExpanded = false,
    super.padding,
    super.icon,
    super.iconAtEnd = false,
  });

  @override
  Widget buildButton(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: getButtonStyle(context),
      child: buildButtonContent(context),
    );
  }
}

class AppOutlineButton extends BaseButton {
  const AppOutlineButton({
    super.key,
    super.text,
    super.child,
    super.onPressed,
    super.size = ButtonSize.medium,
    super.isLoading = false,
    super.isExpanded = false,
    super.padding,
    super.icon,
    super.iconAtEnd = false,
  }) : super(variant: ButtonVariant.outline);

  @override
  Widget buildButton(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: getButtonStyle(context),
      child: buildButtonContent(context),
    );
  }
}

class AppTextButton extends BaseButton {
  const AppTextButton({
    super.key,
    super.text,
    super.child,
    super.onPressed,
    super.size = ButtonSize.medium,
    super.isLoading = false,
    super.isExpanded = false,
    super.padding,
    super.icon,
    super.iconAtEnd = false,
  }) : super(variant: ButtonVariant.text);

  @override
  Widget buildButton(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: getButtonStyle(context),
      child: buildButtonContent(context),
    );
  }
}

class AppIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final ButtonSize size;
  final ButtonVariant variant;
  final bool isLoading;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = ButtonSize.medium,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              height: _getIconSize(),
              width: _getIconSize(),
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : icon,
      iconSize: _getIconSize(),
      style: _getIconButtonStyle(context),
      tooltip: tooltip,
    );

    return button;
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  ButtonStyle _getIconButtonStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.transparent;
        }
        if (variant == ButtonVariant.primary) {
          if (states.contains(WidgetState.hovered)) {
            return colorScheme.primary.withValues(alpha: 0.1);
          }
        }
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.38);
        }
        switch (variant) {
          case ButtonVariant.primary:
            return colorScheme.primary;
          case ButtonVariant.secondary:
            return colorScheme.secondary;
          case ButtonVariant.danger:
            return colorScheme.error;
          default:
            return colorScheme.onSurface;
        }
      }),
    );
  }
}