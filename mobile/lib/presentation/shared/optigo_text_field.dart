import 'package:flutter/material.dart';
import '../../app/theme.dart';

class OptigoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final FocusNode? focusNode;

  const OptigoTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: OptigoTheme.textPrimary,
          ),
        ),
        const SizedBox(height: OptigoTheme.spacingXS + 2),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          focusNode: focusNode,
          style: const TextStyle(
            fontSize: 15,
            color: OptigoTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: OptigoTheme.textSecondary, size: 20)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: OptigoTheme.spacingMD,
              vertical: OptigoTheme.spacingMD,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
              borderSide: const BorderSide(color: OptigoTheme.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
              borderSide: const BorderSide(color: OptigoTheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
              borderSide: const BorderSide(color: OptigoTheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
              borderSide: const BorderSide(color: OptigoTheme.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
