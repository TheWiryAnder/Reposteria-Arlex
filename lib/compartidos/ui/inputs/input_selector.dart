import 'package:flutter/material.dart';
import 'input_base.dart';

class InputSelector<T> extends BaseInput {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isDense;
  final bool isExpanded;

  const InputSelector({
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
    this.value,
    required this.items,
    this.onChanged,
    this.isDense = false,
    this.isExpanded = true,
  });

  @override
  Widget buildInput(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: isEnabled ? onChanged : null,
      decoration: getDecoration(context),
      isDense: isDense,
      isExpanded: isExpanded,
      onTap: onTap,
    );
  }
}

class InputDate extends BaseInput {
  final DateTime? value;
  final ValueChanged<DateTime?>? onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final TextEditingController? controller;

  const InputDate({
    super.key,
    super.label,
    super.hint,
    super.errorText,
    super.isRequired,
    super.isEnabled,
    super.prefixIcon = const Icon(Icons.calendar_today),
    super.suffixIcon,
    super.padding,
    super.labelStyle,
    super.hintStyle,
    super.border,
    super.focusedBorder,
    super.errorBorder,
    this.value,
    this.onChanged,
    this.firstDate,
    this.lastDate,
    this.controller,
  });

  @override
  Widget buildInput(BuildContext context) {
    final textController = controller ?? TextEditingController();

    if (value != null) {
      textController.text = _formatDate(value!);
    }

    return TextFormField(
      controller: textController,
      readOnly: true,
      enabled: isEnabled,
      decoration: getDecoration(context),
      onTap: isEnabled ? () => _selectDate(context) : null,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2101),
    );

    if (picked != null && picked != value) {
      onChanged?.call(picked);
    }
  }
}

class InputTime extends BaseInput {
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?>? onChanged;
  final TextEditingController? controller;

  const InputTime({
    super.key,
    super.label,
    super.hint,
    super.errorText,
    super.isRequired,
    super.isEnabled,
    super.prefixIcon = const Icon(Icons.access_time),
    super.suffixIcon,
    super.padding,
    super.labelStyle,
    super.hintStyle,
    super.border,
    super.focusedBorder,
    super.errorBorder,
    this.value,
    this.onChanged,
    this.controller,
  });

  @override
  Widget buildInput(BuildContext context) {
    final textController = controller ?? TextEditingController();

    if (value != null) {
      textController.text = value!.format(context);
    }

    return TextFormField(
      controller: textController,
      readOnly: true,
      enabled: isEnabled,
      decoration: getDecoration(context),
      onTap: isEnabled ? () => _selectTime(context) : null,
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: value ?? TimeOfDay.now(),
    );

    if (picked != null && picked != value) {
      onChanged?.call(picked);
    }
  }
}