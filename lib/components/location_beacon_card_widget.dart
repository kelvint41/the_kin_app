import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/kin_services.dart';
import '/components/location_beacon_modal_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationBeaconCardWidget extends StatefulWidget {
  const LocationBeaconCardWidget({
    super.key,
    required this.businessRef,
    required this.businessName,
    required this.isMobileVendor,
    this.currentLocation,
    this.expiresAt,
    this.isActive = false,
  });

  final DocumentReference businessRef;
  final String businessName;
  final bool isMobileVendor;
  final String? currentLocation;
  final DateTime? expiresAt;
  final bool isActive;

  @override
  State<LocationBeaconCardWidget> createState() =>
      _LocationBeaconCardWidgetState();
}

class _LocationBeaconCardWidgetState extends State<LocationBeaconCardWidget> {
  bool _isStopping = false;

  Future<void> _stopBeacon() async {
    safeSetState(() => _isStopping = true);
    final result = await KinServices.stopLocationBeacon(
      businessRef: widget.businessRef,
    );
    if (!mounted) return;
    safeSetState(() => _isStopping = false);

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location beacon stopped.')),
    );
  }

  String _formatTimeUntilExpiry(DateTime expiresAt) {
    final now = DateTime.now();
    final duration = expiresAt.difference(now);

    if (duration.isNegative) return 'Expired';
    if (duration.inHours > 0) return '${duration.inHours}h left';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m left';
    return 'Expiring soon';
  }

  @override
  Widget build(BuildContext context) {
    // Only show for mobile vendors (food trucks, mobile services, etc.)
    if (!widget.isMobileVendor) {
      return const SizedBox.shrink();
    }

    if (widget.isActive && widget.currentLocation != null) {
      return _buildActiveBeacon();
    }
    return _buildInactiveBeacon();
  }

  Widget _buildActiveBeacon() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).success,
          width: 2.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚐 Location Beacon Active',
                        style: FlutterFlowTheme.of(context)
                            .titleSmall
                            .override(
                              font: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                              ),
                              color: FlutterFlowTheme.of(context).success,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        widget.currentLocation ?? '',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.plusJakartaSans(),
                              color: FlutterFlowTheme.of(context).primaryText,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).success,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    widget.expiresAt != null
                        ? _formatTimeUntilExpiry(widget.expiresAt!)
                        : 'Active',
                    style: FlutterFlowTheme.of(context).labelSmall.override(
                          font: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                          ),
                          color: Colors.white,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            SizedBox(
              width: double.infinity,
              child: FFButtonWidget(
                onPressed: _isStopping ? null : () => _stopBeacon(),
                text: _isStopping ? 'Stopping...' : 'Stop Broadcasting',
                options: FFButtonOptions(
                  height: 44.0,
                  color: FlutterFlowTheme.of(context).error,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        font: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                        ),
                        color: Colors.white,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                      ),
                  elevation: 0.0,
                  borderRadius: BorderRadius.circular(8.0),
                  disabledColor: FlutterFlowTheme.of(context).alternate,
                  disabledTextColor: FlutterFlowTheme.of(context).secondaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInactiveBeacon() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🚐 Location Beacon',
              style: FlutterFlowTheme.of(context).titleSmall.override(
                    font: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                    ),
                    color: FlutterFlowTheme.of(context).primaryText,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Let customers find you today',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    font: GoogleFonts.plusJakartaSans(),
                    color: FlutterFlowTheme.of(context).secondaryText,
                    letterSpacing: 0.0,
                  ),
            ),
            const SizedBox(height: 12.0),
            Text(
              'Broadcast your location with a live beacon. Customers see you on the map and in the feed.',
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    font: GoogleFonts.plusJakartaSans(),
                    color: FlutterFlowTheme.of(context).secondaryText,
                    letterSpacing: 0.0,
                    lineHeight: 1.4,
                  ),
            ),
            const SizedBox(height: 16.0),
            SizedBox(
              width: double.infinity,
              child: FFButtonWidget(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => LocationBeaconModalWidget(
                      businessRef: widget.businessRef,
                      businessName: widget.businessName,
                    ),
                  );
                },
                text: 'Start Broadcasting',
                options: FFButtonOptions(
                  height: 44.0,
                  color: FlutterFlowTheme.of(context).primary,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        font: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                        ),
                        color: FlutterFlowTheme.of(context).info,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                      ),
                  elevation: 0.0,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
