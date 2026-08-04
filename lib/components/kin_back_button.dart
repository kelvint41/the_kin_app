import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

/// The app's one back-arrow treatment: a 44x44 circular ring in the brand
/// primary color around a rounded arrow icon. Screens had drifted into five
/// different back controls (a 60px version, a bare default AppBar arrow, a
/// close "X", and three screens with no back control at all) - this is the
/// single component all of them now share.
///
/// Defaults to [context.safePop] like every existing back button in the
/// app; pass [onPressed] only when a screen needs different behavior first
/// (e.g. a confirm dialog).
///
/// [floating] switches to an opaque white circle - the same recipe
/// [MainMenuButton] already uses - for screens where the button sits over a
/// hero photo with a transparent AppBar rather than a flat themed
/// background. The primary-colored ring in the default style would be
/// invisible against a solid-primary AppBar, and unreliable in contrast
/// against arbitrary photo content.
class KinBackButton extends StatelessWidget {
  const KinBackButton({super.key, this.onPressed, this.floating = false});

  final VoidCallback? onPressed;
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: floating ? 48.0 : 44.0,
      height: floating ? 48.0 : 44.0,
      decoration: BoxDecoration(
        color: floating ? Color(0xE6FFFFFF) : null,
        borderRadius: BorderRadius.circular(9999.0),
        shape: BoxShape.rectangle,
        border: Border.all(
          color: floating ? theme.alternate : theme.primary,
          width: floating ? 1.0 : 2.0,
        ),
      ),
      alignment: AlignmentDirectional(0.0, 0.0),
      child: FlutterFlowIconButton(
        borderRadius: 8.0,
        buttonSize: 40.0,
        fillColor: Colors.transparent,
        icon: Icon(
          Icons.arrow_back_rounded,
          color: floating ? theme.primaryText : theme.secondaryText,
          size: 24.0,
        ),
        onPressed: onPressed ?? () => context.safePop(),
      ),
    );
  }
}
