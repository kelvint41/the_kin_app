import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'kin_bottom_nav2_model.dart';
export 'kin_bottom_nav2_model.dart';

class KinBottomNav2Widget extends StatefulWidget {
  const KinBottomNav2Widget({super.key, this.activeTab = 'map'});

  /// Which tab to render as active ('map' or 'profile'). Lets the shared
  /// bottom bar highlight the correct tab on whichever screen displays it.
  final String activeTab;

  @override
  State<KinBottomNav2Widget> createState() => _KinBottomNav2WidgetState();
}

class _KinBottomNav2WidgetState extends State<KinBottomNav2Widget> {
  late KinBottomNav2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => KinBottomNav2Model());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapColor = widget.activeTab == 'map'
        ? FlutterFlowTheme.of(context).primary
        : FlutterFlowTheme.of(context).secondaryText;
    final profileColor = widget.activeTab == 'profile'
        ? FlutterFlowTheme.of(context).primary
        : FlutterFlowTheme.of(context).secondaryText;
    return Container(
      height: 90.0,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
            FlutterFlowTheme.of(context).designToken.spacing.lg,
            0.0,
            FlutterFlowTheme.of(context).designToken.spacing.lg,
            0.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // V1 MVP bottom bar: Map + Profile. The map page already includes
            // the business directory/list, so a separate Directory tab would
            // be redundant. The community tabs (Feed, Loyalty) below stay in
            // the code, gated off for a V2 reintroduction.
            Expanded(
              flex: 1,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  print('KinBottomNav2Widget: Map tab tapped');
                  context.pushNamed(GoogleMapPageWidget.routeName);
                },
                child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_rounded,
                    color: mapColor,
                    size: 24.0,
                  ),
                  Text(
                    'Map',
                    style: FlutterFlowTheme.of(context).labelSmall.override(
                          font: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontStyle,
                          ),
                          color: mapColor,
                          fontSize: 10.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelSmall.fontStyle,
                          lineHeight: 1.2,
                        ),
                  ),
                ].divide(SizedBox(
                    height:
                        FlutterFlowTheme.of(context).designToken.spacing.xs)),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  print('KinBottomNav2Widget: Profile tab tapped');
                  context.pushNamed(CustomerProfilePageWidget.routeName);
                },
                child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_rounded,
                    color: profileColor,
                    size: 24.0,
                  ),
                  Text(
                    'Profile',
                    style: FlutterFlowTheme.of(context).labelSmall.override(
                          font: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontStyle,
                          ),
                          color: profileColor,
                          fontSize: 10.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelSmall.fontStyle,
                          lineHeight: 1.2,
                        ),
                  ),
                ].divide(SizedBox(
                    height:
                        FlutterFlowTheme.of(context).designToken.spacing.xs)),
                ),
              ),
            ),
            if (FFAppConstants.communityFeaturesEnabled)
              Expanded(
              flex: 1,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  print('KinBottomNav2Widget: Feed tab tapped');
                  final businesses = await queryBusinessesRecordOnce(limit: 1);
                  final businessRef = businesses.firstOrNull?.reference;
                  if (businessRef == null || !context.mounted) {
                    print(
                        'KinBottomNav2Widget: no business available to open Feed');
                    return;
                  }
                  context.pushNamed(
                    TheExchangeWidget.routeName,
                    queryParameters: {
                      'businessRef': serializeParam(
                        businessRef,
                        ParamType.DocumentReference,
                      ),
                    }.withoutNulls,
                  );
                },
                child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.forum_rounded,
                    color: FlutterFlowTheme.of(context).secondaryText,
                    size: 24.0,
                  ),
                  Text(
                    'Feed',
                    style: FlutterFlowTheme.of(context).labelSmall.override(
                          font: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).secondaryText,
                          fontSize: 10.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelSmall.fontStyle,
                          lineHeight: 1.2,
                        ),
                  ),
                ].divide(SizedBox(
                    height:
                        FlutterFlowTheme.of(context).designToken.spacing.xs)),
                ),
              ),
            ),
            if (FFAppConstants.communityFeaturesEnabled)
              Expanded(
              flex: 1,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  print('KinBottomNav2Widget: Loyalty tab tapped');
                  context.pushNamed(CommunityPrestigeWidget.routeName);
                },
                child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: FlutterFlowTheme.of(context).secondaryText,
                    size: 24.0,
                  ),
                  Text(
                    'Loyalty',
                    style: FlutterFlowTheme.of(context).labelSmall.override(
                          font: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).secondaryText,
                          fontSize: 10.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelSmall.fontStyle,
                          lineHeight: 1.2,
                        ),
                  ),
                ].divide(SizedBox(
                    height:
                        FlutterFlowTheme.of(context).designToken.spacing.xs)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
