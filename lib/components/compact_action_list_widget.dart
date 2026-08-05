import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// One tappable row for [CompactActionListWidget]: an icon, a bold title, a
/// muted subtitle, and a trailing chevron.
class CompactActionRowData {
  const CompactActionRowData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Styles the row in the error color (icon, title, chevron) - for
  /// warnings like account deletion, where blending in with the other rows
  /// would undersell how permanent the action is.
  final bool isDestructive;
}

/// A single bordered card holding one or more [CompactActionRowData] rows,
/// separated by hairline dividers instead of each row carrying its own
/// border/background/padding.
///
/// Replaces a pattern that was duplicated per-row across
/// customer_profile_page_widget.dart, owner_profile_widget.dart, and
/// growth_tools_page_widget.dart: every action (Share KIN, Get Support,
/// Growth Tools, Job Board Messages, ...) was its own full-width bordered
/// box with 16px padding on every side. Stood alone that reads fine, but
/// customer_profile_page_widget.dart stacked four of them in a row, which
/// is what actually made the page feel dense - four borders, four
/// backgrounds, four rounded corners, four blocks of internal padding all
/// competing for attention. Grouping rows under one shared card (even a
/// card of one) cuts that down to a single outer border and slimmer
/// per-row padding, while every row keeps its own tap target, icon, title,
/// and subtitle.
class CompactActionListWidget extends StatelessWidget {
  const CompactActionListWidget({super.key, required this.items});

  final List<CompactActionRowData> items;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: theme.alternate, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1.0, thickness: 1.0, color: theme.alternate),
            _CompactActionRow(theme: theme, data: items[i]),
          ],
        ],
      ),
    );
  }
}

class _CompactActionRow extends StatelessWidget {
  const _CompactActionRow({required this.theme, required this.data});

  final FlutterFlowTheme theme;
  final CompactActionRowData data;

  @override
  Widget build(BuildContext context) {
    final accent = data.isDestructive ? theme.error : theme.accentOnSurface;
    final titleColor = data.isDestructive ? theme.error : theme.primaryText;
    return InkWell(
      onTap: data.onTap,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 12.0),
        child: Row(
          children: [
            Icon(data.icon, color: accent, size: 20.0),
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 8.0, 0.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: theme.bodyMedium.override(
                        font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                        color: titleColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.0,
                      ),
                    ),
                    Text(
                      data.subtitle,
                      style: theme.bodySmall.override(
                        font: GoogleFonts.plusJakartaSans(),
                        color: theme.secondaryText,
                        letterSpacing: 0.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: data.isDestructive ? theme.error : theme.secondaryText,
              size: 18.0,
            ),
          ],
        ),
      ),
    );
  }
}
