import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/kin_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ai_marketing_sheet_model.dart';
export 'ai_marketing_sheet_model.dart';

class AiMarketingSheetWidget extends StatefulWidget {
  const AiMarketingSheetWidget({super.key, required this.businessRef});

  final DocumentReference businessRef;

  @override
  State<AiMarketingSheetWidget> createState() => _AiMarketingSheetWidgetState();
}

class _AiMarketingSheetWidgetState extends State<AiMarketingSheetWidget> {
  late AiMarketingSheetModel _model;

  bool _loading = false;
  String? _error;
  MarketingContent? _content;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AiMarketingSheetModel());
    _model.themeController ??= TextEditingController();
    _model.themeFocusNode ??= FocusNode();
    _model.captionController ??= TextEditingController();
    _model.captionFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await KinServices.generateMarketingContent(
      businessRef: widget.businessRef,
      theme: _model.themeController?.text,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _content = result.data;
        // Reseed the editable caption for every generation, including a
        // regenerate - otherwise the previous suggestion's text (or the
        // owner's edits to it) would linger over the new one and get
        // logged as an edit of content it didn't come from.
        _model.captionController?.text = result.data?.caption ?? '';
      } else {
        _error = result.error;
      }
    });
  }

  void _regenerate() {
    final logId = _content?.generationLogId;
    if (logId != null) {
      KinServices.logAiSuggestionEngagement(
        generationLogId: logId,
        action: 'regenerated',
      );
    }
    _generate();
  }

  void _useThis() {
    final content = _content;
    if (content == null) return;
    final finalCaption = _model.captionController?.text ?? content.caption;
    // Trimmed comparison so trailing whitespace alone doesn't get recorded
    // as a meaningful rewrite, but the text is logged exactly as typed.
    final wasEdited = finalCaption.trim() != content.caption.trim();
    KinServices.logAiSuggestionEngagement(
      generationLogId: content.generationLogId,
      action: wasEdited ? 'edited' : 'used',
      // Only sent when it actually differs. The original is already on the
      // parent log doc, so an unchanged caption would just store the same
      // string twice, and the diff is derivable from the pair.
      finalCaption: wasEdited ? finalCaption : null,
    );
    Clipboard.setData(ClipboardData(
      text: '$finalCaption\n\n${content.hashtags.join(' ')}\n\n${content.cta}',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied — ready to paste into your post.')),
    );
    Navigator.pop(context);
  }

  void _dismiss() {
    final logId = _content?.generationLogId;
    if (logId != null) {
      KinServices.logAiSuggestionEngagement(
        generationLogId: logId,
        action: 'dismissed',
      );
    }
    Navigator.pop(context);
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
          MediaQuery.of(context).viewInsets.bottom +
              theme.designToken.spacing.lg,
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
                Icon(Icons.auto_awesome_rounded,
                    color: theme.primaryText, size: 20.0),
                SizedBox(width: theme.designToken.spacing.xs),
                Text(
                  'AI Marketing Orchestrator',
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
            SizedBox(height: theme.designToken.spacing.sm),
            TextFormField(
              controller: _model.themeController,
              focusNode: _model.themeFocusNode,
              maxLines: 2,
              decoration: InputDecoration(
                hintText:
                    "Optional: what's today's post about? (e.g. 'weekend brunch special')",
                hintStyle: theme.bodySmall.override(color: theme.hint),
                filled: true,
                fillColor: theme.secondaryBackground,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(theme.designToken.radius.sm),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.all(theme.designToken.spacing.sm),
              ),
              style: theme.bodyMedium.override(color: theme.secondaryText),
            ),
            SizedBox(height: theme.designToken.spacing.md),
            if (_content == null)
              FFButtonWidget(
                onPressed: _loading ? null : _generate,
                text: _loading ? 'Generating...' : 'Generate Post Idea',
                icon: _loading
                    ? null
                    : const Icon(Icons.bolt_rounded, size: 18.0),
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 48.0,
                  color: theme.primary,
                  textStyle: theme.titleSmall.override(color: Colors.white),
                  elevation: 0.0,
                  borderRadius:
                      BorderRadius.circular(theme.designToken.radius.sm),
                ),
              ),
            if (_error != null)
              Padding(
                padding: EdgeInsets.only(top: theme.designToken.spacing.sm),
                child: Text(
                  _error!,
                  style: theme.bodySmall.override(color: theme.error),
                ),
              ),
            if (_content != null) ..._buildResult(theme, _content!),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResult(FlutterFlowTheme theme, MarketingContent content) {
    return [
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(theme.designToken.radius.md),
        ),
        child: Padding(
          padding: EdgeInsets.all(theme.designToken.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _model.captionController,
                focusNode: _model.captionFocusNode,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: theme.bodyMedium.override(color: theme.secondaryText),
              ),
              Row(
                children: [
                  Icon(Icons.edit_outlined, color: theme.hint, size: 12.0),
                  SizedBox(width: theme.designToken.spacing.xs),
                  Text(
                    'Tap the caption to edit before using it',
                    style: theme.labelSmall.override(color: theme.hint),
                  ),
                ],
              ),
              SizedBox(height: theme.designToken.spacing.sm),
              Wrap(
                spacing: 6.0,
                children: content.hashtags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: theme.accent1.withAlpha(38),
                            borderRadius: BorderRadius.circular(
                                theme.designToken.radius.full),
                          ),
                          child: Text(
                            tag,
                            style: theme.labelSmall
                                .override(color: theme.primaryText),
                          ),
                        ))
                    .toList(),
              ),
              SizedBox(height: theme.designToken.spacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.campaign_rounded,
                      color: theme.secondary, size: 16.0),
                  SizedBox(width: theme.designToken.spacing.xs),
                  Expanded(
                    child: Text(
                      content.cta,
                      style: theme.bodySmall.override(
                        color: theme.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: theme.designToken.spacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.image_outlined, color: theme.hint, size: 16.0),
                  SizedBox(width: theme.designToken.spacing.xs),
                  Expanded(
                    child: Text(
                      content.imageConcept,
                      style: theme.bodySmall.override(color: theme.hint),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      SizedBox(height: theme.designToken.spacing.md),
      Row(
        children: [
          Expanded(
            child: FFButtonWidget(
              onPressed: _dismiss,
              text: 'Dismiss',
              options: FFButtonOptions(
                height: 44.0,
                color: theme.secondaryBackground,
                textStyle:
                    theme.bodyMedium.override(color: theme.secondaryText),
                elevation: 0.0,
                borderSide: BorderSide(color: theme.alternate),
                borderRadius:
                    BorderRadius.circular(theme.designToken.radius.sm),
              ),
            ),
          ),
          SizedBox(width: theme.designToken.spacing.sm),
          Expanded(
            child: FFButtonWidget(
              onPressed: _loading ? null : _regenerate,
              text: 'Regenerate',
              options: FFButtonOptions(
                height: 44.0,
                color: theme.secondaryBackground,
                textStyle: theme.bodyMedium.override(color: theme.primaryText),
                elevation: 0.0,
                borderSide: BorderSide(color: theme.accent1),
                borderRadius:
                    BorderRadius.circular(theme.designToken.radius.sm),
              ),
            ),
          ),
          SizedBox(width: theme.designToken.spacing.sm),
          Expanded(
            child: FFButtonWidget(
              onPressed: _useThis,
              text: 'Use This',
              options: FFButtonOptions(
                height: 44.0,
                color: theme.primary,
                textStyle: theme.bodyMedium.override(color: Colors.white),
                elevation: 0.0,
                borderRadius:
                    BorderRadius.circular(theme.designToken.radius.sm),
              ),
            ),
          ),
        ],
      ),
    ];
  }
}
