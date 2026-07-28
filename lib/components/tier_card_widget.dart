import '/components/feature_item_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'tier_card_model.dart';
export 'tier_card_model.dart';

class TierCardWidget extends StatefulWidget {
  const TierCardWidget({
    super.key,
    bool? isPro,
    bool? isElite,
    String? title,
    String? badgeLabel,
    String? price,
    String? f1,
    String? f2,
    String? f3,
    String? f4,
    this.beaconText,
  })  : this.isPro = isPro ?? false,
        this.isElite = isElite ?? false,
        this.title = title ?? 'Community',
        this.badgeLabel = badgeLabel ?? 'Free Community Tier',
        this.price = price ?? '\$0',
        this.f1 = f1 ?? 'Access to public community forums',
        this.f2 = f2 ?? 'Basic business profile page on local directory',
        this.f3 = f3 ?? 'Up to 3 active local connections',
        this.f4 = f4 ?? 'Basic community support';

  final bool isPro;
  final bool isElite;
  final String title;
  final String badgeLabel;
  final String price;
  final String f1;
  final String f2;
  final String f3;
  final String f4;

  /// Text shown on a small pulsing "beacon" badge at the card's top-left
  /// corner (e.g. 'Free' or 'Upgrade'). Null hides the beacon entirely.
  final String? beaconText;

  @override
  State<TierCardWidget> createState() => _TierCardWidgetState();
}

