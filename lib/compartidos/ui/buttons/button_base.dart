import 'package:flutter/material.dart';

enum ButtonVariant {
  primary,
  secondary,
  outline,
  text,
  danger,
}

enum ButtonSize {
  small,
  medium,
  large,
}

abstract class BaseButton extends StatelessWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool isExpanded;
  final EdgeInsetsGeometry? padding;
  final Widget? icon;
  final bool iconAtEnd;

  const BaseButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isExpanded = false,
    this.padding,
    this.icon,
    this.iconAtEnd = false,
  }) : assert(text != null || child != null, 'Either text or child must be provided');

  Widget buildButton(BuildContext context);

  @override
  Widget build(BuildContext context) {
    Widget button = buildButton(context);

    if (isExpanded) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  ButtonStyle getButtonStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ButtonStyle(
      padding: WidgetStateProperty.all(getButtonPadding()),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.12);
        }
        return getBackgroundColor(context, states);
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.38);
        }
        return getForegroundColor(context, states);
      }),
      side: WidgetStateProperty.resolveWith((states) {
        return getBorderSide(context, states);
      }),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (variant == ButtonVariant.outline || variant == ButtonVariant.text) {
          return 0;
        }
        if (states.contains(WidgetState.pressed)) {
          return 2;
        }
        return 1;
      }),
    );
  }

  EdgeInsetsGeometry getButtonPadding() {
    if (padding != null) return padding!;

    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  double getButtonHeight() {
    switch (size) {
      case ButtonSize.small:
        return 32;
      case ButtonSize.medium:
        return 40;
      case ButtonSize.large:
        return 48;
    }
  }

  TextStyle getTextStyle(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    switch (size) {
      case ButtonSize.small:
        return textTheme.bodySmall!;
      case ButtonSize.medium:
        return textTheme.bodyMedium!;
      case ButtonSize.large:
        return textTheme.bodyLarge!;
    }
  }

  Color getBackgroundColor(BuildContext context, Set<WidgetState> states) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (variant) {
      case ButtonVariant.primary:
        if (states.contains(WidgetState.hovered)) {
          return colorScheme.primary.withValues(alpha: 0.9);
        }
        return colorScheme.primary;
      case ButtonVariant.secondary:
        if (states.contains(WidgetState.hovered)) {
          return colorScheme.secondary.withValues(alpha: 0.9);
        }
        return colorScheme.secondary;
      case ButtonVariant.outline:
      case ButtonVariant.text:
        if (states.contains(WidgetState.hovered)) {
          return colorScheme.primary.withValues(alpha: 0.1);
        }
        return Colors.transparent;
      case ButtonVariant.danger:
        if (states.contains(WidgetState.hovered)) {
          return colorScheme.error.withValues(alpha: 0.9);
        }
        return colorScheme.error;
    }
  }

  Color getForegroundColor(BuildContext context, Set<WidgetState> states) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (variant) {
      case ButtonVariant.primary:
        return colorScheme.onPrimary;
      case ButtonVariant.secondary:
        return colorScheme.onSecondary;
      case ButtonVariant.outline:
      case ButtonVariant.text:
        return colorScheme.primary;
      case ButtonVariant.danger:
        return colorScheme.onError;
    }
  }

  BorderSide? getBorderSide(BuildContext context, Set<WidgetState> states) {
    final colorScheme = Theme.of(context).colorScheme;

    if (variant == ButtonVariant.outline) {
      return BorderSide(
        color: states.contains(WidgetState.disabled)
            ? colorScheme.onSurface.withValues(alpha: 0.12)
            : colorScheme.primary,
        width: 1,
      );
    }
    return null;
  }

  Widget buildButtonContent(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            getForegroundColor(context, {}),
          ),
        ),
      );
    }

    final content = child ?? Text(text!);

    if (icon == null) {
      return content;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: iconAtEnd
          ? [content, const SizedBox(width: 8), icon!]
          : [icon!, const SizedBox(width: 8), content],
    );
  }
}