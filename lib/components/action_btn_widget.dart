import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'action_btn_model.dart';
export 'action_btn_model.dart';

class ActionBtnWidget extends StatefulWidget {
  const ActionBtnWidget({
    super.key,
    this.icon,
    String? label,
  }) : this.label = label ?? 'Edit Profile';

  final Widget? icon;
  final String label;

  @override
  State<ActionBtnWidget> createState() => _ActionBtnWidgetState();
}

class _ActionBtnWidgetState extends State<ActionBtnWidget> {
  late ActionBtnModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ActionBtnModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  /// The circle below is a hardcoded dark disc in BOTH themes (it's the
  /// brand look - dark puck, gold rim), so whatever sits inside it has to be
  /// a light colour in both themes too. Callers were passing
  /// `theme.primaryText`, which is bright gold in dark mode but a deep
  /// brown-gold (0xFF7D5F16) in light mode - invisible on a 0xFF242424 disc.
  /// That's why all four icons vanished in light mode and only light mode.
  ///
  /// Enforced here rather than at the call sites: the surface is this
  /// widget's, so the contrast against it should be this widget's problem.
  /// Fixing the four callers instead would leave the next one free to
  /// reintroduce the same bug.
  static const Color _onDarkDisc = Color(0xFFD4AF37);

  /// Re-colours whatever icon the caller passed. Rebuilds an [Icon] with the
  /// enforced colour (an explicit `color:` on the caller's Icon would
  /// otherwise win over an ambient IconTheme), and falls back to IconTheme
  /// for any other widget.
  Widget _iconOnDisc() {
    final provided = widget!.icon;
    if (provided is Icon) {
      return Icon(
        provided.icon,
        size: provided.size ?? 24.0,
        color: _onDarkDisc,
        semanticLabel: provided.semanticLabel,
      );
    }
    return IconTheme(
      data: const IconThemeData(color: _onDarkDisc, size: 24.0),
      child: provided ?? const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56.0,
          height: 56.0,
          decoration: BoxDecoration(
            color: Color(0xFF242424),
            borderRadius: BorderRadius.circular(9999.0),
            shape: BoxShape.rectangle,
            border: Border.all(
              color: Color(0x4DD4AF37),
              width: 1.0,
            ),
          ),
          alignment: AlignmentDirectional(0.0, 0.0),
          child: _iconOnDisc(),
        ),
        Text(
          valueOrDefault<String>(
            widget!.label,
            'Edit Profile',
          ),
          style: FlutterFlowTheme.of(context).labelSmall.override(
                font: GoogleFonts.plusJakartaSans(
                  fontWeight:
                      FlutterFlowTheme.of(context).labelSmall.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                ),
                // The label sits OUTSIDE the dark disc, on the card's
                // secondaryBackground - which is near-white in light mode, so
                // a hardcoded Colors.white made it invisible there too. Same
                // bug as the icons, one widget over; theme-aware because this
                // text is on a theme-aware surface, unlike the disc.
                color: FlutterFlowTheme.of(context).primaryText,
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                lineHeight: 1.4,
              ),
        ),
      ].divide(SizedBox(height: 4.0)),
    );
  }
}
