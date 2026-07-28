import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The submission half of `bug_reports`.
///
/// The collection, its record schema and the two cards that render it all
/// existed already, but nothing ever wrote to it - there was no form
/// anywhere in the app, so it had sat empty since it was created. This is
/// that form.
///
/// Deliberately one sheet for all three kinds of feedback rather than a
/// separate "report a bug" and "suggest a feature" flow. People do not
/// reliably know which one they have, and being asked to classify a
/// complaint before making it is the sort of friction that means it never
/// gets made. `feedback_type` sorts it out afterwards.
class FeedbackSheetWidget extends StatefulWidget {
  const FeedbackSheetWidget({super.key, this.originPage});

  /// Where the user was when they opened this, recorded as
  /// `page_where_it_happened`. Passed in rather than inferred, because by
  /// the time this sheet is on screen the route is this sheet.
  final String? originPage;

  @override
  State<FeedbackSheetWidget> createState() => _FeedbackSheetWidgetState();
}

class _FeedbackSheetWidgetState extends State<FeedbackSheetWidget> {
  static const _types = ['Bug', 'Feature request', 'General feedback'];

  final _descriptionController = TextEditingController();
  String _type = 'General feedback';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _descriptionController.text.trim();
    // Mirrors the rule rather than trusting it to produce a good message:
    // a rules rejection surfaces as a generic permission error, which
    // tells the user nothing about what to fix.
    if (text.isEmpty) {
      setState(() => _error = 'Tell us what happened first.');
      return;
    }
    if (text.length > 2000) {
      setState(() => _error =
          'That is ${text.length} characters - the limit is 2000.');
      return;
    }
    final userRef = currentUserReference;
    if (userRef == null) {
      setState(() => _error = 'Sign in to send feedback.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await BugReportsRecord.collection.doc().set(createBugReportsRecordData(
            testerName: currentUserDisplayName,
            issueDescription: text,
            pageWhereItHappened: widget.originPage ?? 'Unspecified',
            feedbackType: _type,
            timestamp: getCurrentTimestamp,
            userRef: userRef,
          ));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not send that. Please try again.';
      });
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Thanks - that came through.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Padding(
      // Lifts the sheet clear of the keyboard, which otherwise covers the
      // send button on the field it belongs to.
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell us what you think',
              style: theme.headlineSmall.override(
                font:
                    GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
                letterSpacing: 0.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0, 6, 0, 16),
              child: Text(
                'Bugs, ideas, or anything that felt wrong. It goes straight '
                'to the team.',
                style: theme.bodySmall.override(
                  font: GoogleFonts.plusJakartaSans(),
                  color: theme.secondaryText,
                  letterSpacing: 0.0,
                ),
              ),
            ),
            Wrap(
              spacing: 8.0,
              children: [
                for (final type in _types)
                  ChoiceChip(
                    label: Text(type),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                    labelStyle: theme.bodySmall.override(
                      font: GoogleFonts.plusJakartaSans(),
                      color: _type == type
                          ? theme.info
                          : theme.primaryText,
                      letterSpacing: 0.0,
                    ),
                    selectedColor: theme.primary,
                    backgroundColor: theme.secondaryBackground,
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                maxLength: 2000,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: _type == 'Bug'
                      ? 'What did you do, and what happened instead?'
                      : 'What would you like to see?',
                  filled: true,
                  fillColor: theme.secondaryBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: theme.alternate),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: theme.alternate),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: theme.primary),
                  ),
                ),
                style: theme.bodyMedium.override(
                  font: GoogleFonts.plusJakartaSans(),
                  letterSpacing: 0.0,
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0, 4, 0, 0),
                child: Text(
                  _error!,
                  style: theme.bodySmall.override(
                    font: GoogleFonts.plusJakartaSans(),
                    color: theme.error,
                    letterSpacing: 0.0,
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
              child: FFButtonWidget(
                onPressed: _submitting ? null : _submit,
                text: _submitting ? 'Sending...' : 'Send',
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 48.0,
                  color: theme.primary,
                  textStyle: theme.titleSmall.override(
                    font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold),
                    color: theme.info,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
