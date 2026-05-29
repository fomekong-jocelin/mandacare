import 'package:flutter/material.dart';

import '../../../../shared/presentation/widgets/compact_form_field.dart';

class ConsultationTextField extends StatelessWidget {
  const ConsultationTextField({
    required super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.minLines = 1,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final int minLines;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return CompactTextFormField(
      controller: controller,
      label: label,
      hintText: hintText,
      icon: icon,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction: TextInputAction.newline,
      textCapitalization: TextCapitalization.sentences,
      validator: validator,
    );
  }
}
