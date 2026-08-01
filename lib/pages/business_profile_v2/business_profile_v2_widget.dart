import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/services/kin_services.dart';
import '/components/action_btn_widget.dart';
import '/components/ai_marketing_sheet_widget.dart';
import '/components/business_image_widget.dart';
import '/components/kindex_trend_indicator.dart';
import '/components/visit_check_in_widget.dart';
import '/components/clean_elegant_mobile_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'business_profile_v2_model.dart';
export 'business_profile_v2_model.dart';

// There's no dedicated boolean for this yet - BusinessesRecord.
// is_delivery_eligible exists in the schema but has no writer anywhere in
// the app today (confirmed via grep), so gating on it would hide "Order on
// KIN" for every business. `category` is the only populated signal: new
// businesses get one of 5 fixed values from business_setup_page's dropdown
// ('Restaurant & Food', 'Retail', etc.), but the 498 bulk-imported
// businesses carry free-text Google-Places-style categories instead (e.g.
// 'Barbecue restaurant', 'Bakery') - a keyword match covers both without a
// data migration. If is_delivery_eligible ever gets a real writer (e.g. a
// toggle next to the delivery URL fields in business_setup_page), that
// would be the more precise long-term signal to switch to.
/// Whether the Order sheet has anywhere to send the user.
///
/// This replaces a keyword match on `category` ('restaurant', 'bbq',
/// 'cafe', ...). Category answered "does this business plausibly sell
/// food", which is not the question: the sheet's three buttons launch
/// `doordash_url`, `ubereats_url` and `grubhub_url`, so a business that
/// sells food but gave us no delivery link still got an Order button, a
/// sheet, and three buttons that called launchURL('') and did nothing.
/// Every one of the 500 businesses currently has all three URLs empty, so
/// that was every food business in the directory.
///
/// Note this is deliberately not `is_delivery_eligible` either. That flag
/// is set on 10 businesses and says the business delivers somehow - by its
/// own driver, by phone order, however. It earns the "Offers delivery"
/// line on the profile. It does not mean we hold a link we can open, and
/// only a link we can open should produce a button.
bool _hasOrderingLinks(BusinessesRecord business) =>
    business.doordashUrl.isNotEmpty ||
    business.ubereatsUrl.isNotEmpty ||
    business.grubhubUrl.isNotEmpty;

/// "Create a professional business profile page for a directory.
///
/// Include a large header image at the top. Below the image, add the business
/// name in a large font, a 'Call Now' button, and an 'Open in Maps' button
/// side-by-side. Add a section for 'About the Business' with a long text
/// description and a grid of 4 smaller photos for a gallery. Use a clean,
/// modern design."
class BusinessProfileV2Widget extends StatefulWidget {
  const BusinessProfileV2Widget({
    super.key,
    required this.businessDocument,
  });

  final DocumentReference? businessDocument;

  static String routeName = 'BusinessProfile_V2';
  static String routePath = '/businessProfileV2';

  @override
  State<BusinessProfileV2Widget> createState() =>
      _BusinessProfileV2WidgetState();
}

class _BusinessProfileV2WidgetState extends State<BusinessProfileV2Widget> {
  late BusinessProfileV2Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  /// Guards against logging the same view twice.
  ///
  /// This page rebuilds on every snapshot tick of its business document, so
  /// logging from build would write a row per rebuild rather than per visit.
  bool _loggedView = false;