class _TierCardWidgetState extends State<TierCardWidget>
    with SingleTickerProviderStateMixin {
  late TierCardModel _model;
  late AnimationController _beaconController;
  late Animation<double> _beaconOpacity;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TierCardModel());
    _beaconController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _beaconOpacity = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _beaconController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _beaconController.dispose();
    _model.maybeDispose();

    super.dispose();
  }

  Widget _buildBeacon(BuildContext context) {
    final isFree = widget!.beaconText == 'Free';
    return FadeTransition(
      opacity: _beaconOpacity,
      child: Container(
        padding: EdgeInsetsDirectional.fromSTEB(10.0, 5.0, 10.0, 5.0),
        decoration: BoxDecoration(
          color:
              isFree ? FlutterFlowTheme.of(context).success : Color(0xFFD4AF37),
          borderRadius: BorderRadius.circular(9999.0),
          boxShadow: [
            BoxShadow(
              color: (isFree
                      ? FlutterFlowTheme.of(context).success
                      : Color(0xFFD4AF37))
                  .withOpacity(0.6),
              blurRadius: 8.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6.0,
              height: 6.0,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6.0),
            Text(
              widget!.beaconText!,
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    font: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                    ),
                    color: Colors.black,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
      child: Container(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: Container(
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(24.0),
              shape: BoxShape.rectangle,
              border: Border.all(
                color: Colors.transparent,
                width: 0.0,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Container(
                child: Stack(
                  alignment: AlignmentDirectional(-1.0, -1.0),
                  children: [
                    if (valueOrDefault<bool>(
                      widget!.isElite,
                      false,
                    ))
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
                            stops: [0.0, 1.0],
                            begin: AlignmentDirectional(1.0, 1.0),
                            end: AlignmentDirectional(-1.0, -1.0),
                          ),
                          shape: BoxShape.rectangle,
                        ),
                      ),
                    // The badge used to be PositionedDirectional(top: -8,
                    // start: -8) - anchored outside the card's own bounds at
                    // the top-left, which put it directly on top of the tier
                    // name. "Upgrade" sat across "Founding Local" and "Free"
                    // across "Community".
                    //
                    // It now sits in the layout above the title rather than
                    // floating over it, so it can never collide no matter how
                    // long a tier name gets, and it is aligned to the start so
                    // it reads as a label for the card rather than a sticker
                    // on the corner.
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget!.beaconText != null)
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 12.0),
                            child: Align(
                              alignment: AlignmentDirectional(-1.0, 0.0),
                              child: _buildBeacon(context),
                            ),
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  valueOrDefault<String>(
                                    widget!.title,
                                    'Community',
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .titleLarge
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleLarge
                                                  .fontStyle,
                                        ),
                                        color: widget!.isElite
                                            ? Color(0xFFD4AF37)
                                            : FlutterFlowTheme.of(context)
                                                .primaryText,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleLarge
                                            .fontStyle,
                                        lineHeight: 1.4,
                                      ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: widget!.isElite
                                        ? Color(0x33D4AF37)
                                        : Color(0x00000000),
                                    borderRadius: BorderRadius.circular(9999.0),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        16.0, 4.0, 16.0, 4.0),
                                    child: Container(
                                      child: Text(
                                        valueOrDefault<String>(
                                          widget!.badgeLabel,
                                          'Free Community Tier',
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .override(
                                              font: GoogleFonts.plusJakartaSans(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .labelSmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelSmall
                                                        .fontStyle,
                                              ),
                                              color: widget!.isElite
                                                  ? Color(0xFFD4AF37)
                                                  : FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontStyle,
                                              lineHeight: 1.4,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ].divide(SizedBox(height: 4.0)),
                            ),
                            if (valueOrDefault<bool>(
                              widget!.isPro,
                              false,
                            ))
                              Container(
                                decoration: BoxDecoration(
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  borderRadius: BorderRadius.circular(9999.0),
                                  shape: BoxShape.rectangle,
                                ),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      8.0, 4.0, 8.0, 4.0),
                                  child: Container(
                                    child: Text(
                                      'POPULAR',
                                      style: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .override(
                                            font: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.bold,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontStyle,
                                            ),
                                            color: Colors.black,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelSmall
                                                    .fontStyle,
                                            lineHeight: 1.4,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              valueOrDefault<String>(
                                widget!.price,
                                '\$0',
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .headlineMedium
                                  .override(
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .headlineMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w800,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .headlineMedium
                                        .fontStyle,
                                    lineHeight: 1.4,
                                  ),
                            ),
                            Text(
                              '/ Month',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    font: GoogleFonts.playfairDisplay(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .fontStyle,
                                    lineHeight: 1.4,
                                  ),
                            ),
                          ].divide(SizedBox(width: 4.0)),
                        ),
                        Divider(
                          height: 16.0,
                          thickness: 1.0,
                          indent: 0.0,
                          endIndent: 0.0,
                          color: FlutterFlowTheme.of(context).alternate,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            wrapWithModel(
                              model: _model.featureItemModel1,
                              updateCallback: () => safeSetState(() {}),
                              child: FeatureItemWidget(
                                iconColor: widget!.isElite
                                    ? Color(0xFFD4AF37)
                                    : FlutterFlowTheme.of(context).primary,
                                benefit: valueOrDefault<String>(
                                  widget!.f1,
                                  'Access to public community forums',
                                ),
                              ),
                            ),
                            wrapWithModel(
                              model: _model.featureItemModel2,
                              updateCallback: () => safeSetState(() {}),
                              child: FeatureItemWidget(
                                iconColor: widget!.isElite
                                    ? Color(0xFFD4AF37)
                                    : FlutterFlowTheme.of(context).primary,
                                benefit: valueOrDefault<String>(
                                  widget!.f2,
                                  'Basic business profile page on local directory',
                                ),
                              ),
                            ),
                            wrapWithModel(
                              model: _model.featureItemModel3,
                              updateCallback: () => safeSetState(() {}),
                              child: FeatureItemWidget(
                                iconColor: widget!.isElite
                                    ? Color(0xFFD4AF37)
                                    : FlutterFlowTheme.of(context).primary,
                                benefit: valueOrDefault<String>(
                                  widget!.f3,
                                  'Up to 3 active local connections',
                                ),
                              ),
                            ),
                            wrapWithModel(
                              model: _model.featureItemModel4,
                              updateCallback: () => safeSetState(() {}),
                              child: FeatureItemWidget(
                                iconColor: widget!.isElite
                                    ? Color(0xFFD4AF37)
                                    : FlutterFlowTheme.of(context).primary,
                                benefit: valueOrDefault<String>(
                                  widget!.f4,
                                  'Basic community support',
                                ),
                              ),
                            ),
                          ].divide(SizedBox(height: 8.0)),
                        ),
                      ].divide(SizedBox(height: 16.0)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
