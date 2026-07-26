import '/components/business_image_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'business_preview_card_model.dart';
export 'business_preview_card_model.dart';

class BusinessPreviewCardWidget extends StatefulWidget {
  const BusinessPreviewCardWidget({
    super.key,
    String? name,
    bool? isPriority,
    String? category,
    String? rating,
    this.distance,
    this.imageUrl,
  })  : this.name = name ?? 'Harlem Coffee Co.',
        this.isPriority = isPriority ?? true,
        this.category = category ?? 'Cafe & Bakery',
        this.rating = rating ?? '4.9';

  final String name;
  final bool isPriority;
  final String category;
  final String rating;

  /// Null when no real distance is known. The app has no user-location
  /// plumbing or distance helper yet, so callers can't compute one -
  /// rendering a placeholder like '0.2 mi' would be inventing data, and
  /// the previous caller passed a raw LatLng here, which blew the row's
  /// width out. Null hides the field entirely instead.
  final String? distance;

  /// Business hero photo. Null/empty/unloadable falls back to the KIN
  /// logo via [BusinessImage].
  final String? imageUrl;

  @override
  State<BusinessPreviewCardWidget> createState() =>
      _BusinessPreviewCardWidgetState();
}

class _BusinessPreviewCardWidgetState extends State<BusinessPreviewCardWidget> {
  late BusinessPreviewCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BusinessPreviewCardModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300.0,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(24.0),
        shape: BoxShape.rectangle,
        border: Border.all(
          color: valueOrDefault<Color>(
            valueOrDefault<bool>(
              widget!.isPriority,
              true,
            )
                ? FlutterFlowTheme.of(context).tertiary
                : FlutterFlowTheme.of(context).alternate,
            FlutterFlowTheme.of(context).tertiary,
          ),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Container(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14.0),
                child: Container(
                  width: 64.0,
                  height: 64.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    borderRadius: BorderRadius.circular(14.0),
                    shape: BoxShape.rectangle,
                  ),
                  child: BusinessImage(
                    imageUrl: widget.imageUrl,
                    width: 64.0,
                    height: 64.0,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Flexible so the ellipsis actually applies: a Text
                        // directly in a Row gets unbounded width, which makes
                        // `overflow: ellipsis` a no-op and lets a long
                        // business name overflow the card horizontally.
                        Flexible(
                          child: Text(
                            valueOrDefault<String>(
                              widget!.name,
                              'Harlem Coffee Co.',
                            ),
                            maxLines: 1,
                            style: FlutterFlowTheme.of(context)
                                .titleSmall
                                .override(
                                font: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                                color: FlutterFlowTheme.of(context).primaryText,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontStyle,
                              ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (valueOrDefault<bool>(
                          widget!.isPriority,
                          true,
                        ))
                          Icon(
                            Icons.verified_rounded,
                            color: FlutterFlowTheme.of(context).tertiary,
                            size: 14.0,
                          ),
                      ].divide(SizedBox(width: 4.0)),
                    ),
                    Text(
                      valueOrDefault<String>(
                        widget!.category,
                        'Cafe & Bakery',
                      ),
                      style: FlutterFlowTheme.of(context).labelSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).tertiary,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontStyle,
                            lineHeight: 1.4,
                          ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: FlutterFlowTheme.of(context).warning,
                              size: 14.0,
                            ),
                            Text(
                              valueOrDefault<String>(
                                widget!.rating,
                                '4.9',
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .override(
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                    lineHeight: 1.4,
                                  ),
                            ),
                          ].divide(SizedBox(width: 4.0)),
                        ),
                        // Only rendered when a real distance is supplied -
                        // and Flexible so an unexpectedly long value
                        // truncates instead of overflowing the row.
                        if (widget.distance != null &&
                            widget.distance!.trim().isNotEmpty)
                          Flexible(
                            child: Text(
                              widget.distance!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .override(
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                    lineHeight: 1.4,
                                  ),
                            ),
                          ),
                      ].divide(SizedBox(width: 16.0)),
                    ),
                  ].divide(SizedBox(height: 4.0)),
                ),
              ),
            ].divide(SizedBox(width: 16.0)),
          ),
        ),
      ),
    );
  }
}
