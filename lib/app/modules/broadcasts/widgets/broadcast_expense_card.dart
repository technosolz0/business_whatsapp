import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Card that shows the financial summary of a broadcast:
///  • Blocked Amount  → totalCost stored on the broadcast document
///  • Actual Spent   → chargeable_amount from wallet/broadcast_history
///
/// Dimensions follow design spec:
///   width: 278, height: 142, border-radius: 12, border: 1 px
///   padding: 24 top / 16 right / 16 bottom / 16 left  gap: 16 px
class BroadcastExpenseCard extends StatefulWidget {
  /// Pre-loaded blocked amount (totalCost / 100) in rupees.
  final double? blockedAmount;

  /// Async loader that fetches chargeable_amount from Firebase.
  final Future<double?> Function() fetchActualSpent;

  const BroadcastExpenseCard({
    super.key,
    required this.blockedAmount,
    required this.fetchActualSpent,
  });

  @override
  State<BroadcastExpenseCard> createState() => _BroadcastExpenseCardState();
}

class _BroadcastExpenseCardState extends State<BroadcastExpenseCard> {
  double? _actualSpent;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(BroadcastExpenseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-fetch when the broadcast changes (fetchActualSpent closure changes).
    if (oldWidget.fetchActualSpent != widget.fetchActualSpent) {
      setState(() {
        _actualSpent = null;
        _loading = true;
      });
      _load();
    }
  }

  Future<void> _load() async {
    final result = await widget.fetchActualSpent();
    if (mounted) {
      setState(() {
        _actualSpent = result;
        _loading = false;
      });
    }
  }

  String _formatRupees(double? amount) {
    if (amount == null) return '—';
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color cardBg = isDark
        ? AppColors.gray800.withValues(alpha: 0.5)
        : AppColors.gray50;
    final Color iconBg = AppColors.success.withValues(alpha: 0.12);
    final Color titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final Color labelColor =
        isDark ? AppColors.textSecondaryDark : const Color(0xFF6B7280);
    const Color actualSpentColor = AppColors.success;

    return Container(
      width: 278,
      constraints: const BoxConstraints(minHeight: 142),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 24,
          right: 16,
          bottom: 16,
          left: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header row ──────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Broadcast Expense',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Two-column amounts ───────────────────────────────────────
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Blocked Amount
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BLOCKED AMOUNT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: labelColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatRupees(widget.blockedAmount),
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    indent: 0,
                    endIndent: 0,
                  ),

                  const SizedBox(width: 16),

                  // Actual Spent
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTUAL SPENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: labelColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _loading
                            ? SizedBox(
                                width: 60,
                                height: 22,
                                child: LinearProgressIndicator(
                                  borderRadius: BorderRadius.circular(4),
                                  color: AppColors.success,
                                  backgroundColor: AppColors.success
                                      .withValues(alpha: 0.15),
                                ),
                              )
                            : Text(
                                _formatRupees(_actualSpent),
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: actualSpentColor,
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
