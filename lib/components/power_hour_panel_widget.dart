import 'dart:async';

import '/components/ai_marketing_sheet_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/kin_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'power_hour_panel_model.dart';
export 'power_hour_panel_model.dart';

/// Interactive control panel for a business's Power Hour flash-beacon
/// promotion. Off state shows a duration picker + "Start Power Hour".
/// Live state shows a countdown - computed client-side from
/// flashBeaconExpiresAt via a local Timer, not a Firestore read on a
/// loop - plus "Stop Power Hour" (confirm-gated, since an accidental
/// early stop mid-promotion is the costlier mistake; starting isn't).
///
/// Expiry itself is handled server-side by the existing
/// checkAndExpireBeacons scheduled Cloud Function - this widget only
/// ever sets/clears has_flash_beacon via KinServices.startPowerHour /
/// stopPowerHour.
class PowerHourPanelWidget extends StatefulWidget {
  const PowerHourPanelWidget({
    super.key,
    required this.businessRef,
    required this.hasFlashBeacon,
    this.flashBeaconExpiresAt,
  });

  final DocumentReference businessRef;
  final bool hasFlashBeacon;
  final DateTime? flashBeaconExpiresAt;

  @override
  State<PowerHourPanelWidget> createState() => _PowerHourPanelWidgetState();
}

class _PowerHourPanelWidgetState extends State<PowerHourPanelWidget>
    with SingleTickerProviderStateMixin {
  late PowerHourPanelModel _model;
  late AnimationController _pulseController;
  Timer? _countdownTimer;
  int _selectedDurationMinutes = 30;
  bool _isSubmitting = false;

  bool get _isLive =>
      widget.hasFlashBeacon &&
      widget.flashBeaconExpiresAt != null &&
      widget.flashBeaconExpiresAt!.isAfter(DateTime.now());

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PowerHourPanelModel());
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    );
    _syncCountdownTimer();
  }

  @override
  void didUpdateWidget(covariant PowerHourPanelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncCountdownTimer();
  }

  void _syncCountdownTimer() {
    if (_isLive && _countdownTimer == null) {
      _pulseController.repeat(reverse: true);
      _countdownTimer = Timer.periodic(Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (!_isLive) {
          _syncCountdownTimer();
        }
        safeSetState(() {});
      });
    } else if (!_isLive && _countdownTimer != null) {
      _countdownTimer!.cancel();
      _countdownTimer = null;
      _pulseController
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _model.dispose();
    super.dispose();
  }

  String _formatRemaining() {
    final remaining = widget.flashBeaconExpiresAt!.difference(DateTime.now());
    if (remaining.isNegative) return '0:00';
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _start() async {
    setState(() => _isSubmitting = true);
    final result = await KinServices.startPowerHour(
      businessRef: widget.businessRef,
      durationMinutes: _selectedDurationMinutes,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (!result.isSuccess) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.error!)));
    }
  }

  void _openAiMarketing() {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => Padding(
        padding: MediaQuery.viewInsetsOf(context),
        child: AiMarketingSheetWidget(businessRef: widget.businessRef),
      ),
    );
  }

  Future<void> _confirmStop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Stop Power Hour?'),
        content: Text(
            'Your promotion will end early and stop appearing to nearby customers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Stop Now'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    final result =
        await KinServices.stopPowerHour(businessRef: widget.businessRef);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (!result.isSuccess) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLive ? _buildLiveState(context) : _buildOffState(context);
  }

  Widget _buildLiveState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FadeTransition(
              opacity:
                  Tween<double>(begin: 0.4, end: 1.0).animate(_pulseController),
              child: Container(
                width: 10.0,
                height: 10.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SizedBox(width: 8.0),
            Text(
              'LIVE',
              style: FlutterFlowTheme.of(context).labelMedium.override(
                    font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold),
                    color: FlutterFlowTheme.of(context).primary,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Spacer(),
            Text(
              _formatRemaining(),
              style: FlutterFlowTheme.of(context).headlineSmall.override(
                    font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold),
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        SizedBox(height: 16.0),
        FFButtonWidget(
          onPressed: _isSubmitting ? null : _confirmStop,
          text: _isSubmitting ? 'Stopping...' : 'Stop Power Hour',
          options: FFButtonOptions(
            width: double.infinity,
            height: 44.0,
            color: Colors.transparent,
            textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                  color: FlutterFlowTheme.of(context).error,
                ),
            elevation: 0.0,
            borderSide: BorderSide(
              color: FlutterFlowTheme.of(context).error,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ],
    );
  }

  Widget _buildOffState(BuildContext context) {
    const durations = [30, 60, 120];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Boost your visibility to nearby customers for a limited time.',
          style: FlutterFlowTheme.of(context).bodySmall.override(
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
        ),
        SizedBox(height: 12.0),
        Row(
          children: durations
              .map(
                (minutes) => Padding(
                  padding: EdgeInsetsDirectional.only(end: 8.0),
                  child: InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () =>
                        setState(() => _selectedDurationMinutes = minutes),
                    child: Container(
                      height: 34.0,
                      padding:
                          EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primary,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: _selectedDurationMinutes == minutes
                              ? const Color(0xFFD4AF37)
                              : FlutterFlowTheme.of(context).alternate,
                          width: 1.0,
                        ),
                      ),
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Text(
                        minutes < 60 ? '$minutes min' : '${minutes ~/ 60} hr',
                        style: FlutterFlowTheme.of(context)
                            .labelMedium
                            .override(
                              color: const Color(0xFFD4AF37),
                            ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        SizedBox(height: 12.0),
        FFButtonWidget(
          onPressed: _openAiMarketing,
          text: 'Get an AI post idea for this promotion',
          icon: Icon(Icons.auto_awesome_rounded,
              color: const Color(0xFFD4AF37), size: 16.0),
          options: FFButtonOptions(
            width: double.infinity,
            height: 40.0,
            color: Colors.transparent,
            textStyle: FlutterFlowTheme.of(context).labelMedium.override(
                  color: const Color(0xFFD4AF37),
                ),
            elevation: 0.0,
            borderSide: BorderSide(
              color: const Color(0xFFD4AF37).withAlpha(102),
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        SizedBox(height: 12.0),
        FFButtonWidget(
          onPressed: _isSubmitting ? null : _start,
          text: _isSubmitting ? 'Starting...' : 'Start Power Hour',
          options: FFButtonOptions(
            width: double.infinity,
            height: 44.0,
            color: FlutterFlowTheme.of(context).primary,
            // // The brand gold as a literal, not primaryText. These sit on a fixed dark
            // surface (theme.primary, the deep green, and a hardcoded 0xFF1E1E1E chip)
            // which does not change with the theme - so a *text* token that inverts
            // between modes is the wrong tool. When light-mode primaryText became a
            // near-black for body legibility, every one of these labels turned
            // near-black on dark green and disappeared. 0xFFD4AF37 reads on this
            // surface in both modes, which is the whole reason the app pairs them.
            textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                  color: const Color(0xFFD4AF37),
                ),
            elevation: 0.0,
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ],
    );
  }
}