  /// One `profile_view` per visit, attributed to the business.
  ///
  /// No event of this kind existed. activity_logs recorded page views only
  /// for GoogleMapPage, so the most basic question an owner has - how many
  /// people looked at my business - had no data behind it at all.
  ///
  /// Best-effort and unawaited by the caller: a failed analytics write must
  /// never stop a profile rendering.
  void _logProfileView(BusinessesRecord business) {
    if (_loggedView) return;
    _loggedView = true;
    ActivityLogsRecord.collection.doc().set(createActivityLogsRecordData(
          eventType: 'profile_view',
          userRef: currentUserReference,
          businessRef: business.reference,
          city: business.city,
          category: business.category,
          pageName: 'BusinessProfileV2',
          sessionId: FFAppState().sessionId,
          timestamp: getCurrentTimestamp,
        ));
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BusinessProfileV2Model());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  /// Instagram / Facebook / TikTok / LinkedIn, when the business has them.
  ///
  /// All four URLs have been on the businesses schema all along and were
  /// rendered nowhere, so a business that gave us its Instagram had no way
  /// to send anyone there. Renders nothing when none are set, rather than a
  /// row of greyed-out icons implying the business is absent from
  /// platforms it may simply not have told us about.
  Widget _socialLinks(BuildContext context, BusinessesRecord business) {
    final links = <(IconData, String, String)>[
      (Icons.camera_alt_rounded, 'Instagram', business.instagramUrl),
      (Icons.facebook_rounded, 'Facebook', business.facebookUrl),
      (Icons.music_note_rounded, 'TikTok', business.tiktokUrl),
      (Icons.business_center_rounded, 'LinkedIn', business.linkedinUrl),
    ].where((l) => l.$3.isNotEmpty).toList();

    if (links.isEmpty) return SizedBox.shrink();

    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (icon, label, url) in links)
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 12.0, 0.0),
              child: Semantics(
                button: true,
                label: label,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.0),
                  onTap: () async => KinServices.launchBusinessLink(url),
                  child: Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: theme.accent1,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(icon, color: theme.primary, size: 22.0),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return StreamBuilder<BusinessesRecord>(
      stream: BusinessesRecord.getDocument(widget!.businessDocument!),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).secondaryText,
                  ),
                ),
              ),
            ),
          );
        }

        final businessProfileV2BusinessesRecord = snapshot.data!;
        _logProfileView(businessProfileV2BusinessesRecord);

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              leading: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                child: FlutterFlowIconButton(
                  borderColor: Colors.transparent,
                  borderRadius: 20.0,
                  borderWidth: 0.0,
                  buttonSize: 40.0,
                  fillColor: Color(0x33FFFFFF),
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20.0,
                  ),
                  onPressed: () {
                    context.safePop();
                  },
                ),
              ),
              actions: [],
              centerTitle: false,
              elevation: 0.0,
            ),
            body: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    width: double.infinity,
                    height: 280.0,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(0.0),
                          child: BusinessImage(
                            imageUrl:
                                businessProfileV2BusinessesRecord.heroImage,
                            width: double.infinity,
                            height: 280.0,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // The scrim used to sit AFTER the name in this Stack, so it painted
                        // over the title instead of behind it - the business name rendered
                        // dimmed to grey against a bright hero. It has to precede the text
                        // it is darkening.
                        Container(
                          width: double.infinity,
                          height: 280.0,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              // Was [transparent, 0xCC000000] - only the bottom darkened, so
                              // the white title sat on the light top half of
                              // the image in light mode and vanished. The scrim
                              // now covers the whole hero, because the text on
                              // it is white in both themes.
                              colors: [Color(0x66000000), Color(0xE6000000)],
                              stops: [0.0, 1.0],
                              begin: AlignmentDirectional(0.0, -1.0),
                              end: AlignmentDirectional(0, 1.0),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              20.0, 0.0, 20.0, 24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                valueOrDefault<String>(
                                  businessProfileV2BusinessesRecord
                                      .businessName,
                                  'Business',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: FlutterFlowTheme.of(context)
                                    .displaySmall
                                    .override(
                                      font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .displaySmall
                                            .fontStyle,
                                      ),
                                      color: Colors.white,
                                      fontSize: 30.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .displaySmall
                                          .fontStyle,
                                      lineHeight: 1.2,
                                    ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 4.0, 0.0, 0.0),
                                child: Text(
                                  [
                                    businessProfileV2BusinessesRecord.category,
                                    businessProfileV2BusinessesRecord.city,
                                  ]
                                      .where((part) => part.trim().isNotEmpty)
                                      .join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        fontSize: 14.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ),
                              // KIN's whole premise, and it was nowhere on
                              // the page. Driven by is_certified_black_owned,
                              // which only apply_bob_certification.js sets -
                              // never by the meaningless bulk-imported
                              // is_black_owned flag. Shows the certifying
                              // body and its date so the claim is auditable
                              // rather than asserted.
                              if (businessProfileV2BusinessesRecord
                                  .isCertifiedBlackOwned)
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 10.0, 0.0, 0.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xE60B3D2E),
                                      borderRadius: BorderRadius.circular(20.0),
                                      border: Border.all(
                                        color: Color(0xFFFFD700),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          10.0, 6.0, 12.0, 6.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.verified_rounded,
                                            color: Color(0xFFFFD700),
                                            size: 16.0,
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    6.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              'Certified Black-Owned',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .labelMedium
                                                  .override(
                                                    color: Color(0xFFFFD700),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              // Kindex score with its trajectory. The score
                              // is the app's core trust signal and appeared
                              // nowhere on the profile.
                              //
                              // The arrow is driven by kindex_velocity and
                              // shows only when that is non-zero. It is
                              // deliberately not derived from the score
                              // itself: business_kindex_engine.js declines to
                              // write a velocity precisely because a
                              // sign-based placeholder "would look more
                              // meaningful than it is", and inventing a
                              // direction here would be the same mistake one
                              // layer up. No velocity yet means no arrow, not
                              // a guessed one.
                              if (businessProfileV2BusinessesRecord
                                  .hasKindexScore())
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 10.0, 0.0, 0.0),
                                  child: Align(
                                    alignment: AlignmentDirectional(-1.0, 0.0),
                                    child: KindexScoreBadge(
                                      score: businessProfileV2BusinessesRecord
                                          .kindexScore,
                                      velocity:
                                          businessProfileV2BusinessesRecord
                                              .kindexVelocity,
                                    ),
                                  ),
                                ),
                              if (businessProfileV2BusinessesRecord
                                      .isCertifiedBlackOwned &&
                                  businessProfileV2BusinessesRecord
                                      .certificationSource.isNotEmpty)
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 6.0, 0.0, 0.0),
                                  child: Text(
                                    [
                                      businessProfileV2BusinessesRecord
                                          .certificationSource,
                                      businessProfileV2BusinessesRecord
                                          .certificationAsOf,
                                    ]
                                        .where((p) => p.trim().isNotEmpty)
                                        .join(' · '),
                                    maxLines: 2,
                                    style: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .override(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // The row had no SafeArea and zero top padding, so
                        // both buttons sat directly under the status bar and
                        // the notch, where iOS consumes the touches before
                        // Flutter sees them - the same thing that made
                        // GoogleMapPage's menu button look dead. They were
                        // unreachable regardless of their handlers, and the
                        // handlers were FlutterFlow's `print(...)` stubs
                        // anyway, so nothing happened either way.
                        Align(
                          alignment: AlignmentDirectional(1.0, -1.0),
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 8.0, 16.0, 16.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  FlutterFlowIconButton(
                                    borderColor: Colors.transparent,
                                    borderRadius: 20.0,
                                    borderWidth: 0.0,
                                    buttonSize: 40.0,
                                    fillColor: Color(0x33FFFFFF),
                                    icon: Icon(
                                      Icons.share_rounded,
                                      color: Colors.white,
                                      size: 20.0,
                                    ),
                                    onPressed: () async {
                                      final business =
                                          businessProfileV2BusinessesRecord;
                                      // sharePositionOrigin is required on
                                      // iPad, where the share sheet is a
                                      // popover that must be anchored to the
                                      // control that opened it or UIKit
                                      // throws.
                                      final box = context.findRenderObject()
                                          as RenderBox?;
                                      await KinServices.shareApp(
                                        text: business.website.isNotEmpty
                                            ? '${business.businessName} on KIN - '
                                                '${business.website}'
                                            : '${business.businessName} on KIN',
                                        sharePositionOrigin: box == null
                                            ? null
                                            : box.localToGlobal(Offset.zero) &
                                                box.size,
                                        businessRef: business.reference,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Removed: a 100x100 Container filled with
                        // secondaryBackground, sitting in this Stack with no
                        // Positioned or Align around it. A Stack defaults its
                        // unpositioned children to the top-left corner, so it
                        // painted a blank square over the hero image - white
                        // in light mode, grey in dark - across the start of
                        // the business name. Empty FlutterFlow scaffolding
                        // that was never given a purpose.
                      ],
                    ),
                  ),
                  if (businessProfileV2BusinessesRecord.hasFlashBeacon)
                    Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      height: 60.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primary,
                      ),
                      child: Text(
                        '⚡ Live Power Hour Blast Active!',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.plusJakartaSans(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                      ),
                    ),
                  // isBusinessOpen() correctly returns false when hours are missing, but
                  // the pill then asserted "Closed" in red - and opening_time and
                  // closing_time are empty on all 498 businesses, so every listing was
                  // telling shoppers it was shut. Not knowing the hours is not the same
                  // as being closed, so the pill only appears once hours exist.
                  if (businessProfileV2BusinessesRecord
                          .openingTime.isNotEmpty &&
                      businessProfileV2BusinessesRecord.closingTime.isNotEmpty)
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 8.0),
                      child: Container(
                        height: 28.0,
                        decoration: BoxDecoration(
                          color: functions.isBusinessOpen(
                                  businessProfileV2BusinessesRecord.openingTime,
                                  businessProfileV2BusinessesRecord.closingTime)
                              ? FlutterFlowTheme.of(context).primary
                              : FlutterFlowTheme.of(context).error,
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              10.0, 0.0, 10.0, 0.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                color: Colors.white,
                                size: 14.0,
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    6.0, 0.0, 6.0, 0.0),
                                child: Text(
                                  functions.isBusinessOpen(
                                          businessProfileV2BusinessesRecord
                                              .openingTime,
                                          businessProfileV2BusinessesRecord
                                              .closingTime)
                                      ? 'Open Now'
                                      : 'Closed',
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        font: GoogleFonts.playfairDisplay(
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontStyle,
                                        ),
                                        color: Colors.white,
                                        fontSize: 12.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(20.0, 24.0, 20.0, 0.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 1.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 8.0, 0.0),
                                child: FFButtonWidget(
                                  onPressed: () async {
                                    await launchMap(
                                      address: businessProfileV2BusinessesRecord
                                          .address,
                                      title: businessProfileV2BusinessesRecord
                                          .businessName,
                                    );

                                    await ActivityLogsRecord.collection
                                        .doc()
                                        .set(createActivityLogsRecordData(
                                          eventType: 'map_tap',
                                          userRef: currentUserReference,
                                          // activity_logs has carried a
                                          // business_ref field all along and
                                          // nothing ever set it, so a tap
                                          // recorded that *someone* wanted
                                          // directions somewhere without
                                          // recording where. An owner could
                                          // never be shown their own numbers.
                                          businessRef:
                                              businessProfileV2BusinessesRecord
                                                  .reference,
                                          // Was hardcoded to 'San Antonio',
                                          // which mislabelled every map_tap
                                          // outside it. The directory now
                                          // spans El Paso, Lubbock, Houston
                                          // and Dallas, so that would have
                                          // skewed the whole city breakdown.
                                          city:
                                              businessProfileV2BusinessesRecord
                                                  .city,
                                          sessionId: FFAppState().sessionId,
                                          timestamp: getCurrentTimestamp,
                                        ));
                                  },
                                  text: 'Directions',
                                  icon: Icon(
                                    Icons.location_on_rounded,
                                    size: 18.0,
                                  ),
                                  options: FFButtonOptions(
                                    height: 48.0,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        6.0, 0.0, 6.0, 0.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    iconColor:
                                        FlutterFlowTheme.of(context).primary,
                                    // accent1, the brand gold, in both
                                    // themes. This was secondaryText - a
                                    // *text* token used as a fill, which is
                                    // gold in dark mode and near-black in
                                    // light, so these buttons rendered dark
                                    // green on black and were unreadable.
                                    color: FlutterFlowTheme.of(context)
                                        .accent1,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                      font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontStyle,
                                      ),
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      fontSize: 13.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,

                                    ),
                                    elevation: 0.0,
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .accent1,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                              ),
                            ),
                            // Call. 479 of the 500 businesses carry a phone
                            // number and there was no way to ring any of
                            // them - for a directory of local services,
                            // that is the single most likely thing a
                            // customer wants to do. `call_tap` was already
                            // an event type in activity_logs with one row
                            // against it, logged from somewhere that no
                            // longer exists.
                            //
                            // Hidden rather than disabled when there's no
                            // number, so the row stays even-width for the
                            // 21 businesses without one.
                            if (businessProfileV2BusinessesRecord
                                .phoneNumber.isNotEmpty)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 8.0, 0.0),
                                  child: FFButtonWidget(
                                    onPressed: () async {
                                      final number =
                                          businessProfileV2BusinessesRecord
                                              .phoneNumber;
                                      // launchURL throws when nothing can
                                      // handle the scheme, and `tel:` has no
                                      // handler on the iOS Simulator, an
                                      // iPad without cellular, or a desktop
                                      // build. Unhandled, that made the
                                      // button look dead on exactly the
                                      // device it gets tested on. Falling
                                      // back to the number on the clipboard
                                      // means the tap is never wasted.
                                      try {
                                        await launchURL('tel:$number');
                                      } catch (_) {
                                        await Clipboard.setData(
                                            ClipboardData(text: number));
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: Text(
                                                "This device can't place calls. "
                                                "$number copied instead."),
                                          ));
                                        }
                                      }
                                      await ActivityLogsRecord.collection
                                          .doc()
                                          .set(createActivityLogsRecordData(
                                            eventType: 'call_tap',
                                            userRef: currentUserReference,
                                            businessRef:
                                                businessProfileV2BusinessesRecord
                                                    .reference,
                                            city:
                                                businessProfileV2BusinessesRecord
                                                    .city,
                                            sessionId:
                                                FFAppState().sessionId,
                                            timestamp: getCurrentTimestamp,
                                          ));
                                    },
                                    text: 'Call',
                                    icon: Icon(
                                      Icons.phone_rounded,
                                      size: 18.0,
                                    ),
                                    options: FFButtonOptions(
                                      height: 48.0,
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          6.0, 0.0, 6.0, 0.0),
                                      iconPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              0.0, 0.0, 0.0, 0.0),
                                      iconColor:
                                          FlutterFlowTheme.of(context).primary,
                                      color: FlutterFlowTheme.of(context)
                                          .accent1,
                                      textStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .override(
                                            font: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w600,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            fontSize: 13.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      elevation: 0.0,
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .accent1,
                                        width: 1.5,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(12.0),
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 8.0, 0.0),
                                child: FFButtonWidget(
                                  onPressed: () async {
                                    context.pushNamed(
                                      TheExchangeWidget.routeName,
                                      queryParameters: {
                                        'businessRef': serializeParam(
                                          businessProfileV2BusinessesRecord
                                              .reference,
                                          ParamType.DocumentReference,
                                        ),
                                      }.withoutNulls,
                                    );
                                  },
                                  text: 'Exchange',
                                  icon: Icon(
                                    Icons.group_add,
                                    size: 18.0,
                                  ),
                                  options: FFButtonOptions(
                                    height: 48.0,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        6.0, 0.0, 6.0, 0.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    iconColor:
                                        FlutterFlowTheme.of(context).primary,
                                    // accent1, the brand gold, in both
                                    // themes. This was secondaryText - a
                                    // *text* token used as a fill, which is
                                    // gold in dark mode and near-black in
                                    // light, so these buttons rendered dark
                                    // green on black and were unreadable.
                                    color: FlutterFlowTheme.of(context)
                                        .accent1,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                      font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context).info,
                                      fontSize: 13.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,

                                    ),
                                    elevation: 0.0,
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .accent1,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                              ),
                            ),
                            if (_hasOrderingLinks(
                                businessProfileV2BusinessesRecord))
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 8.0, 0.0),
                                  child: FFButtonWidget(
                                    onPressed: () async {
                                      await showModalBottomSheet(
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        enableDrag: false,
                                        context: context,
                                        builder: (context) {
                                          return GestureDetector(
                                            onTap: () {
                                              FocusScope.of(context).unfocus();
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                            },
                                            child: Padding(
                                              padding: MediaQuery.viewInsetsOf(
                                                  context),
                                              child: CleanElegantMobileWidget(
                                                businessDoc:
                                                    businessProfileV2BusinessesRecord,
                                              ),
                                            ),
                                          );
                                        },
                                      ).then((value) => safeSetState(() {}));
                                    },
                                    text: 'Order',
                                    icon: Icon(
                                      Icons.delivery_dining_sharp,
                                      size: 18.0,
                                    ),
                                    options: FFButtonOptions(
                                      height: 48.0,
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 0.0, 12.0, 0.0),
                                      iconPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              0.0, 0.0, 0.0, 0.0),
                                      iconColor:
                                          FlutterFlowTheme.of(context).primary,
                                      color: FlutterFlowTheme.of(context)
                                          .accent1,
                                      textStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                        color:
                                            FlutterFlowTheme.of(context).info,
                                        fontSize: 13.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontStyle,
                                        shadows: [
                                          Shadow(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            offset: Offset(2.0, 2.0),
                                            blurRadius: 2.0,
                                          )
                                        ],
                                      ),
                                      elevation: 0.0,
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .accent1,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                  ),
                                ),
                              ),
                          ].divide(SizedBox(width: 12.0)),
                        ),
                        // Unclaimed listing (all ~500 bulk-imported businesses
                        // start this way) - invite the owner to take it over.
                        // This is the entry point into the claim flow: owners
                        // find themselves on the map, then claim rather than
                        // registering a duplicate via BusinessSetupPage.
                        if (businessProfileV2BusinessesRecord.ownerRef == null)
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 4.0, 0.0, 0.0),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                borderRadius: BorderRadius.circular(16.0),
                                border: Border.all(
                                  color: FlutterFlowTheme.of(context).primary,
                                  width: 1.5,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Is this your business?',
                                      style: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .override(
                                            font: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.bold),
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 4.0, 0.0, 12.0),
                                      child: Text(
                                        'Claim it to edit your details and tell '
                                        'the community you\'re Black-owned or '
                                        'veteran-owned.',
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              font:
                                                  GoogleFonts.plusJakartaSans(),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              letterSpacing: 0.0,
                                              lineHeight: 1.4,
                                            ),
                                      ),
                                    ),
                                    FFButtonWidget(
                                      onPressed: () async {
                                        context.pushNamed(
                                          ClaimBusinessWidget.routeName,
                                          queryParameters: {
                                            'businessRef': serializeParam(
                                              businessProfileV2BusinessesRecord
                                                  .reference,
                                              ParamType.DocumentReference,
                                            ),
                                          }.withoutNulls,
                                        );
                                      },
                                      text: 'Claim This Business',
                                      icon: Icon(Icons.verified_outlined,
                                          size: 18.0),
                                      options: FFButtonOptions(
                                        width: double.infinity,
                                        height: 48.0,
                                        iconColor:
                                            FlutterFlowTheme.of(context).info,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        textStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .override(
                                              font: GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.w600),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .info,
                                              fontSize: 14.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                        elevation: 0.0,
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // Null-guarded: without the null check this panel also
                        // renders for signed-out visitors on unclaimed
                        // businesses, where ownerRef and currentUserReference
                        // are both null and compare equal.
                        if (businessProfileV2BusinessesRecord.ownerRef !=
                                null &&
                            businessProfileV2BusinessesRecord.ownerRef ==
                                currentUserReference)
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 4.0, 0.0, 0.0),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Manage Your Business',
                                      style: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .override(
                                            font: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () async {
                                            context.pushNamed(
                                                BusinessSetupPageWidget
                                                    .routeName);
                                          },
                                          child: wrapWithModel(
                                            model: _model.ownerSetupActionModel,
                                            updateCallback: () =>
                                                safeSetState(() {}),
                                            child: ActionBtnWidget(
                                              icon: Icon(
                                                Icons.edit_rounded,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                                size: 24.0,
                                              ),
                                              label: 'Edit Profile\n& Hours',
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () async {
                                            context.pushNamed(
                                              MerchantPricingSuiteWidget
                                                  .routeName,
                                              queryParameters: {
                                                'businessRef': serializeParam(
                                                  businessProfileV2BusinessesRecord
                                                      .reference,
                                                  ParamType.DocumentReference,
                                                ),
                                              }.withoutNulls,
                                            );
                                          },
                                          child: wrapWithModel(
                                            model:
                                                _model.ownerPricingActionModel,
                                            updateCallback: () =>
                                                safeSetState(() {}),
                                            child: ActionBtnWidget(
                                              icon: Icon(
                                                Icons.payments_rounded,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                                size: 24.0,
                                              ),
                                              label: 'Manage\nPricing',
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () async {
                                            context.pushNamed(
                                                OwnerProfileWidget.routeName);
                                          },
                                          child: wrapWithModel(
                                            model: _model
                                                .ownerDashboardActionModel,
                                            updateCallback: () =>
                                                safeSetState(() {}),
                                            child: ActionBtnWidget(
                                              icon: Icon(
                                                Icons.dashboard_rounded,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                                size: 24.0,
                                              ),
                                              label: 'Owner\nDashboard',
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () async {
                                            await showModalBottomSheet(
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              context: context,
                                              builder: (context) => Padding(
                                                padding:
                                                    MediaQuery.viewInsetsOf(
                                                        context),
                                                child: AiMarketingSheetWidget(
                                                  businessRef:
                                                      businessProfileV2BusinessesRecord
                                                          .reference,
                                                ),
                                              ),
                                            );
                                          },
                                          child: wrapWithModel(
                                            model: _model
                                                .ownerAiMarketingActionModel,
                                            updateCallback: () =>
                                                safeSetState(() {}),
                                            child: ActionBtnWidget(
                                              icon: Icon(
                                                Icons.auto_awesome_rounded,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                                size: 24.0,
                                              ),
                                              label: 'AI\nMarketing',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ].divide(SizedBox(height: 12.0)),
                                ),
                              ),
                            ),
                          ),
                        // Address, Hours, Website, About and Photo Gallery are all optional on a
                        // bulk-imported listing. Hours and photo_gallery are empty on every one
                        // of the 498 businesses today, and description on all but 71, so
                        // rendering these unconditionally filled the page with empty headings
                        // and blank rows. Each section now appears only once it has content.
                        if (businessProfileV2BusinessesRecord
                            .address.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Container(
                                width: 44.0,
                                height: 44.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).accent1,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 22.0,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Address',
                                      style: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .override(
                                            font: GoogleFonts.plusJakartaSans(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            fontSize: 12.0,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                    Text(
                                      businessProfileV2BusinessesRecord.address,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w500,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ].divide(SizedBox(width: 16.0)),
                          ),
                        if (businessProfileV2BusinessesRecord
                                .openingTime.isNotEmpty ||
                            businessProfileV2BusinessesRecord
                                .closingTime.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Container(
                                width: 44.0,
                                height: 44.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).accent1,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Icon(
                                    Icons.access_time_rounded,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 22.0,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hours',
                                      style: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .override(
                                            font: GoogleFonts.plusJakartaSans(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            fontSize: 12.0,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                    Text(
                                      '${businessProfileV2BusinessesRecord.openingTime}-${businessProfileV2BusinessesRecord.closingTime}',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w500,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                    Text(
                                      '${businessProfileV2BusinessesRecord.openingTime}-${businessProfileV2BusinessesRecord.closingTime}',
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .override(
                                            font: GoogleFonts.playfairDisplay(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ].divide(SizedBox(width: 16.0)),
                          ),
                        if (businessProfileV2BusinessesRecord
                            .website.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Container(
                                width: 44.0,
                                height: 44.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).accent1,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Icon(
                                    Icons.language_rounded,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 22.0,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Website',
                                      style: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .override(
                                            font: GoogleFonts.plusJakartaSans(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            fontSize: 12.0,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                    InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        await KinServices.launchBusinessLink(
                                            businessProfileV2BusinessesRecord
                                                .website);
                                      },
                                      // The tap was already wired; nothing
                                      // said so. Rendered in the same
                                      // secondaryText as the inert 'Website'
                                      // label above it, with no underline
                                      // and no link colour, it read as a
                                      // caption. Same treatment as any other
                                      // link, plus the raw scheme trimmed -
                                      // 'http://www.' is noise the user
                                      // neither needs nor can act on.
                                      child: Text(
                                        businessProfileV2BusinessesRecord
                                            .website
                                            .replaceFirst(
                                                RegExp(r'^https?://'), '')
                                            .replaceFirst('www.', '')
                                            .replaceFirst(RegExp(r'/$'), ''),
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w500,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .accentOnSurface,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w500,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ].divide(SizedBox(width: 16.0)),
                          ),
                        _socialLinks(
                            context, businessProfileV2BusinessesRecord),
                        // Information, not an action. There is no delivery
                        // integration in the app: DeliveryButtonComponent
                        // was never referenced by any page, DeliveryStatus
                        // has a route nothing links to, and all 500
                        // businesses have empty doordash/ubereats/grubhub
                        // URLs. A button would promise an order flow that
                        // does not exist; this only repeats what the
                        // business told us.
                        if (businessProfileV2BusinessesRecord
                            .isDeliveryEligible)
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 4.0, 0.0, 0.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.delivery_dining_rounded,
                                  color: FlutterFlowTheme.of(context)
                                      .accentOnSurface,
                                  size: 20.0,
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      8.0, 0.0, 0.0, 0.0),
                                  child: Text(
                                    'Offers delivery',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font:
                                              GoogleFonts.plusJakartaSans(),
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (businessProfileV2BusinessesRecord
                            .description.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            height: 1.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).alternate,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'About the Business',
                                style: FlutterFlowTheme.of(context)
                                    .headlineSmall
                                    .override(
                                      font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineSmall
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .headlineSmall
                                          .fontStyle,
                                    ),
                              ),
                              Text(
                                businessProfileV2BusinessesRecord.description,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                      lineHeight: 1.6,
                                    ),
                              ),
                            ].divide(SizedBox(height: 12.0)),
                          ),
                        ],
                        if (businessProfileV2BusinessesRecord
                            .photoGallery.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            height: 1.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).alternate,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Photo Gallery',
                                style: FlutterFlowTheme.of(context)
                                    .headlineSmall
                                    .override(
                                      font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineSmall
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .headlineSmall
                                          .fontStyle,
                                    ),
                              ),
                              Builder(
                                builder: (context) {
                                  final galleryItem =
                                      businessProfileV2BusinessesRecord
                                          .photoGallery
                                          .toList();

                                  return GridView.builder(
                                    padding: EdgeInsets.zero,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 10.0,
                                      mainAxisSpacing: 10.0,
                                      childAspectRatio: 0.7,
                                    ),
                                    primary: false,
                                    shrinkWrap: true,
                                    scrollDirection: Axis.vertical,
                                    itemCount: galleryItem.length,
                                    itemBuilder: (context, galleryItemIndex) {
                                      final galleryItemItem =
                                          galleryItem[galleryItemIndex];
                                      // Was Image.network with a hardcoded
                                      // picsum.photos URL, so every business
                                      // showed the same two stock photographs
                                      // of somewhere else - the loop read the
                                      // real photo_gallery entry into
                                      // galleryItemItem and then ignored it.
                                      return ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: Image.network(
                                          galleryItemItem,
                                          width: 200.0,
                                          height: 200.0,
                                          fit: BoxFit.cover,
                                          // A gallery URL that 404s or points
                                          // at a dead host shouldn't paint a
                                          // grey exception box across the
                                          // profile.
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            width: 200.0,
                                            height: 200.0,
                                            color:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                            alignment: Alignment.center,
                                            child: Icon(
                                              Icons.image_not_supported_rounded,
                                              color: FlutterFlowTheme.of(
                                                      context)
                                                  .secondaryText,
                                              size: 28.0,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ].divide(SizedBox(height: 12.0)),
                          ),
                        ],
                        // A 1px divider. It was also given a 200x200 stock
                        // photo as its child, which a 1px-high box clipped
                        // to invisibility - so it downloaded an image on
                        // every profile open and drew none of it.
                        Container(
                          width: double.infinity,
                          height: 1.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                        ),
                        // The whole review panel is hidden for the owner
                        // viewing their own profile, not just the check-in
                        // inside it. Check-in was already gated; Submit
                        // Review was not, so an owner still saw a rating bar
                        // and a review box on their own business. The server
                        // discards those - the nightly recompute drops owner
                        // reviews outright - so the form was offering an
                        // action that silently went nowhere. Gating the
                        // container also avoids leaving a rating widget with
                        // no submit behind it.
                        if (widget.businessDocument != null &&
                            businessProfileV2BusinessesRecord.ownerRef !=
                                currentUserReference)
                        Container(
                          width: double.infinity,
                          // No fixed height: the review controls (button 40 +
                          // rating bar 24 + dense text field ~50) need ~114px,
                          // so a hardcoded 100 overflowed by 14. This sits
                          // inside the page's SingleChildScrollView, so
                          // sizing to content is safe.
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                          ),
                          // The panel had no padding, so its controls ran to
                          // the container edges.
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            // stretch, not the default center. Centering laid
                            // each control out at its own intrinsic width -
                            // a 40px-tall button as wide as its label, a
                            // 200px text box, a five-star row - so nothing
                            // shared an edge and the whole panel read as
                            // misaligned. Stretch gives the button and the
                            // review box one common width; the rating bar is
                            // centered explicitly below, since stretching a
                            // row of stars would just spread them.
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // The owner gate now lives on the container
                              // above, covering the review controls too. It
                              // is still only the first of three:
                              // recordVerifiedVisit refuses owner check-ins
                              // and the nightly recompute drops owner
                              // reviews, since a UI check alone is
                              // bypassable.
                              VisitCheckInWidget(
                                businessRef: widget.businessDocument!,
                              ),
                              // Rate first, write second, submit last. The
                              // button used to sit directly under the
                              // check-in, above both the rating bar and the
                              // review box, so the control that ends the task
                              // came before the two that do it.
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 4.0, 0.0, 0.0),
                                child: Text(
                                  'Rate your visit',
                                  style: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(),
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        letterSpacing: 0.0,
                                      ),
                                ),
                              ),
                              // Wrapped, because the Column stretches its
                              // children and a stretched RatingBar spreads
                              // its five stars across the full width.
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: RatingBar.builder(
                                onRatingUpdate: (newValue) => safeSetState(
                                    () => _model.ratingBarValue = newValue),
                                itemBuilder: (context, index) => Icon(
                                  Icons.star_rounded,
                                  color: FlutterFlowTheme.of(context).primary,
                                ),
                                direction: Axis.horizontal,
                                initialRating: _model.ratingBarValue ??= 3.0,
                                unratedColor:
                                    FlutterFlowTheme.of(context).accent1,
                                itemCount: 5,
                                itemSize: 28.0,
                                glowColor: FlutterFlowTheme.of(context).primary,
                              ),
                              ),
                              Container(
                                // Was a hardcoded width: 200, which floated a
                                // narrow box in the middle of a full-width
                                // panel. Null lets the stretch above give it
                                // the same width as the submit button.
                                child: TextFormField(
                                  controller: _model.textController,
                                  focusNode: _model.textFieldFocusNode,
                                  autofocus: false,
                                  enabled: true,
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.plusJakartaSans(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                        ),
                                    // Was 'StarRating', a FlutterFlow
                                    // placeholder left on the wrong field -
                                    // this is the review body, and the star
                                    // rating is the separate widget above it.
                                    hintText: 'Write a review (optional)',
                                    hintStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.plusJakartaSans(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                        ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0x00000000),
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0x00000000),
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    filled: true,
                                    fillColor: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                  cursorColor:
                                      FlutterFlowTheme.of(context).primaryText,
                                  enableInteractiveSelection: true,
                                  validator: _model.textControllerValidator
                                      .asValidator(context),
                                ),
                              ),
                              FFButtonWidget(
                                onPressed: () async {
                                  final businessRef = widget!.businessDocument;
                                  if (businessRef == null) {
                                    return;
                                  }
                                  final result = await KinServices.submitReview(
                                    businessRef: businessRef,
                                    rating: _model.ratingBarValue ?? 0,
                                    reviewText: _model.textController.text,
                                  );
                                  if (!result.isSuccess && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(result.error!)),
                                    );
                                  }
                                },
                                text: 'Submit Review',
                                options: FFButtonOptions(
                                  height: 40.0,
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 0.0, 16.0, 0.0),
                                  iconPadding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 0.0),
                                  color: FlutterFlowTheme.of(context).primary,
                                  textStyle: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .fontStyle,
                                        ),
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontStyle,
                                      ),
                                  elevation: 0.0,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            _model.updatedKindexResult =
                                await actions.calculateRealTimeKindex(
                              businessProfileV2BusinessesRecord.kindexScore,
                              _model.ratingBarValue!.round(),
                              businessProfileV2BusinessesRecord.isPremium,
                            );

                            safeSetState(() {});
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customer Reviews',
                                style: FlutterFlowTheme.of(context)
                                    .headlineSmall
                                    .override(
                                      font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineSmall
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .headlineSmall
                                          .fontStyle,
                                    ),
                              ),
                              StreamBuilder<List<ReviewsRecord>>(
                                stream: queryReviewsRecord(
                                  queryBuilder: (reviewsRecord) => reviewsRecord
                                      .where(
                                        'business_ref',
                                        isEqualTo:
                                            businessProfileV2BusinessesRecord
                                                .reference,
                                      )
                                      .orderBy('timestamp', descending: true),
                                ),
                                builder: (context, snapshot) {
                                  // Customize what your widget looks like when it's loading.
                                  if (!snapshot.hasData) {
                                    return Center(
                                      child: SizedBox(
                                        width: 50.0,
                                        height: 50.0,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            FlutterFlowTheme.of(context)
                                                .primary,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  List<ReviewsRecord>
                                      listViewReviewsRecordList =
                                      snapshot.data!;

                                  return ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    scrollDirection: Axis.vertical,
                                    primary: false,
                                    itemCount: listViewReviewsRecordList.length,
                                    itemBuilder: (context, listViewIndex) {
                                      final listViewReviewsRecord =
                                          listViewReviewsRecordList[
                                              listViewIndex];
                                      return Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: StreamBuilder<UsersRecord>(
                                          stream: UsersRecord.getDocument(
                                              listViewReviewsRecord.userRef!),
                                          builder: (context, snapshot) {
                                            // Customize what your widget looks like when it's loading.
                                            if (!snapshot.hasData) {
                                              return Center(
                                                child: SizedBox(
                                                  width: 50.0,
                                                  height: 50.0,
                                                  child:
                                                      CircularProgressIndicator(
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                            Color>(
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .primary,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }

                                            final containerUsersRecord =
                                                snapshot.data!;

                                            return Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryBackground,
                                                borderRadius:
                                                    BorderRadius.circular(16.0),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.all(16.0),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          children: [
                                                            Container(
                                                              width: 40.0,
                                                              height: 40.0,
                                                              clipBehavior: Clip
                                                                  .antiAlias,
                                                              decoration:
                                                                  BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              child:
                                                                  Image.network(
                                                                'https://images.unsplash.com/photo-1701854851797-59656d43e5fe?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3Nzc1Mjk1OTN8&ixlib=rb-4.1.0&q=80&w=1080',
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                            ),
                                                            Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  containerUsersRecord
                                                                      .displayName,
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .plusJakartaSans(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .titleSmall
                                                                              .fontStyle,
                                                                        ),
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .titleSmall
                                                                            .fontStyle,
                                                                      ),
                                                                ),
                                                                Text(
                                                                  dateTimeFormat(
                                                                      "relative",
                                                                      listViewReviewsRecord
                                                                          .timestamp!),
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .playfairDisplay(
                                                                          fontWeight: FlutterFlowTheme.of(context)
                                                                              .bodySmall
                                                                              .fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .bodySmall
                                                                              .fontStyle,
                                                                        ),
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryText,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .bodySmall
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodySmall
                                                                            .fontStyle,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                          ].divide(SizedBox(
                                                              width: 10.0)),
                                                        ),
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          children: [
                                                            if (listViewReviewsRecord
                                                                    .rating >=
                                                                1.0)
                                                              Icon(
                                                                Icons
                                                                    .star_rounded,
                                                                color: Color(
                                                                    0xFFF59E0B),
                                                                size: 14.0,
                                                              ),
                                                            if (listViewReviewsRecord
                                                                    .rating >=
                                                                2.0)
                                                              Icon(
                                                                Icons
                                                                    .star_rounded,
                                                                color: Color(
                                                                    0xFFF59E0B),
                                                                size: 14.0,
                                                              ),
                                                            if (listViewReviewsRecord
                                                                    .rating >=
                                                                3.0)
                                                              Icon(
                                                                Icons
                                                                    .star_rounded,
                                                                color: Color(
                                                                    0xFFF59E0B),
                                                                size: 14.0,
                                                              ),
                                                            if (listViewReviewsRecord
                                                                    .rating >=
                                                                4.0)
                                                              Icon(
                                                                Icons
                                                                    .star_rounded,
                                                                color: Color(
                                                                    0xFFF59E0B),
                                                                size: 14.0,
                                                              ),
                                                            if (listViewReviewsRecord
                                                                    .rating >=
                                                                5.0)
                                                              Icon(
                                                                Icons
                                                                    .star_rounded,
                                                                color: Color(
                                                                    0xFFF59E0B),
                                                                size: 14.0,
                                                              ),
                                                          ].divide(SizedBox(
                                                              width: 2.0)),
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      listViewReviewsRecord
                                                          .reviewText,
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .override(
                                                                font: GoogleFonts
                                                                    .plusJakartaSans(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryText,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                                lineHeight: 1.5,
                                                              ),
                                                    ),
                                                  ].divide(
                                                      SizedBox(height: 8.0)),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ].divide(SizedBox(height: 16.0)),
                          ),
                        ),
                      ].divide(SizedBox(height: 24.0)),
                    ),
                  ),
                ].addToEnd(SizedBox(height: 40.0)),
              ),
            ),
          ),
        );
      },
    );
  }
}
