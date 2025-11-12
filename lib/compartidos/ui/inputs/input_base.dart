import 'package:flutter/material.dart';

abstract class BaseInput extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final bool isRequired;
  final bool isEnabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final InputBorder? border;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;

  const BaseInput({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.isRequired = false,
    this.isEnabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.padding,
    this.labelStyle,
    this.hintStyle,
    this.border,
    this.focusedBorder,
    this.errorBorder,
  });

  Widget buildInput(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            RichText(
              text: TextSpan(
                text: label!,
                style: labelStyle ?? Theme.of(context).textTheme.bodyMedium,
                children: [
                  if (isRequired)
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          buildInput(context),
          if (errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration getDecoration(BuildContext context) {
    return InputDecoration(
      hintText: hint,
      hintStyle: hintStyle,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      enabled: isEnabled,
      border: border ?? _getDefaultBorder(context),
      focusedBorder: focusedBorder ?? _getDefaultFocusedBorder(context),
      errorBorder: errorBorder ?? _getDefaultErrorBorder(context),
      errorText: null, // Manejamos el error externamente
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  InputBorder _getDefaultBorder(BuildContext context) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }

  InputBorder _getDefaultFocusedBorder(BuildContext context) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary,
        width: 2,
      ),
    );
  }

  InputBorder _getDefaultErrorBorder(BuildContext context) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.error,
        width: 2,
      ),
    );
  }
}