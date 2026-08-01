import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lets the signed-in user set or change the short bio shown on their own
/// CustomerProfilePage. Same bottom-sheet convention as
/// EditExchangePostSheet, minus the AI clean-up pass - a bio is short
/// enough that it isn't worth the extra round trip.
class EditBioSheet extends StatefulWidget {
  const EditBioSheet({super.key, required this.currentBio});

  final String currentBio;

  @override
  State<EditBioSheet> createState() => _EditBioSheetState();
}

class _EditBioSheetState extends State<EditBioSheet> {
  late final TextEditingController _textController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.currentBio);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final userRef = currentUserReference;
    if (userRef == null) return;
    final newBio = _textController.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await userRef.update({'bio': newBio});
      if (!mounted) return;
      Navigator.pop(context, newBio);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save. Try again.';
      });
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
                  'About Me',
                  style: theme.titleMedium.override(
                    font:
                        GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
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
              autofocus: true,
              maxLines: 4,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Tell the community a little about yourself...',
                hintStyle: theme.bodyMedium.override(color: theme.secondaryText),
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
