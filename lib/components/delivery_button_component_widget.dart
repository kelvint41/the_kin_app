import '/backend/backend.dart';
import '/components/clean_elegant_mobile_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'delivery_button_component_model.dart';
export 'delivery_button_component_model.dart';

class DeliveryButtonComponentWidget extends StatefulWidget {
  const DeliveryButtonComponentWidget({
    super.key,
    required this.businessDoc,
  });

  final BusinessesRecord? businessDoc;

  @override
  State<DeliveryButtonComponentWidget> createState() =>
      _DeliveryButtonComponentWidgetState();
}

class _DeliveryButtonComponentWidgetState
    extends State<DeliveryButtonComponentWidget> {
  late DeliveryButtonComponentModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DeliveryButtonComponentModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FFButtonWidget(
      onPressed: () async {
        await showModalBottomSheet(
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          enableDrag: false,
          context: context,
          builder: (context) {
            return Padding(
              padding: MediaQuery.viewInsetsOf(context),
              child: CleanElegantMobileWidget(
                businessDoc: widget!.businessDoc!,
              ),
            );
          },
        ).then((value) => safeSetState(() {}));
      },
      text: 'Delivery via The KIN App',
      options: FFButtonOptions(
        width: 100.0,
        height: 55.0,
        padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
        iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
        color: FlutterFlowTheme.of(context).primary,
        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
              font: GoogleFonts.plusJakartaSans(
                fontWeight: FlutterFlowTheme.of(context).titleSmall.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
              ),
              color: FlutterFlowTheme.of(context).primaryText,
              letterSpacing: 0.0,
              fontWeight: FlutterFlowTheme.of(context).titleSmall.fontWeight,
              fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
            ),
        elevation: 0.0,
        borderRadius: BorderRadius.circular(24.0),
      ),
    );
  }
}
