import 'package:flutter/material.dart';

import '../../models/payment_method.dart';
import '../../services/payment_method_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_semantic_colors.dart';
import '../../widgets/screen_header.dart';
import 'add_payment_method_screen.dart';

// Exact values read from the Figma `PaymentMethodsScreen` frame (node
// 1217:2477) via the REST API -- same method as decisions #20/#40/#41/#42.
// Sprint 8 Task 2 (dark mode rebuild): the neutral greys are now sourced
// from `context.colors`; the green "Default"/set-default and red delete inks
// map onto the semantic success/danger tokens, which invert correctly.

const _hairline = 0.515; // Figma's fractional hairline stroke width

/// Payment Methods (Figma frame "PaymentMethodsScreen", node 1217:2477):
/// the user's saved cards -- brand, masked number, expiry, a green "Default"
/// badge -- with "Add New Payment Method", and on each card a delete button
/// (and, on non-default cards, a set-as-default button).
///
/// Everything shown is a real `payment_methods` row, metadata only (no full
/// number or CVV exists to show). The "one default per user" rule is enforced
/// in the database, not here: this screen just asks for "make this default" or
/// "delete this" and reloads the list, so what it shows is always what the
/// server ended up with -- never a client-side reordering.
///
/// **Not in the design, added for a real list:** an empty state, a load-failure
/// state with retry, a confirm dialog before deleting, and SnackBars for
/// failures.
class PaymentMethodsScreen extends StatefulWidget {
  final PaymentMethodService service;

  const PaymentMethodsScreen({super.key, this.service = const PaymentMethodService()});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool _loading = true;
  bool _loadFailed = false;
  List<PaymentMethod> _methods = const [];

  /// The card an action is currently running on; all actions are disabled
  /// meanwhile so two can't interleave.
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final methods = await widget.service.list();
      if (!mounted) return;
      setState(() {
        _methods = methods;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _add() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddPaymentMethodScreen(isFirstCard: _methods.isEmpty)),
    );
    if (added == true && mounted) await _load();
  }

  Future<void> _setDefault(PaymentMethod method) async {
    if (_busyId != null) return;
    setState(() => _busyId = method.id);
    try {
      await widget.service.setDefault(method.id);
    } on PaymentMethodFailure catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (_) {
      if (mounted) _showMessage('Something went wrong. Please try again.');
    }
    if (!mounted) return;
    setState(() => _busyId = null);
    await _load(); // show exactly what the server ended up with
  }

  Future<void> _delete(PaymentMethod method) async {
    if (_busyId != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove this card?'),
        content: Text('${method.brand} ending in ${method.last4} will be removed from your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Remove', style: TextStyle(color: ctx.colors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyId = method.id);
    try {
      await widget.service.delete(method.id);
    } on PaymentMethodFailure catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (_) {
      if (mounted) _showMessage('Something went wrong. Please try again.');
    }
    if (!mounted) return;
    setState(() => _busyId = null);
    await _load(); // the database promotes another card if this was the default
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.pageBackgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            // Figma's frame padding: 16 sides, 32 top; 32 below the list.
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(title: 'Payment Methods', onBack: () => Navigator.of(context).pop()),
                const SizedBox(height: 24),
                _AddButton(onTap: _busyId == null ? _add : null),
                const SizedBox(height: 24),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_loadFailed)
                  _MessageCard(
                    message: "Couldn't load your payment methods.",
                    actionLabel: 'Try again',
                    onAction: _load,
                  )
                else if (_methods.isEmpty)
                  const _MessageCard(message: "You haven't added a payment method yet.")
                else
                  for (var i = 0; i < _methods.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    _PaymentMethodCard(
                      method: _methods[i],
                      enabled: _busyId == null,
                      onSetDefault: () => _setDefault(_methods[i]),
                      onDelete: () => _delete(_methods[i]),
                    ),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Add New Payment Method" (Figma node 1217:2486): 48 tall, radius 8, the
/// primary gradient, a 16px plus icon 15px before the label, centred.
class _AddButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Container(
        height: 48,
        decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 16, color: Colors.white),
                SizedBox(width: 15),
                Text(
                  'Add New Payment Method',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 20 / 14,
                    letterSpacing: -0.15,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One saved card (Figma nodes 1217:2492 / 1217:2514): a 56px gradient tile
/// with a card emoji, the brand (+ a green "Default" badge), the masked
/// number and the expiry; a delete button at the right, plus a set-as-default
/// button on non-default cards.
class _PaymentMethodCard extends StatelessWidget {
  final PaymentMethod method;
  final bool enabled;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const _PaymentMethodCard({
    required this.method,
    required this.enabled,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border, width: _hairline),
      ),
      child: SizedBox(
        height: 76,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 56px tile, vertically centred in the 76px content. Uses
                  // the theme's own surface tones (rather than the design's
                  // fixed light-grey pair) so it doesn't go flat/invisible
                  // against a dark card.
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [colors.inputFill, colors.surfaceElevated],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Text('💳', style: TextStyle(fontSize: 24, height: 32 / 24)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _CardDetails(method: method)),
                ],
              ),
            ),
            const SizedBox(width: 3),
            if (!method.isDefault) ...[
              _IconAction(
                icon: Icons.check_circle_outline,
                color: colors.success,
                tooltip: 'Set as default',
                onTap: enabled ? onSetDefault : null,
              ),
              const SizedBox(width: 8),
            ],
            _IconAction(
              icon: Icons.delete_outline,
              color: colors.danger,
              tooltip: 'Delete',
              onTap: enabled ? onDelete : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardDetails extends StatelessWidget {
  final PaymentMethod method;

  const _CardDetails({required this.method});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // The design's column is 76 tall on a non-default card; on the default
    // card the extra 4px gap before "Expires" pushes it to 80, spilling into
    // the card's bottom padding. Reproduced: the box stays 76 and the text
    // overflows visibly rather than growing the card.
    return SizedBox(
      height: 76,
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minHeight: 0,
        maxHeight: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 28,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      method.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        height: 28 / 18,
                        letterSpacing: -0.44,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  if (method.isDefault) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Default',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 16 / 12,
                          color: colors.success,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              method.maskedNumber,
              style: TextStyle(fontSize: 16, height: 24 / 16, letterSpacing: -0.31, color: colors.textMuted),
            ),
            SizedBox(height: method.isDefault ? 4 : 0),
            Text(
              method.expiryLabel,
              style: TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// A 36x32 icon button, radius 8, no fill (Figma nodes 1217:2507 etc.).
class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _IconAction({required this.icon, required this.color, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 32,
          child: Center(child: Icon(icon, size: 16, color: onTap == null ? color.withValues(alpha: 0.4) : color)),
        ),
      ),
    );
  }
}

/// A white card with a short message and an optional action -- the empty and
/// load-failure states (neither exists in the design).
class _MessageCard extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageCard({required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border, width: _hairline),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: colors.textMuted),
          ),
          if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
