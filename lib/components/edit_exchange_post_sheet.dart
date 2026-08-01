import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/kin_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lets the author of an Exchange post fix a typo or grammar error after
/// posting, with an optional "Clean up with AI" pass (KinServices.
/// cleanUpPostText) the author can accept, edit further, or ignore -
/// never applied automatically. Same bottom-sheet convention as
/// AiMarketingSheetWidget/AddBusinessDiscoveryDialog.
class EditExchangePostSheet extends StatefulWidget {
  const EditExchangePostSheet({super.key, required this.postRecord});

  final ExchangePostsRecord postRecord;

  @override
  State<EditExchangePostSheet> createState() => _EditExchangePostSheetState();
}

class _EditExchangePostSheetState extends State<EditExchangePostSheet> {
  late final TextEditingController _textController;
  bool _cleaningUp = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.postRecord.postText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _cleanUp() async {
    final current = _textController.text.trim();
    if (current.isEmpty) return;
    setState(() {
      _cleaningUp = true;
      _error = null;
    });
    final result = await KinServices.cleanUpPostText(postText: current);
    if (!mounted) return;
    setState(() {
      _cleaningUp = false;
      if (result.isSuccess) {
        _textController.text = result.data ?? current;
      } else {
        _error = result.error;
      }
    });
  }

  Future<void> _save() async {
    final newText = _textController.text.trim();
    if (newText.isEmpty) {
      setState(() => _error = 'Post can\'t be empty.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await KinServices.editExchangePost(
      postRef: widget.postRecord.reference,
      postText: newText,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.isSuccess) {
      Navigator.pop(context);
    } else {
      setState(() => _error = result.error);
    }
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
              MediaQuery.of(context).padding.bottom +
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
                Icon(Icons.edit_rounded, color: theme.primaryText, size: 20.0),
                SizedBox(width: theme.designToken.spacing.xs),
                Text(
                  'Edit Post',
                  style: theme.titleMedium.override(
                    font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                    color: theme.primaryText,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.0,
                  ),
                ),
              ],
            ),
            SizedBox(height: theme.designToken.spacing.sm),
            TextFormField(
              controller: _textController,
              maxLines: 5,
              maxLength: 2000,
              decoration: InputDecoration(
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
            OutlinedButton.icon(
              onPressed: _cleaningUp ? null : _cleanUp,
              icon: _cleaningUp
                  ? SizedBox(
                      width: 14.0,
                      height: 14.0,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    )
                  : const Icon(Icons.auto_awesome_rounded, size: 16.0),
              label: Text(_cleaningUp ? 'Cleaning up...' : 'Clean up with AI'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primaryText,
                side: BorderSide(color: theme.alternate),
              ),
            ),
            if (_error != null) ...[
              SizedBox(height: theme.designToken.spacing.xs),
              Text(
                _error!,
                style: theme.bodySmall.override(color: theme.error),
              ),
            ],
            SizedBox(height: theme.designToken.spacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.secondaryText,
                      side: BorderSide(color: theme.alternate),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: theme.designToken.spacing.sm),
                Expanded(
                  child: FFButtonWidget(
                    onPressed: _saving ? null : _save,
                    text: _saving ? 'Saving...' : 'Save',
                    options: FFButtonOptions(
                      height: 44.0,
                      color: theme.primary,
                      textStyle: theme.titleSmall.override(color: Colors.white),
                      elevation: 0.0,
                      borderRadius:
                          BorderRadius.circular(theme.designToken.radius.sm),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
