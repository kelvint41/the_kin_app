import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/kin_services.dart';

/// GPS check-in control shown next to the review form.
///
/// A review can always be posted, checked in or not - the check-in only
/// decides whether that review counts toward the business's Kindex score
/// in the nightly recompute. The copy has to make that distinction clear,
/// because a customer who declines location should understand what they're
/// giving up without feeling blocked.
///
/// The location read is one-shot and happens only on tap; there is no
/// background tracking.
class VisitCheckInWidget extends StatefulWidget {
  const VisitCheckInWidget({super.key, required this.businessRef});

  final DocumentReference businessRef;

  @override
  State<VisitCheckInWidget> createState() => _VisitCheckInWidgetState();
}

class _VisitCheckInWidgetState extends State<VisitCheckInWidget> {
  bool _checking = false;
  bool _verified = false;
  bool _loadingInitialState = true;

  @override
  void initState() {
    super.initState();
    _loadVerifiedState();
  }

  Future<void> _loadVerifiedState() async {
    final verified =
        await KinServices.hasVerifiedVisit(businessRef: widget.businessRef);
    if (!mounted) return;
    setState(() {
      _verified = verified;
      _loadingInitialState = false;
    });
  }

  Future<void> _checkIn() async {
    setState(() => _checking = true);
    final result =
        await KinServices.checkInToBusiness(businessRef: widget.businessRef);
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (result.isSuccess) _verified = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    if (result.isSuccess) {
      messenger.showSnackBar(SnackBar(
        content: Text(result.data!.alreadyCheckedIn
            ? "You're already checked in here - your review will count."
            : "Checked in. Your review will count toward this business's Kindex score."),
      ));
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(result.error!),
        duration: const Duration(seconds: 6),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (_loadingInitialState) {
      return const SizedBox(height: 48.0);
    }

    if (_verified) {
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, color: theme.success, size: 18.0),
            const SizedBox(width: 8.0),
            Flexible(
              child: Text(
                'Visit verified - your review counts toward the Kindex score.',
                style: theme.labelSmall.override(
                  font: GoogleFonts.plusJakartaSans(
                    fontWeight: theme.labelSmall.fontWeight,
                    fontStyle: theme.labelSmall.fontStyle,
                  ),
                  color: theme.secondaryText,
                  letterSpacing: 0.0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FFButtonWidget(
            onPressed: _checking ? null : _checkIn,
            text: _checking ? 'Checking...' : "I'm Here - Check In",
            icon: const Icon(Icons.location_on_outlined, size: 18.0),
            options: FFButtonOptions(
              height: 40.0,
              padding:
                  const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
              iconPadding:
                  const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 8.0, 0.0),
              color: theme.primary,
              textStyle: theme.titleSmall.override(
                font: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontStyle: theme.titleSmall.fontStyle,
                ),
                color: theme.info,
                letterSpacing: 0.0,
              ),
              elevation: 0.0,
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Checking in confirms you actually visited, which keeps Kindex '
            'scores trustworthy. You can still leave a review without it - '
            "it just won't affect the score.",
            style: theme.labelSmall.override(
              font: GoogleFonts.plusJakartaSans(
                fontWeight: theme.labelSmall.fontWeight,
                fontStyle: theme.labelSmall.fontStyle,
              ),
              color: theme.secondaryText,
              letterSpacing: 0.0,
              lineHeight: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
