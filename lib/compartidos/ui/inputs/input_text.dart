import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'input_base.dart';

class InputText extends BaseInput {
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool readOnly;

  const InputText({
    super.key,
    super.label,
    super.hint,
    super.errorText,
    super.isRequired,
    super.isEnabled,
    super.prefixIcon,
    super.suffixIcon,
    super.onTap,
    super.padding,
    super.labelStyle,
    super.hintStyle,
    super.border,
    super.focusedBorder,
    super.errorBorder,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.readOnly = false,
  });

  @override
  Widget buildInput(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      onTap: onTap,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: minLines,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
      autofocus: autofocus,
      readOnly: readOnly,
      enabled: isEnabled,
      decoration: getDecoration(context),
    );
  }
}

class InputEmail extends InputText {
  const InputEmail({
    super.key,
    super.label = 'Correo electrónico',
    super.hint = 'ejemplo@correo.com',
    super.errorText,
    super.isRequired = true,
    super.isEnabled,
    super.prefixIcon = const Icon(Icons.email_outlined),
    super.suffixIcon,
    super.onTap,
    super.padding,
    super.labelStyle,
    super.hintStyle,
    super.border,
    super.focusedBorder,
    super.errorBorder,
    super.controller,
    super.initialValue,
    super.onChanged,
    super.onSubmitted,
    super.onEditingComplete,
    super.textInputAction,
    super.maxLength,
    super.inputFormatters,
    super.focusNode,
    super.autofocus,
    super.readOnly,
  }) : super(
         keyboardType: TextInputType.emailAddress,
       );
}

class InputPassword extends InputText {
  final bool showPassword;
  final VoidCallback? onTogglePassword;

  const InputPassword({
    super.key,
    super.label = 'Contraseña',
    super.hint = 'Ingresa tu contraseña',
    super.errorText,
    super.isRequired = true,
    super.isEnabled,
    super.prefixIcon = const Icon(Icons.lock_outline),
    super.onTap,
    super.padding,
    super.labelStyle,
    super.hintStyle,
    super.border,
    super.focusedBorder,
    super.errorBorder,
    super.controller,
    super.initialValue,
    super.onChanged,
    super.onSubmitted,
    super.onEditingComplete,
    super.textInputAction,
    super.maxLength,
    super.inputFormatters,
    super.focusNode,
    super.autofocus,
    super.readOnly,
    this.showPassword = false,
    this.onTogglePassword,
  }) : super(
         keyboardType: TextInputType.visiblePassword,
         obscureText: !showPassword,
       );

  @override
  Widget buildInput(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      onTap: onTap,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: !showPassword,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: minLines,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
      autofocus: autofocus,
      readOnly: readOnly,
      enabled: isEnabled,
      decoration: getDecoration(context).copyWith(
        suffixIcon: onTogglePassword != null
            ? IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: onTogglePassword,
              )
            : suffixIcon,
      ),
    );
  }
}