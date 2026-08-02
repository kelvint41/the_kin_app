import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/section_header_widget.dart';
import '/components/step_indicator3_widget.dart';
import '/services/kin_services.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_place_picker.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/place.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'business_setup_page_model.dart';
export 'business_setup_page_model.dart';

/// Create a clean, professional, dark-mode multi-step business onboarding
/// form page called "Biz Setup Page" for The Kin App.
///
/// Theme: Dark luxurious black/gold/green accents matching the rest of the
/// app.
///
/// Structure:
/// - Step 1: Business Information
///   - Business Name: Use Autocomplete field that searches existing
/// businesses in the 'businesses' collection (to help avoid duplicates and
/// suggest similar names)
///   - Business Category: Dropdown with common options (Salon/Beauty,
/// Restaurant/Food, Retail, Services, etc.)
///   - Business Type: Choice Chips (Sole Proprietor, LLC, Corporation,
/// Partnership)
///   - Phone Number, Email, Website (TextFields)
///
/// - Step 2: Location & Details
///   - Address: Use Google Place Picker component that auto-fills street
/// address, city, state, zip_code_postcode, and saves latitude & longitude
/// into business_location
///   - Business Description: Large multiline TextField
///   - Upload Business Logo / Hero Image
///   - Toggle: "This is a Black-owned business" (default: true)
///
/// - Final Submit Button: "Claim & Register Business"
///
/// Backend Logic:
/// - On submit, create a new document in the 'businesses' collection
/// - Map all fields correctly: business_name, address, city, state,
/// zip_code_postcode, latitude, longitude, business_location (LatLng),
/// phone_number, email, website, category, description, is_black_owned, etc.
/// - Set is_verified = false, is_claimed = true, is_black_owned = true by
/// default
/// - After successful creation, navigate to Business Profile Owner page
/// passing the new document reference
///
/// Make the UI modern, clean, with good spacing and matching The Kin App
/// style.
class BusinessSetupPageWidget extends StatefulWidget {
  const BusinessSetupPageWidget({super.key});

  static String routeName = 'BusinessSetupPage';
  static String routePath = '/businessSetupPage';

  @override
  State<BusinessSetupPageWidget> createState() =>
      _BusinessSetupPageWidgetState();
}

