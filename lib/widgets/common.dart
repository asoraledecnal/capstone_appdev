import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Standard rounded panel/card used across all dashboard screens.
class DashCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DashCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

/// Small colored status/severity chip, e.g. ACTIVE, CRITICAL, HIGH, MODIFIED.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.outlined = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border:
            outlined ? Border.all(color: color.withValues(alpha: 0.5)) : null,
      ),
      child: Text(
        label,
        // A badge squeezed into a narrow flex column (e.g. a SEVERITY
        // column on a horizontally-scrolling table) would otherwise wrap
        // a word like "MEDIUM" onto two lines. Badges should always stay
        // on one line and shrink/ellipsize instead.
        softWrap: false,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Page header with title + subtitle, used at the top of every module screen.
class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 560;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: narrow ? 20 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        );

        if (trailing == null) return titleBlock;

        // On narrow screens, stack the trailing content (badges/buttons)
        // below the title and let it wrap, rather than squeezing both into
        // one Row where the title collapses to near-zero width.
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 10, children: [trailing!]),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            trailing!,
          ],
        );
      },
    );
  }
}

/// A simple data-table-like widget built with rows, since Flutter's DataTable
/// styling is hard to fully theme to match a dark dashboard aesthetic.
class SimpleTable extends StatelessWidget {
  final List<String> headers;
  final List<List<Widget>> rows;
  final List<int>? flex;

  /// Per-column alignment for both the header label and every cell in that
  /// column. Defaults to left-aligned (matches the previous behavior) when
  /// omitted. Pass e.g. `Alignment.center` for short/fixed-width columns
  /// like a status badge, count, or action button so they sit centered in
  /// their column instead of hugging the left edge.
  final List<Alignment>? align;

  const SimpleTable({
    super.key,
    required this.headers,
    required this.rows,
    this.flex,
    this.align,
  });

  @override
  Widget build(BuildContext context) {
    final flexValues = flex ?? List.filled(headers.length, 1);
    final alignValues =
        align ?? List.filled(headers.length, Alignment.centerLeft);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              for (int i = 0; i < headers.length; i++)
                Expanded(
                  flex: flexValues[i],
                  child: Align(
                    alignment: alignValues[i],
                    child: Text(
                      headers[i],
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.cardBorder),
        for (final row in rows) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (int i = 0; i < row.length; i++)
                  Expanded(
                    flex: flexValues[i],
                    child: Align(alignment: alignValues[i], child: row[i]),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),
        ],
      ],
    );
  }
}

/// Wraps a table (or any wide content) so that on screens narrower than
/// [minWidth] it becomes horizontally scrollable instead of squeezing every
/// column down to near-zero width (which is what causes text to wrap one
/// character per line on phones).
class HScrollBox extends StatelessWidget {
  final double minWidth;
  final Widget child;

  const HScrollBox({super.key, required this.minWidth, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final needsScroll = constraints.maxWidth < minWidth;
        final content = SizedBox(
          width: needsScroll ? minWidth : constraints.maxWidth,
          child: child,
        );
        if (!needsScroll) return content;
        // Scroll still works via swipe/drag/trackpad, but the scrollbar
        // thumb and the overscroll glow are hidden so the table edge stays
        // clean instead of showing a bar across the data.
        return ScrollConfiguration(
          behavior: const _NoScrollbarBehavior(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: content,
          ),
        );
      },
    );
  }
}

/// Hides the scrollbar thumb and overscroll glow so horizontally-scrollable
/// tables (HScrollBox) don't show a visible bar across the data.
class _NoScrollbarBehavior extends ScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class CellText extends StatelessWidget {
  final String text;
  final Color? color;
  final FontWeight weight;
  final double size;

  const CellText(
    this.text, {
    super.key,
    this.color,
    this.weight = FontWeight.normal,
    this.size = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color ?? AppColors.textPrimary,
        fontWeight: weight,
        fontSize: size,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class AdaptivePill extends StatelessWidget {
  final IconData? leadingIcon;
  final String label;
  final String? shortLabel;
  final IconData? trailingIcon;
  final bool filled;
  final Color accentColor;
  final EdgeInsets padding;
  final double borderRadius;
  final bool bordered;

  const AdaptivePill({
    super.key,
    this.leadingIcon,
    required this.label,
    this.shortLabel,
    this.trailingIcon,
    this.filled = false,
    this.accentColor = AppColors.teal,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    this.borderRadius = 20,
    this.bordered = true,
  });

  bool _fits(String text, TextStyle style, double maxWidth) {
    if (maxWidth <= 0) return false;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);
    return painter.width <= maxWidth;
  }

  @override
  Widget build(BuildContext context) {
    final contentColor = filled ? Colors.black : accentColor;
    final textStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: contentColor,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Fall back to full screen width if somehow unbounded, so this
        // never crashes — but see the doc comment above: always wrap in
        // Expanded/Flexible/SizedBox for this to actually do its job.
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        // Reserve room for the fixed "chrome" (icons + gaps + padding) so
        // what's left is the true budget available for the text itself.
        double chrome = padding.horizontal;
        if (leadingIcon != null) chrome += 15 + 6;
        if (trailingIcon != null) chrome += 4 + 16;
        final available = maxWidth - chrome;

        String? chosenLabel;
        if (_fits(label, textStyle, available)) {
          chosenLabel = label;
        } else if (shortLabel != null &&
            _fits(shortLabel!, textStyle, available)) {
          chosenLabel = shortLabel;
        } else {
          chosenLabel = null; // Neither fits — icon-only fallback.
        }

        return Container(
          padding: padding,
          decoration: BoxDecoration(
            color: filled ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
            border: bordered
                ? Border.all(color: filled ? accentColor : AppColors.cardBorder)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 15, color: contentColor),
                if (chosenLabel != null) const SizedBox(width: 6),
              ],
              if (chosenLabel != null) Text(chosenLabel, style: textStyle),
              if (trailingIcon != null) ...[
                const SizedBox(width: 4),
                Icon(trailingIcon, size: 16, color: contentColor),
              ],
            ],
          ),
        );
      },
    );
  }
}
