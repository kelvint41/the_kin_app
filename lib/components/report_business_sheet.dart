import 'package:flutter/material.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/kin_services.dart';

/// "This isn't a Black-owned business" - the report/delist entry point.
///
/// KIN lists verified Black-owned businesses, but the bulk imports brought
/// in rows that don't qualify (Panifico Bakeshop is the known example) and
/// there was no way for anyone standing in front of one to say so. This is
/// that path.
///
/// Deliberately two different actions behind one entry point:
///
///  - A customer files a report. It queues; nothing they can see changes.
///    One stranger's tap must not be able to delist a real Black-owned
///    business, and a competitor must not be able to knock a rival off the
///    map.
///  - An admin removes it on the spot, because the person doing the
///    verifying is standing at the address and already knows the answer.
///    Reversible - see KinServices.restoreBusiness.
void showReportBusinessSheet(
  BuildContext context, {
  required BusinessesRecord business,
  VoidCallback? onHidden,
}) {
  final isAdmin = currentUserDocument?.isAdmin == true;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _ReportBusinessSheet(
      business: business,
      isAdmin: isAdmin,
      onHidden: onHidden,
    ),
  );
}

class _ReportBusinessSheet extends StatefulWidget {
  const _ReportBusinessSheet({
    required this.business,
    required this.isAdmin,
    this.onHidden,
  });

  final BusinessesRecord business;
  final bool isAdmin;
  final VoidCallback? onHidden;

  @override
  State<_ReportBusinessSheet> createState() => _ReportBusinessSheetState();
}

class _ReportBusinessSheetState extends State<_ReportBusinessSheet> {
  final noteController = TextEditingController();
  bool submitting = false;

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final userRef = currentUserReference;
    if (userRef == null) return;
    setState(() => submitting = true);

    final result = widget.isAdmin
        ? await KinServices.hideBusiness(
            businessRef: widget.business.reference,
            adminRef: userRef,
            reason: 'not_black_owned',
          )
        : await KinServices.reportBusinessListing(
            businessRef: widget.business.reference,
            reporterRef: userRef,
            reason: 'not_black_owned',
            note: noteController.text,
          );

    if (!mounted) return;
    setState(() => submitting = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? (widget.isAdmin
                  ? '${widget.business.businessName} removed from KIN.'
                  : 'Thanks - we\'ll review this listing.')
              : result.error!,
        ),
      ),
    );
    if (result.isSuccess && widget.isAdmin) widget.onHidden?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(theme.designToken.radius.lg),
            topRight: Radius.circular(theme.designToken.radius.lg),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.0,
                    height: 4.0,
                    margin: const EdgeInsets.only(bottom: 20.0),
                    decoration: BoxDecoration(
                      color: theme.alternate,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                Text(
                  widget.isAdmin
                      ? 'Remove this business?'
                      : 'Is this not a Black-owned business?',
                  style: theme.titleMedium,
                ),
                const SizedBox(height: 8.0),
                Text(
                  widget.business.businessName,
                  style: theme.bodyMedium.override(color: theme.primary),
                ),
                const SizedBox(height: 16.0),
                Text(
                  widget.isAdmin
                      ? 'This removes it from the map, Quest, search, and the '
                          'feed right away. You can restore it later if you '
                          'need to.'
                      : 'KIN only lists Black-owned businesses. Tell us and '
                          'we\'ll check it out - the listing stays up until '
                          'someone reviews it.',
                  style: theme.bodySmall.override(color: theme.secondaryText),
                ),
                if (!widget.isAdmin) ...[
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Anything else we should know? (optional)',
                      labelStyle: theme.labelSmall,
                      alignLabelWithHint: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.alternate),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: theme.primary, width: 2.0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    style: theme.bodySmall,
                  ),
                ],
                const SizedBox(height: 24.0),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: submitting
                            ? null
                            : () => Navigator.pop(context),
                        child: Text('Cancel', style: theme.bodyMedium),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: FilledButton(
                        onPressed: submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              widget.isAdmin ? theme.error : theme.primary,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14.0),
                        ),
                        child: Text(
                          submitting
                              ? 'Working...'
                              : (widget.isAdmin
                                  ? 'Remove from KIN'
                                  : 'Send report'),
                          style: theme.bodyMedium.override(color: theme.info),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
