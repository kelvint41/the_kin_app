import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'card_draft_page_model.dart';
export 'card_draft_page_model.dart';

/// "Create a modern, premium horizontal business directory card for a mobile
/// app.
///
/// Structure:
///
/// A fixed-width Container (approx 300px wide, 200px high) with 24px rounded
/// corners and a subtle drop shadow.
///
/// The background should be a high-quality placeholder image of a storefront
/// or product with a dark gradient overlay at the bottom for text
/// readability.
///
/// Content Elements:
///
/// Top Left: A small, pill-shaped badge with a gold or vibrant orange
/// background that says 'KIN Verified' in white bold text.
///
/// Bottom Left: The Business Name in white, 22px bold Montserrat or similar
/// sans-serif font.
///
/// Below Name: A smaller Category Tag (e.g., 'Soul Food' or 'Tech Hub') in
/// light grey or semi-transparent white.
///
/// Style:
///
/// The aesthetic should be 'San Antonio Modern'—vibrant, warm, and
/// professional.
///
/// Ensure the layout is clean with at least 16px of padding from the edges.
/// No cluttered borders."
class CardDraftPageWidget extends StatefulWidget {
  const CardDraftPageWidget({super.key});

  static String routeName = 'CardDraftPage';
  static String routePath = '/cardDraftPage';

  @override
  State<CardDraftPageWidget> createState() => _CardDraftPageWidgetState();
}

class _CardDraftPageWidgetState extends State<CardDraftPageWidget> {
  late CardDraftPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CardDraftPageModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Color(0xFF1A1A2E),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [],
          ),
        ),
      ),
    );
  }
}
