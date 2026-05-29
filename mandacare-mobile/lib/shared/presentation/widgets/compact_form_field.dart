import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class CompactTextFormField extends StatelessWidget {
  const CompactTextFormField({
    required this.controller,
    required this.label,
    this.icon,
    this.hintText,
    this.helperText,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.minLines,
    this.maxLines = 1,
    this.validator,
    this.suffixIcon,
    this.autofillHints,
    this.onFieldSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? hintText;
  final String? helperText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final int? minLines;
  final int maxLines;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final effectiveMinLines = minLines ?? (maxLines > 1 ? 2 : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompactFieldLabel(label: label),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          minLines: effectiveMinLines,
          maxLines: maxLines,
          validator: validator,
          autofillHints: autofillHints,
          onFieldSubmitted: onFieldSubmitted,
          style: _inputTextStyle(context),
          decoration: compactInputDecoration(
            context,
            hintText: hintText,
            helperText: helperText,
            prefixIcon: icon != null ? Icon(icon, size: 19) : null,
            suffixIcon: suffixIcon,
            multiline: maxLines > 1 || effectiveMinLines > 1,
          ),
        ),
      ],
    );
  }
}

class CompactDropdownField extends StatelessWidget {
  const CompactDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
    super.key,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompactFieldLabel(label: label),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: onChanged,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          style: _inputTextStyle(context),
          decoration: compactInputDecoration(
            context,
            prefixIcon: icon != null ? Icon(icon, size: 19) : null,
          ),
          dropdownColor: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          items: [
            for (final item in items)
              DropdownMenuItem<String>(value: item, child: Text(item)),
          ],
        ),
      ],
    );
  }
}

class CompactFieldLabel extends StatelessWidget {
  const CompactFieldLabel({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.deepHealthBlue.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.1,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration compactInputDecoration(
  BuildContext context, {
  String? hintText,
  String? helperText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  bool multiline = false,
}) {
  return InputDecoration(
    hintText: hintText,
    helperText: helperText,
    helperMaxLines: 1,
    isDense: true,
    filled: true,
    fillColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        return Colors.white;
      }
      if (states.contains(WidgetState.disabled)) {
        return AppColors.lightBackground.withValues(alpha: 0.3);
      }
      return AppColors.lightBackground.withValues(alpha: 0.55);
    }),
    contentPadding: EdgeInsets.symmetric(
      horizontal: 14,
      vertical: multiline ? 12 : 10,
    ),
    constraints: BoxConstraints(minHeight: multiline ? 0 : 48),
    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary.withValues(alpha: 0.60),
      fontSize: 13.5,
      height: 1.2,
    ),
    helperStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary.withValues(alpha: 0.75),
      fontSize: 11,
      height: 1.12,
    ),
    errorStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.error,
      fontSize: 11,
      height: 1.12,
    ),
    prefixIcon: prefixIcon != null
        ? Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: prefixIcon,
          )
        : null,
    prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
    prefixIconColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        return AppColors.medicalGreen;
      }
      if (states.contains(WidgetState.error)) {
        return AppColors.error;
      }
      return AppColors.textSecondary.withValues(alpha: 0.70);
    }),
    suffixIcon: suffixIcon,
    suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    suffixIconColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        return AppColors.medicalGreen;
      }
      if (states.contains(WidgetState.error)) {
        return AppColors.error;
      }
      return AppColors.textSecondary.withValues(alpha: 0.70);
    }),
    border: _compactBorder(AppColors.border.withValues(alpha: 0.60)),
    enabledBorder: _compactBorder(AppColors.border.withValues(alpha: 0.60)),
    focusedBorder: _compactBorder(AppColors.medicalGreen, width: 1.5),
    errorBorder: _compactBorder(AppColors.error.withValues(alpha: 0.70)),
    focusedErrorBorder: _compactBorder(AppColors.error, width: 1.5),
  );
}

TextStyle? _inputTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyLarge?.copyWith(
    color: AppColors.textPrimary,
    fontSize: 15,
    height: 1.18,
  );
}

OutlineInputBorder _compactBorder(Color color, {double width = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: color, width: width),
  );
}
