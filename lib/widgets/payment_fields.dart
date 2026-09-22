import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Digits-only MM/YY formatter -- inserts the "/" automatically so typing
/// stays natural, matching the design's placeholder. Shared by the Payment
/// screen and Add Payment Method (moved here unchanged from Payment).
class ExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '').substring(0, newValue.text.replaceAll(RegExp(r'\D'), '').length.clamp(0, 4));
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if (i == 1 && digits.length > 2) buffer.write('/');
    }
    final text = buffer.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// A labelled card field (Card Number / Expiry Date / CVV) styled like the
/// Complete Payment screen's inputs (Figma node 1213:1281). Shared by the
/// Payment screen and Add Payment Method (moved here unchanged from Payment).
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.15, color: Color(0xFF0A0A0A)),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          validator: validator,
          // Deliberately no autofillHints: there is no real payment processor
          // behind these forms -- letting the OS/browser offer to save a real
          // card here would be actively misleading.
          autofillHints: null,
          enableSuggestions: false,
          autocorrect: false,
          style: const TextStyle(fontSize: 16, color: Color(0xFF717182), letterSpacing: -0.31),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF3F3F5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
            ),
            errorStyle: TextStyle(color: AppColors.danger, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
