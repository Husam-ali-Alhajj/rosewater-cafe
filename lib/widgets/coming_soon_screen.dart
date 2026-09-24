import 'package:flutter/material.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';

/// Shared placeholder for a destination that isn't built yet, so in-progress
/// flows stay testable end-to-end without a bespoke stub per screen.
class ComingSoonScreen extends StatelessWidget {
  final String label;

  const ComingSoonScreen({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.pageBackgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$label — coming in a future task',
                    style: AppTextStyles.bodyMuted(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
