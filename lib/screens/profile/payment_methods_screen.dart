import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/payment_method.dart';
import '../../services/payment_method_service.dart';
import '../../theme/app_semantic_colors.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/screen_header.dart';
import 'add_payment_method_screen.dart';

// Sizes from the design; colours come from the theme so dark mode works.

const _hairline = 0.515;

/// The user's saved cards (brand, masked number, expiry, a "Default" badge), with buttons to add,
/// delete or set as default.
///
/// The database enforces one default card per user, so after each action the list is simply
/// reloaded from the server.
///
/// Added beyond the design: empty and error states, a delete confirmation and error messages.
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

  /// The card an action is running on; all buttons are disabled meanwhile.
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
    final added = await Navigator.of(
      context,
    ).push<bool>(appRoute(context, (_) => AddPaymentMethodScreen(isFirstCard: _methods.isEmpty)));
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
      if (mounted) _showMessage(AppLocalizations.of(context).genericTryAgainError);
    }
    if (!mounted) return;
    setState(() => _busyId = null);
    await _load();
  }

  Future<void> _delete(PaymentMethod method) async {
    if (_busyId != null) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeCardTitle),
        content: Text(l10n.removeCardBody(method.brand, method.last4)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancelButton)),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.removeButton, style: TextStyle(color: ctx.colors.danger)),
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
      if (mounted) _showMessage(l10n.genericTryAgainError);
    }
    if (!mounted) return;
    setState(() => _busyId = null);
    await _load(); // the database picks a new default if needed
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.pageBackgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(title: l10n.paymentMethodsLabel, onBack: () => Navigator.of(context).pop()),
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
                    message: l10n.couldntLoadPaymentMethods,
                    actionLabel: l10n.tryAgainButton,
                    onAction: _load,
                  )
                else if (_methods.isEmpty)
                  _MessageCard(message: l10n.noPaymentMethodsYet)
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

/// The "Add New Payment Method" button.
class _AddButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Container(
        height: 48,
        decoration: BoxDecoration(gradient: context.colors.accentGradient, borderRadius: BorderRadius.circular(8)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, size: 16, color: Colors.white),
                const SizedBox(width: 15),
                Text(
                  AppLocalizations.of(context).addNewPaymentMethodButton,
                  style: const TextStyle(
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

/// One saved card: card tile, brand (with "Default" badge), masked number, expiry, and its buttons.
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
                  // Uses theme colours so the tile stays visible on a dark card.
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
                tooltip: AppLocalizations.of(context).setAsDefaultTooltip,
                onTap: enabled ? onSetDefault : null,
              ),
              const SizedBox(width: 8),
            ],
            _IconAction(
              icon: Icons.delete_outline,
              color: colors.danger,
              tooltip: AppLocalizations.of(context).deleteTooltip,
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
    // Matches the design: the text column keeps a fixed height, so on the default card it overflows
    // slightly instead of growing the card.
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
                      style: TextStyle(fontSize: 18, height: 28 / 18, letterSpacing: -0.44, color: colors.textPrimary),
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
                        AppLocalizations.of(context).defaultBadge,
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

/// A small icon button.
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

/// A card with a message and an optional button, used for the empty and error states.
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
