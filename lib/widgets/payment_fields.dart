import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_semantic_colors.dart';

/// MM/YY input: adds the "/" automatically. Used by the payment and add-card screens.
class ExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text
        .replaceAll(RegExp(r'\D'), '')
        .substring(0, newValue.text.replaceAll(RegExp(r'\D'), '').length.clamp(0, 4));
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if (i == 1 && digits.length > 2) buffer.write('/');
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// A labelled card field (card number, expiry, CVV). Used by the payment and add-card screens.
class PaymentField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final String? Function(String?) validator;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool enabled;

  const PaymentField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    required this.validator,
    required this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.15, color: colors.textPrimary),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          validator: validator,
          // No autofill hints on purpose: there's no real payment processor, so the browser
          // shouldn't offer to save a real card here.
          autofillHints: null,
          enableSuggestions: false,
          autocorrect: false,
          style: TextStyle(fontSize: 16, color: colors.textMuted, letterSpacing: -0.31),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: colors.inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
            errorStyle: TextStyle(color: colors.danger, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
