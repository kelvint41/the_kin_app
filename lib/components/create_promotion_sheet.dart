import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lets a verified business owner post a time-limited promotion to
/// exchange_promotions - title, optional details, and how long it runs.
/// Read by both The Exchange's promo rail and Customer Profile's "Exclusive
/// Connection Stream", which already queries this collection but had no
/// write path anywhere in the app until this sheet. Same bottom-sheet
/// convention as EditExchangePostSheet/AiMarketingSheetWidget.
class CreatePromotionSheet extends StatefulWidget {
  const CreatePromotionSheet({super.key, required this.businessRef});

  final DocumentReference businessRef;

  @override
  State<CreatePromotionSheet> createState() => _CreatePromotionSheetState();
}

class _CreatePromotionSheetState extends State<CreatePromotionSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  // 24h default: long enough to cover a single business day, short enough
  // that the rail doesn't fill up with stale offers from an owner who
  // forgets about it.
  Duration _selectedDuration = const Duration(hours: 24);
  bool _saving = false;
  String? _error;

  static const _durationOptions = <String, Duration>{
    '24 hours': Duration(hours: 24),
    '3 days': Duration(days: 3),
    '1 week': Duration(days: 7),
  };

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Give the promotion a title.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final ref = ExchangePromotionsRecord.collection.doc();
    try {
      await ref.set(createExchangePromotionsRecordData(
        businessRef: widget.businessRef,
        title: title,
        body: _bodyController.text.trim(),
        createdAt: getCurrentTimestamp,
        expiresAt: DateTime.now().add(_selectedDuration),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not post: $e';
      });
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(theme.designToken.radius.lg),
          topRight: Radius.circular(theme.designToken.radius.lg),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          theme.designToken.spacing.lg,
          theme.designToken.spacing.md,
          theme.designToken.spacing.lg,
          MediaQuery.of(context).padding.bottom + theme.designToken.spacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.0,
                height: 4.0,
                margin: EdgeInsets.only(bottom: theme.designToken.spacing.md),
                decoration: BoxDecoration(
                  color: theme.alternate,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.local_offer_rounded,
                    color: theme.primaryText, size: 20.0),
                SizedBox(width: theme.designToken.spacing.xs),
                Text(
                  'New Promotion',
                  style: theme.titleMedium.override(
                    font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold),
                    color: theme.primaryText,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.0,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.0),
            Text(
              'Shows in the promo rail above the feed, and in customers\' '
              'Exclusive Connection Stream, until it expires.',
              style: theme.bodySmall.override(color: theme.secondaryText),
            ),
            SizedBox(height: theme.designToken.spacing.md),
            TextFormField(
              controller: _titleController,
              maxLength: 80,
              decoration: InputDecoration(
                hintText: 'Title (e.g. "Happy Hour")',
                hintStyle: theme.bodyMedium.override(color: theme.hint),
                filled: true,
                fillColor: theme.secondaryBackground,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(theme.designToken.radius.sm),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.all(theme.designToken.spacing.sm),
              ),
              style: theme.bodyMedium.override(color: theme.primaryText),
            ),
            SizedBox(height: theme.designToken.spacing.sm),
            TextFormField(
              controller: _bodyController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText:
                    'Details (e.g. "20% off drinks, 4-6pm today")',
                hintStyle: theme.bodyMedium.override(color: theme.hint),
                filled: true,
                fillColor: theme.secondaryBackground,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(theme.designToken.radius.sm),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.all(theme.designToken.spacing.sm),
              ),
              style: theme.bodyMedium.override(color: theme.primaryText),
            ),
            SizedBox(height: theme.designToken.spacing.sm),
            Text(
              'Runs for',
              style: theme.labelMedium.override(color: theme.secondaryText),
            ),
            SizedBox(height: theme.designToken.spacing.xs),
            Row(
              children: _durationOptions.entries.map((entry) {
                final isSelected = _selectedDuration == entry.value;
                return Padding(
                  padding: EdgeInsetsDirectional.only(
                      end: theme.designToken.spacing.sm),
                  child: ChoiceChip(
                    label: Text(entry.key),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedDuration = entry.value),
                    selectedColor: theme.primary,
                    backgroundColor: theme.secondaryBackground,
                    side: BorderSide(color: theme.alternate),
                    labelStyle: theme.labelMedium.override(
                      color: isSelected ? theme.onPrimary : theme.primaryText,
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_error != null) ...[
              SizedBox(height: theme.designToken.spacing.xs),
              Text(
                _error!,
                style: theme.bodySmall.override(color: theme.error),
              ),
            ],
            SizedBox(height: theme.designToken.spacing.md),
            FFButtonWidget(
              onPressed: _saving ? null : _post,
              text: _saving ? 'Posting...' : 'Post Promotion',
              options: FFButtonOptions(
                width: double.infinity,
                height: 44.0,
                color: theme.primary,
                textStyle: theme.titleSmall.override(color: theme.onPrimary),
                elevation: 0.0,
                borderRadius:
                    BorderRadius.circular(theme.designToken.radius.sm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