class _BusinessSetupPageWidgetState extends State<BusinessSetupPageWidget> {
  late BusinessSetupPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  Timer? _matchDebounce;
  MatchedBusinessSubmission? _matchedSubmission;
  bool _matchDismissed = false;
  bool _matchAccepted = false;
  bool _checkingForMatch = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BusinessSetupPageModel());
  }

  @override
  void dispose() {
    _matchDebounce?.cancel();
    _model.dispose();

    super.dispose();
  }

  /// Debounced check against pending KIN Quest discoveries (see
  /// KinServices.findMatchingBusinessSubmission) every time the business
  /// name changes - the "someone already found your business" moment.
  /// Resets any previous match/dismissal, since a changed name means a
  /// stale match no longer applies.
  void _onBusinessNameChanged(String name) {
    _matchDebounce?.cancel();
    if (_matchAccepted) return; // Already claimed one - don't re-check.
    safeSetState(() {
      _matchedSubmission = null;
      _matchDismissed = false;
    });
    final trimmed = name.trim();
    if (trimmed.length < 3) return;
    _matchDebounce = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      safeSetState(() => _checkingForMatch = true);
      final place = _model.placePickerValue;
      final result = await KinServices.findMatchingBusinessSubmission(
        businessName: trimmed,
        latitude: place.latLng?.latitude,
        longitude: place.latLng?.longitude,
      );
      if (!mounted) return;
      safeSetState(() {
        _checkingForMatch = false;
        if (result.isSuccess) _matchedSubmission = result.data;
      });
    });
  }

  void _useMatchedSubmission() {
    if (_matchedSubmission == null) return;
    // There's no free-text address field here to prefill - location comes
    // from FlutterFlowPlacePicker below, which still requires the owner to
    // pick a real geocoded place. Accepting just remembers the match (shown
    // as a hint) and queues it to be marked resolved once registration
    // succeeds - see _matchDismissed/[resolveBusinessSubmission].
    safeSetState(() => _matchAccepted = true);
  }

  Widget _matchedSubmissionBanner(FlutterFlowTheme theme) {
    final match = _matchedSubmission;
    if (match == null || _matchDismissed) return const SizedBox.shrink();
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      padding: EdgeInsets.all(14.0),
      // This banner's fill is theme.primary, a fixed dark green that
      // doesn't change between light/dark mode - same issue as the support
      // chat bubble. accentOnSurface flips to a darkened gold in light mode
      // (tuned for AA contrast on light backgrounds elsewhere) and reads at
      // only 2.05:1 against this green. accent1 (fixed brand gold) holds
      // 5.8:1 in both modes; white text/icons hold 12.2:1.
      decoration: BoxDecoration(
        color: theme.primary,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: theme.accent1, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.travel_explore_rounded,
                  color: theme.accent1, size: 20.0),
              SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Someone already found your business on KIN Quest!',
                  style: theme.bodyMedium.override(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.0),
          Text(
            _matchAccepted
                ? "We'll link that discovery to your business once you "
                    'register.'
                : 'They noted this address: "${match.address}". Want to '
                    'claim that discovery? (Still pick your exact location '
                    'below.)',
            style: theme.bodySmall.override(color: Colors.white70),
          ),
          if (!_matchAccepted) ...[
            SizedBox(height: 10.0),
            Row(
              children: [
                TextButton(
                  onPressed: () => safeSetState(() => _matchDismissed = true),
                  child: Text('Not Mine',
                      style: theme.bodySmall.override(color: Colors.white70)),
                ),
                SizedBox(width: 8.0),
                FFButtonWidget(
                  onPressed: _useMatchedSubmission,
                  text: 'Use This',
                  options: FFButtonOptions(
                    height: 36.0,
                    padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                    color: theme.accent1,
                    textStyle: theme.bodySmall.override(color: theme.primary),
                    elevation: 0.0,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetupTextField({
    required TextEditingController? controller,
    required FocusNode? focusNode,
    required String labelText,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: false,
      enabled: true,
      obscureText: false,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        isDense: true,
        labelText: labelText,
        // labelMedium/bodyMedium default to primaryText, which is styled for
        // light surfaces - on this field's dark green fill that made the
        // label, hint, and typed text all nearly invisible. accentOnSurface
        // is what every other control on this page (the dropdowns, the
        // business-type chips) already uses for text on this same fill.
        labelStyle: FlutterFlowTheme.of(context).labelMedium.override(
              color: FlutterFlowTheme.of(context).accentOnSurface,
            ),
        hintText: hintText,
        hintStyle: FlutterFlowTheme.of(context).labelMedium.override(
              color: FlutterFlowTheme.of(context)
                  .accentOnSurface
                  .withAlpha(153),
            ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: FlutterFlowTheme.of(context).alternate,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: FlutterFlowTheme.of(context).accentOnSurface,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: FlutterFlowTheme.of(context).error,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        filled: true,
        fillColor: FlutterFlowTheme.of(context).primary,
      ),
      style: FlutterFlowTheme.of(context).bodyMedium.override(
            color: FlutterFlowTheme.of(context).accentOnSurface,
          ),
      cursorColor: FlutterFlowTheme.of(context).accentOnSurface,
    );
  }

  /// Shown instead of the form when nobody is signed in. Offers the account
  /// step rather than just refusing, and stamps signupType so that account
  /// creation returns here instead of dropping them on the customer profile.
  Widget _buildAccountRequiredState(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storefront_rounded,
                    size: 48.0, color: theme.accentOnSurface),
                SizedBox(height: theme.designToken.spacing.md),
                Text(
                  'Create your account first',
                  textAlign: TextAlign.center,
                  style: theme.headlineSmall.override(
                    color: theme.primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: theme.designToken.spacing.sm),
                Text(
                  'Your business is registered to your account, so we need '
                  "that first. It only takes a moment, and you'll come "
                  'straight back here.',
                  textAlign: TextAlign.center,
                  style: theme.bodyMedium.override(color: theme.secondaryText),
                ),
                SizedBox(height: theme.designToken.spacing.lg),
                FFButtonWidget(
                  onPressed: () {
                    FFAppState().signupType = 'business';
                    context.pushNamed(CustomersignupPageWidget.routeName);
                  },
                  text: 'Create Account',
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 48.0,
                    color: theme.primary,
                    textStyle: theme.titleSmall.override(color: Colors.white),
                    elevation: 0.0,
                    borderRadius:
                        BorderRadius.circular(theme.designToken.radius.sm),
                  ),
                ),
                SizedBox(height: theme.designToken.spacing.sm),
                InkWell(
                  onTap: () {
                    FFAppState().signupType = 'business';
                    context.pushNamed(SignInPageWidget.routeName);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
                    child: Text(
                      'Already have an account? Log in',
                      style: theme.bodyMedium.override(
                        color: theme.accentOnSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // registerBusiness needs a signed-in owner and refuses without one, so
    // an unauthenticated visitor could previously fill in every field here
    // and only discover that on submit - by which point the form was gone.
    // The onboarding button now routes to sign-up first, but this page is
    // also reachable directly and by deep link, so the guard lives here as
    // well rather than only at the one entry point that happens to be
    // fixed.
    if (!loggedIn) {
      return _buildAccountRequiredState(context);
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SingleChildScrollView(
          primary: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                  shape: BoxShape.rectangle,
                ),
                child: Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(24.0, 24.0, 24.0, 16.0),
                  child: Container(
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FlutterFlowIconButton(
                          borderRadius: 8.0,
                          buttonSize: 40.0,
                          fillColor: Colors.transparent,
                          icon: Icon(
                            Icons.close_rounded,
                            color: FlutterFlowTheme.of(context).secondaryText,
                            size: 24.0,
                          ),
                          onPressed: () {
                            context.safePop();
                          },
                        ),
                        Text(
                          'Business Setup',
                          style: FlutterFlowTheme.of(context)
                              .titleMedium
                              .override(
                                font: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontStyle,
                                ),
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .fontStyle,
                                lineHeight: 1.4,
                              ),
                        ),
                        Container(
                          width: 40.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    wrapWithModel(
                      model: _model.stepIndicatorModel,
                      updateCallback: () => safeSetState(() {}),
                      child: StepIndicator3Widget(
                        currentStep: 1.0,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        wrapWithModel(
                          model: _model.sectionHeaderModel1,
                          updateCallback: () => safeSetState(() {}),
                          child: SectionHeaderWidget(
                            title: 'Business Info',
                            subtitle:
                                'Let\'s start with the basics of your brand.',
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _matchedSubmissionBanner(
                                FlutterFlowTheme.of(context)),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 16.0),
                              child: _buildSetupTextField(
                                controller:
                                    _model.businessNameTextController ??=
                                        TextEditingController(),
                                focusNode: _model.businessNameFocusNode ??=
                                    FocusNode(),
                                labelText: 'Business Name',
                                hintText: 'Enter your business name',
                                onChanged: _onBusinessNameChanged,
                              ),
                            ),
                            StreamBuilder<List<BusinessCategoriesRecord>>(
                              stream: queryBusinessCategoriesRecord(
                                queryBuilder: (q) =>
                                    q.orderBy('display_name'),
                              ),
                              builder: (context, snapshot) {
                                final categoryOptions = snapshot.hasData &&
                                        snapshot.data!.isNotEmpty
                                    ? snapshot.data!
                                        .map((c) => c.displayName)
                                        .toList()
                                    : [
                                        'Salon & Beauty',
                                        'Restaurant & Food',
                                        'Retail',
                                        'Professional Services',
                                        'Health & Wellness',
                                        'Home Care & Health Services'
                                      ];
                                return FlutterFlowDropDown<String>(
                                  controller:
                                      _model.dropdownValueController ??=
                                          FormFieldController<String>(
                                    _model.dropdownValue ??=
                                        categoryOptions.first,
                                  ),
                                  options: categoryOptions,
                                  onChanged: (val) => safeSetState(
                                      () => _model.dropdownValue = val),
                                  width: 200.0,
                                  height: 40.0,
                                  textStyle: FlutterFlowTheme.of(context)
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
                                            .accentOnSurface,
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                        lineHeight: 1.4,
                                      ),
                                  hintText: 'Salon & Beauty',
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: FlutterFlowTheme.of(context)
                                        .accentOnSurface,
                                    size: 24.0,
                                  ),
                                  fillColor:
                                      FlutterFlowTheme.of(context).primary,
                                  elevation: 2.0,
                                  borderColor:
                                      FlutterFlowTheme.of(context).alternate,
                                  borderWidth: 1.0,
                                  borderRadius: 14.0,
                                  margin: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 0.0, 16.0, 0.0),
                                  hidesUnderline: true,
                                  isOverButton: false,
                                  isSearchable: false,
                                  isMultiSelect: false,
                                  labelText: 'Business Category',
                                  labelTextStyle: FlutterFlowTheme.of(context)
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
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                        lineHeight: 1.4,
                                      ),
                                );
                              },
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 4.0, 16.0, 0.0),
                              child: _model.showOtherCategoryField
                                  ? _buildSetupTextField(
                                      controller: _model
                                              .otherCategoryTextController ??=
                                          TextEditingController(),
                                      focusNode:
                                          _model.otherCategoryFocusNode ??=
                                              FocusNode(),
                                      labelText: "Don't see your category?",
                                      hintText: 'Type a new one',
                                    )
                                  : InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () => safeSetState(() =>
                                          _model.showOtherCategoryField =
                                              true),
                                      child: Text(
                                        "Don't see your category?",
                                        style: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .override(
                                              font: GoogleFonts
                                                  .plusJakartaSans(),
                                              color: FlutterFlowTheme.of(
                                                      context)
                                                  .accentOnSurface,
                                              decoration:
                                                  TextDecoration.underline,
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 4.0, 16.0, 0.0),
                              child: FlutterFlowDropDown<String>(
                                controller: _model.businessTypeValueController ??=
                                    FormFieldController<String>(
                                        _model.businessType),
                                options: const [
                                  'Sole Proprietor',
                                  'LLC',
                                  'Corporation',
                                  'Partnership',
                                ],
                                onChanged: (val) => safeSetState(
                                    () => _model.businessType =
                                        val ?? 'Sole Proprietor'),
                                width: double.infinity,
                                height: 40.0,
                                textStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.plusJakartaSans(),
                                      color: FlutterFlowTheme.of(context)
                                          .accentOnSurface,
                                      letterSpacing: 0.0,
                                    ),
                                hintText: 'Business Type',
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color:
                                      FlutterFlowTheme.of(context).accentOnSurface,
                                  size: 24.0,
                                ),
                                fillColor: FlutterFlowTheme.of(context).primary,
                                elevation: 2.0,
                                borderColor:
                                    FlutterFlowTheme.of(context).alternate,
                                borderWidth: 1.0,
                                borderRadius: 14.0,
                                margin: EdgeInsetsDirectional.zero,
                                hidesUnderline: true,
                                isOverButton: false,
                                isSearchable: false,
                                isMultiSelect: false,
                                labelText: 'Business Type',
                                labelTextStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.plusJakartaSans(),
                                      letterSpacing: 0.0,
                                    ),
                              ),
                            ),
                            _buildSetupTextField(
                              controller: _model.phoneNumberTextController ??=
                                  TextEditingController(),
                              focusNode: _model.phoneNumberFocusNode ??=
                                  FocusNode(),
                              labelText: 'Phone Number',
                              hintText: '(555) 555-5555',
                              keyboardType: TextInputType.phone,
                            ),
                            _buildSetupTextField(
                              controller: _model.emailTextController ??=
                                  TextEditingController(),
                              focusNode: _model.emailFocusNode ??= FocusNode(),
                              labelText: 'Email',
                              hintText: 'business@example.com',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            _buildSetupTextField(
                              controller: _model.websiteTextController ??=
                                  TextEditingController(),
                              focusNode: _model.websiteFocusNode ??=
                                  FocusNode(),
                              labelText: 'Website',
                              hintText: 'https://yourbusiness.com',
                              keyboardType: TextInputType.url,
                            ),
                          ].divide(SizedBox(height: 16.0)),
                        ),
                      ].divide(SizedBox(height: 24.0)),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        wrapWithModel(
                          model: _model.sectionHeaderModel2,
                          updateCallback: () => safeSetState(() {}),
                          child: SectionHeaderWidget(
                            title: 'Location & Details',
                            subtitle:
                                'Help customers find and learn about you.',
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).primary,
                            borderRadius: BorderRadius.circular(14.0),
                            shape: BoxShape.rectangle,
                            border: Border.all(
                              color: FlutterFlowTheme.of(context).alternate,
                              width: 1.0,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Container(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.place_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        size: 24.0,
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        size: 14.0,
                                      ),
                                    ].divide(SizedBox(width: 16.0)),
                                  ),
                                ),
                              ),
                              Opacity(
                                opacity: 0.0,
                                child: Align(
                                  alignment: AlignmentDirectional(-0.04, 0.28),
                                  child: FlutterFlowPlacePicker(
                                    iOSGoogleMapsApiKey:
                                        'AIzaSyD1w4m7IaWva5Bxl9fsbsZgILC7R8wf_Go',
                                    androidGoogleMapsApiKey:
                                        'AIzaSyD1w4m7IaWva5Bxl9fsbsZgILC7R8wf_Go',
                                    webGoogleMapsApiKey:
                                        'AIzaSyD1w4m7IaWva5Bxl9fsbsZgILC7R8wf_Go',
                                    onSelect: (place) async {
                                      safeSetState(() =>
                                          _model.placePickerValue = place);
                                    },
                                    defaultText: 'Select Location',
                                    icon: Icon(
                                      Icons.place,
                                      color: FlutterFlowTheme.of(context).info,
                                      size: 16.0,
                                    ),
                                    buttonOptions: FFButtonOptions(
                                      width: 200.0,
                                      height: 40.0,
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      textStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .override(
                                            font: GoogleFonts.plusJakartaSans(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .info,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                      elevation: 0.0,
                                      borderSide: BorderSide(
                                        color: Colors.transparent,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(0.15, 0.5),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Business Address',
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
                                            // secondaryText flips between
                                            // near-black and light-gold with
                                            // the app theme, but this button
                                            // sits on a fixed dark green fill
                                            // (theme.primary) either way - in
                                            // light mode that made the label
                                            // nearly invisible. accentOnSurface
                                            // is defined per-theme to stay
                                            // readable on this fixed surface.
                                            color: FlutterFlowTheme.of(context)
                                                .accentOnSurface,
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
                                    Text(
                                      'Search with Google Maps...',
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
                                                .accentOnSurface
                                                .withAlpha(153),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                            lineHeight: 1.4,
                                          ),
                                    ),
                                  ].divide(SizedBox(height: 4.0)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Business Image',
                              style: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .override(
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                    lineHeight: 1.4,
                                  ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24.0),
                              child: Container(
                                height: 160.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).primary,
                                  borderRadius: BorderRadius.circular(24.0),
                                  shape: BoxShape.rectangle,
                                  border: Border.all(
                                    color:
                                        FlutterFlowTheme.of(context).alternate,
                                    width: 1.0,
                                  ),
                                ),
                                alignment: AlignmentDirectional(0.0, 0.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .accentOnSurface,
                                      size: 32.0,
                                    ),
                                    Text(
                                      'Upload Logo or Hero Image',
                                      style: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .override(
                                            font: GoogleFonts.plusJakartaSans(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelLarge
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelLarge
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .accentOnSurface,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelLarge
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelLarge
                                                    .fontStyle,
                                            lineHeight: 1.4,
                                          ),
                                    ),
                                  ].divide(SizedBox(height: 8.0)),
                                ),
                              ),
                            ),
                            _buildSetupTextField(
                              controller: _model.descriptionTextController ??=
                                  TextEditingController(),
                              focusNode: _model.descriptionFocusNode ??=
                                  FocusNode(),
                              labelText: 'Business Description',
                              hintText:
                                  'Tell customers what makes your business special',
                              maxLines: 4,
                            ),
                          ].divide(SizedBox(height: 8.0)),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).primary,
                            borderRadius: BorderRadius.circular(24.0),
                            shape: BoxShape.rectangle,
                            border: Border.all(
                              color: Color(0x4D004225),
                              width: 1.0,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Container(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.workspace_premium_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .accentOnSurface,
                                          size: 24.0,
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Black-owned business',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyLarge
                                                        .override(
                                                          font: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyLarge
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .accentOnSurface,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyLarge
                                                                  .fontStyle,
                                                          lineHeight: 1.4,
                                                        ),
                                              ),
                                              Text(
                                                'Display the Kin excellence badge on your profile',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodySmall
                                                        .override(
                                                          font: GoogleFonts
                                                              .playfairDisplay(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .accentOnSurface,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodySmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodySmall
                                                                  .fontStyle,
                                                          lineHeight: 1.4,
                                                        ),
                                              ),
                                            ].divide(SizedBox(height: 4.0)),
                                          ),
                                        ),
                                      ].divide(SizedBox(width: 16.0)),
                                    ),
                                  ),
                                  Switch(
                                    value: _model.isBlackOwned,
                                    onChanged: (newValue) => safeSetState(
                                        () => _model.isBlackOwned = newValue),
                                    activeColor:
                                        FlutterFlowTheme.of(context).primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ].divide(SizedBox(height: 24.0)),
                    ),
                    Container(
                      height: 24.0,
                    ),
                    FFButtonWidget(
                      onPressed: () async {
                        final otherCategory =
                            _model.otherCategoryTextController?.text.trim() ??
                                '';
                        final effectiveCategory = otherCategory.isNotEmpty
                            ? otherCategory
                            : _model.dropdownValue;
                        if (otherCategory.isNotEmpty) {
                          await KinServices.ensureBusinessCategoryExists(
                              otherCategory);
                        }
                        final result = await KinServices.registerBusiness(
                          category: effectiveCategory,
                          businessType: _model.businessType,
                          isBlackOwned: _model.isBlackOwned,
                          place: _model.placePickerValue,
                          businessName: _model.businessNameTextController?.text,
                          phoneNumber: _model.phoneNumberTextController?.text,
                          email: _model.emailTextController?.text,
                          website: _model.websiteTextController?.text,
                          description: _model.descriptionTextController?.text,
                        );
                        if (!result.isSuccess) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result.error!)),
                            );
                          }
                          return;
                        }

                        // Best-effort: the business is already registered at
                        // this point, so a failure here shouldn't block the
                        // owner - it just means the submission stays
                        // unresolved for admin review to catch later.
                        if (_matchAccepted && _matchedSubmission != null) {
                          unawaited(KinServices.resolveBusinessSubmission(
                            submissionId: _matchedSubmission!.submissionId,
                            businessRef: result.data!,
                          ));
                        }

                        context.pushNamed(OwnerProfileWidget.routeName);

                        safeSetState(() {});
                      },
                      text: 'Register Now',
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 65.0,
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 0.0),
                        iconPadding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle: FlutterFlowTheme.of(context)
                            .titleSmall
                            .override(
                              font: GoogleFonts.plusJakartaSans(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontStyle,
                              ),
                              color:
                                  FlutterFlowTheme.of(context).accentOnSurface,
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .fontStyle,
                            ),
                        elevation: 0.0,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    Container(
                      child: Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
                        child: Container(
                          child: Container(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Text(
                              'By registering, you agree to our Terms of Service',
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
                        ),
                      ),
                    ),
                  ].divide(SizedBox(height: 24.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
