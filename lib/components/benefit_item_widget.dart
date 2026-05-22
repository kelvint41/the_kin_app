import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'benefit_item_model.dart';
export 'benefit_item_model.dart';

class BenefitItemWidget extends StatefulWidget {
  const BenefitItemWidget({
    super.key,
    this.label,
  });

  final String? label;

  @override
  State<BenefitItemWidget> createState() => _BenefitItemWidgetState();
}

class _BenefitItemWidgetState extends State<BenefitItemWidget> {
  late BenefitItemModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BenefitItemModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
          0.0, 0.0, 0.0, FlutterFlowTheme.of(context).designToken.spacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 24.0,
            height: 24.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                  FlutterFlowTheme.of(context).designToken.radius.full),
            ),
            alignment: AlignmentDirectional(0.0, 0.0),
            child: Icon(
              Icons.check_rounded,
              color: FlutterFlowTheme.of(context).primaryBackground,
              size: 16.0,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              valueOrDefault<String>(
                widget!.label,
                'Top Search Results',
              ),
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w500,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).primaryBackground,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w500,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
            ),
          ),
        ].divide(SizedBox(
            width: FlutterFlowTheme.of(context).designToken.spacing.md)),
      ),
    );
  }
}
