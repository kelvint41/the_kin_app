import '/components/feature_item_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  State<TierCardWidget> createState() => _TierCardWidgetState();
}

class _TierCardWidgetState extends State<TierCardWidget> {
  late TierCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TierCardModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
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
                      widget.isElite,
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
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                                    widget.title,
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
                                        color: widget.isElite
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
                                    color: widget.isElite
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
                                          widget.badgeLabel,
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
                                              color: widget.isElite
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
                              widget.isPro,
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
                                widget.price,
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
                                iconColor: widget.isElite
                                    ? Color(0xFFD4AF37)
                                    : FlutterFlowTheme.of(context).primary,
                                benefit: valueOrDefault<String>(
                                  widget.f1,
                                  'Access to public community forums',
                                ),
                              ),
                            ),
                            wrapWithModel(
                              model: _model.featureItemModel2,
                              updateCallback: () => safeSetState(() {}),
                              child: FeatureItemWidget(
                                iconColor: widget.isElite
                                    ? Color(0xFFD4AF37)
                                    : FlutterFlowTheme.of(context).primary,
                                benefit: valueOrDefault<String>(
                                  widget.f2,
                                  'Basic business profile page on local directory',
                                ),
                              ),
                            ),
                            wrapWithModel(
                              model: _model.featureItemModel3,
                              updateCallback: () => safeSetState(() {}),
                              child: FeatureItemWidget(
                                iconColor: widget.isElite
                                    ? Color(0xFFD4AF37)
                                    : FlutterFlowTheme.of(context).primary,
                                benefit: valueOrDefault<String>(
                                  widget.f3,
                                  'Up to 3 active local connections',
                                ),
                              ),
                            ),
                            wrapWithModel(
                              model: _model.featureItemModel4,
                              updateCallback: () => safeSetState(() {}),
                              child: FeatureItemWidget(
                                iconColor: widget.isElite
                                    ? Color(0xFFD4AF37)
                                    : FlutterFlowTheme.of(context).primary,
                                benefit: valueOrDefault<String>(
                                  widget.f4,
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
