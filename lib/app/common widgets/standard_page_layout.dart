import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Utilities/responsive.dart';
import '../core/theme/app_colors.dart';

class StandardPageLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? headerActions;
  final List<Widget>? toolbarWidgets;
  final Widget child;
  final bool showBackButton;
  final VoidCallback? onBack;
  final double maxWidth;
  final bool isContentScrollable;

  const StandardPageLayout({
    super.key,
    required this.title,
    this.subtitle,
    this.headerActions,
    this.toolbarWidgets,
    required this.child,
    this.showBackButton = false,
    this.onBack,
    this.maxWidth = 1810,
    this.isContentScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 16.0 : 24.0;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(context, isDark, isMobile),

        // Toolbar (Search, Filters, etc.)
        if (toolbarWidgets != null && toolbarWidgets!.isNotEmpty) ...[
          SizedBox(height: padding),
          _buildToolbar(context, isMobile),
        ],

        SizedBox(height: padding),

        // Main Content
        if (isContentScrollable)
          Expanded(child: SingleChildScrollView(child: child))
        else
          Expanded(child: child),
      ],
    );

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: EdgeInsets.all(padding),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, bool isMobile) {
    final hasActions = headerActions != null && headerActions!.isNotEmpty;

    // On mobile or very narrow tablet, we should stack title and actions
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTitleSection(isDark, isMobile),
          if (hasActions) ...[
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: headerActions!),
          ],
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildTitleSection(isDark, isMobile)),
        if (hasActions) ...[
          const SizedBox(width: 16),
          // Actions on tablet/desktop - use Flexible and Wrap to prevent overflow
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 100),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: headerActions!,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTitleSection(bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showBackButton) ...[
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack ?? () => Get.back(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  letterSpacing: -0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 15,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: toolbarWidgets!.map((w) {
          Widget child = w;
          if (w is Expanded) child = w.child;
          if (w is Flexible) child = w.child;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: child,
          );
        }).toList(),
      );
    }

    // On tablet, if we have many widgets, Row might overflow.
    // Wrap is safer, but we need to handle Expanded.
    if (Responsive.isTablet(context)) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: toolbarWidgets!.map((w) {
          Widget child = w;
          if (w is Expanded) {
            // In a Wrap, Expanded doesn't work. We'll give it a minimum width or let it size to content.
            // For search fields, we might want them to be wider.
            return Container(
              constraints: const BoxConstraints(minWidth: 200),
              child: w.child,
            );
          }
          if (w is Flexible) child = w.child;
          return child;
        }).toList(),
      );
    }

    // For Desktop, we generally want Row to support Expanded (e.g. Search field)
    return Row(
      children: [
        for (int i = 0; i < toolbarWidgets!.length; i++) ...[
          toolbarWidgets![i],
          if (i < toolbarWidgets!.length - 1 &&
              toolbarWidgets![i] is! Expanded &&
              toolbarWidgets![i] is! Flexible)
            const SizedBox(width: 12),
        ],
      ],
    );
  }
}
