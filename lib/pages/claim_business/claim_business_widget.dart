import '/backend/backend.dart';
import '/components/main_menu_button.dart';
import '/services/kin_services.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'claim_business_model.dart';
export 'claim_business_model.dart';

/// Lets a business owner claim an existing directory listing.
///
/// The ~500 bulk-imported businesses are seeded unclaimed (owner_ref null,
/// is_claimed false, is_black_owned false) precisely so owners can find
/// themselves on the map and take ownership - false here means "not yet
/// claimed", not "we determined this isn't a Black-owned business".
///
/// Verification approach is deliberately low-friction and collects nothing
/// sensitive: we ask only for a name, a role, how to reach them, and an
/// optional public link. No EIN, no business license, no government ID, and
/// crucially no documentation of the owner's race or veteran status - those
/// are self-declared here and only applied to the business once a human
/// approves the claim.
class ClaimBusinessWidget extends StatefulWidget {
  const ClaimBusinessWidget({super.key, required this.businessRef});

  final DocumentReference? businessRef;

  static String routeName = 'ClaimBusiness';
  static String routePath = '/claimBusiness';

  @override
  State<ClaimBusinessWidget> createState() => _ClaimBusinessWidgetState();
}

class _ClaimBusinessWidgetState extends State<ClaimBusinessWidget> {
  late ClaimBusinessModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ClaimBusinessModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _submit(BusinessesRecord business) async {
    if (_model.isSubmitting) return;

    // Validate the fields and the attestation together so one tap surfaces
    // everything that's missing, rather than the form errors first and the
    // attestation only after those are fixed.
    final fieldsValid = _model.formKey.currentState?.validate() ?? false;
    if (!_model.attested) {
      safeSetState(() => _model.showAttestationError = true);
    }
    if (!fieldsValid || !_model.attested) return;

    safeSetState(() => _model.isSubmitting = true);
    final result = await KinServices.submitClaimRequest(
      businessRef: business.reference,
      businessName: business.businessName,
      claimantName: _model.claimantNameTextController?.text ?? '',
      claimantRole: _model.claimantRoleTextController?.text ?? '',
      contactEmail: _model.contactEmailTextController?.text ?? '',
      contactPhone: _model.contactPhoneTextController?.text ?? '',
      verificationProofLink: _model.proofLinkTextController?.text,
      openingTime: _model.openingTimeTextController?.text,
      closingTime: _model.closingTimeTextController?.text,
      attested: _model.attested,
      declaredBlackOwned: _model.declaredBlackOwned,
      declaredVeteran: _model.declaredVeteran,
    );
    if (!mounted) return;
    safeSetState(() => _model.isSubmitting = false);

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Claim submitted'),
        content: Text(
          'Thanks! We\'ll review your claim and get in touch at the contact '
          'details you gave us. Once it\'s approved you\'ll be able to edit '
          'your listing yourself.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Got it'),
          ),
        ],
      ),
    );
    if (mounted) context.safePop();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          // Was false with only the hamburger for a way out - this screen
          // is reached by pushNamed from a business profile, so there was
          // always a real route to pop, just no control to do it with.
          automaticallyImplyLeading: true,
          foregroundColor: FlutterFlowTheme.of(context).info,
          title: Text(
            'Claim Your Business',
            style: FlutterFlowTheme.of(context).headlineSmall.override(
                  font:
                      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  color: FlutterFlowTheme.of(context).info,
                  fontSize: 20.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                ),
          ),
          centerTitle: false,
          elevation: 0.0,
          actions: [Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: MainMenuButton(),
          )],
        ),
        body: SafeArea(
          top: true,
          child: StreamBuilder<BusinessesRecord>(
            stream: BusinessesRecord.getDocument(widget.businessRef!),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: SizedBox(
                    width: 40.0,
                    height: 40.0,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          FlutterFlowTheme.of(context).primary),
                    ),
                  ),
                );
              }
              final business = snapshot.data!;

              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Form(
                    key: _model.formKey,
                    autovalidateMode: AutovalidateMode.disabled,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _businessCard(business),
                        SizedBox(height: 24.0),
                        _sectionLabel('Your details'),
                        SizedBox(height: 12.0),
                        _textField(
                          controller: _model.claimantNameTextController ??=
                              TextEditingController(),
                          focusNode: _model.claimantNameFocusNode ??=
                              FocusNode(),
                          label: 'Your full name',
                          validator: _model.claimantNameTextControllerValidator
                              ?.asValidator(context),
                          textCapitalization: TextCapitalization.words,
                        ),
                        SizedBox(height: 16.0),
                        _textField(
                          controller: _model.claimantRoleTextController ??=
                              TextEditingController(),
                          focusNode: _model.claimantRoleFocusNode ??=
                              FocusNode(),
                          label: 'Your role',
                          hint: 'Owner, Manager, etc.',
                          textCapitalization: TextCapitalization.words,
                        ),
                        SizedBox(height: 16.0),
                        _textField(
                          controller: _model.contactEmailTextController ??=
                              TextEditingController(),
                          focusNode: _model.contactEmailFocusNode ??=
                              FocusNode(),
                          label: 'Email',
                          hint: 'Where we\'ll send the outcome',
                          keyboardType: TextInputType.emailAddress,
                          validator: _model.contactEmailTextControllerValidator
                              ?.asValidator(context),
                        ),
                        SizedBox(height: 16.0),
                        _textField(
                          controller: _model.contactPhoneTextController ??=
                              TextEditingController(),
                          focusNode: _model.contactPhoneFocusNode ??=
                              FocusNode(),
                          label: 'Phone (optional)',
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: 24.0),
                        _sectionLabel('Help us verify (optional)'),
                        SizedBox(height: 6.0),
                        Text(
                          'Paste a public link that shows you run this business '
                          '- your website\'s contact page, your Google Business '
                          'Profile, or a post from the business\'s own social '
                          'account. Please don\'t upload licenses, tax IDs, or '
                          'anything with personal information on it.',
                          style: FlutterFlowTheme.of(context)
                              .labelSmall
                              .override(
                                font: GoogleFonts.plusJakartaSans(),
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                                lineHeight: 1.4,
                              ),
                        ),
                        SizedBox(height: 12.0),
                        _textField(
                          controller: _model.proofLinkTextController ??=
                              TextEditingController(),
                          focusNode: _model.proofLinkFocusNode ??= FocusNode(),
                          label: 'Link',
                          hint: 'https://',
                          keyboardType: TextInputType.url,
                        ),
                        SizedBox(height: 24.0),
                        _sectionLabel('Business hours (optional)'),
                        SizedBox(height: 12.0),
                        _textField(
                          controller: _model.openingTimeTextController ??=
                              TextEditingController(),
                          focusNode: _model.openingTimeFocusNode ??=
                              FocusNode(),
                          label: 'Opening time',
                          hint: '9:00 AM',
                        ),
                        SizedBox(height: 16.0),
                        _textField(
                          controller: _model.closingTimeTextController ??=
                              TextEditingController(),
                          focusNode: _model.closingTimeFocusNode ??=
                              FocusNode(),
                          label: 'Closing time',
                          hint: '6:00 PM',
                        ),
                        SizedBox(height: 24.0),
                        _sectionLabel('About your business'),
                        SizedBox(height: 6.0),
                        Text(
                          'You tell us - we never ask for documentation of '
                          'either. These are applied to your listing once your '
                          'claim is approved.',
                          style: FlutterFlowTheme.of(context)
                              .labelSmall
                              .override(
                                font: GoogleFonts.plusJakartaSans(),
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                                lineHeight: 1.4,
                              ),
                        ),
                        SizedBox(height: 8.0),
                        _switchTile(
                          title: 'This is a Black-owned business',
                          value: _model.declaredBlackOwned,
                          onChanged: (v) =>
                              safeSetState(() => _model.declaredBlackOwned = v),
                        ),
                        _switchTile(
                          title: 'This is a veteran-owned business',
                          value: _model.declaredVeteran,
                          onChanged: (v) =>
                              safeSetState(() => _model.declaredVeteran = v),
                        ),
                        SizedBox(height: 24.0),
                        _attestationTile(),
                        SizedBox(height: 24.0),
                        FFButtonWidget(
                          onPressed: _model.isSubmitting
                              ? null
                              : () => _submit(business),
                          text: _model.isSubmitting
                              ? 'Submitting...'
                              : 'Submit Claim',
                          options: FFButtonOptions(
                            width: double.infinity,
                            height: 56.0,
                            color: FlutterFlowTheme.of(context).primary,
                            textStyle: FlutterFlowTheme.of(context)
                                .titleSmall
                                .override(
                                  font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600),
                                  color: FlutterFlowTheme.of(context).info,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                ),
                            elevation: 0.0,
                            borderRadius: BorderRadius.circular(12.0),
                            disabledColor:
                                FlutterFlowTheme.of(context).alternate,
                            disabledTextColor:
                                FlutterFlowTheme.of(context).secondaryText,
                          ),
                        ),
                        SizedBox(height: 24.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _businessCard(BusinessesRecord business) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
              color: FlutterFlowTheme.of(context).alternate, width: 1.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You\'re claiming',
                style: FlutterFlowTheme.of(context).labelSmall.override(
                      font: GoogleFonts.plusJakartaSans(),
                      color: FlutterFlowTheme.of(context).secondaryText,
                      letterSpacing: 0.0,
                    ),
              ),
              SizedBox(height: 4.0),
              Text(
                business.businessName,
                style: FlutterFlowTheme.of(context).titleMedium.override(
                      font: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold),
                      color: FlutterFlowTheme.of(context).primaryText,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (business.address.isNotEmpty) ...[
                SizedBox(height: 4.0),
                Text(
                  business.address,
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        font: GoogleFonts.plusJakartaSans(),
                        color: FlutterFlowTheme.of(context).secondaryText,
                        letterSpacing: 0.0,
                      ),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _sectionLabel(String text) => Text(
        text,
        style: FlutterFlowTheme.of(context).titleSmall.override(
              font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              color: FlutterFlowTheme.of(context).primaryText,
              letterSpacing: 0.0,
              fontWeight: FontWeight.bold,
            ),
      );

  Widget _textField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        validator: validator,
        style: FlutterFlowTheme.of(context).bodyMedium.override(
              font: GoogleFonts.plusJakartaSans(),
              color: FlutterFlowTheme.of(context).primaryText,
              letterSpacing: 0.0,
            ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: FlutterFlowTheme.of(context).labelMedium.override(
                font: GoogleFonts.plusJakartaSans(),
                color: FlutterFlowTheme.of(context).secondaryText,
                letterSpacing: 0.0,
              ),
          hintStyle: FlutterFlowTheme.of(context).labelSmall.override(
                font: GoogleFonts.plusJakartaSans(),
                color: FlutterFlowTheme.of(context).hint,
                letterSpacing: 0.0,
              ),
          filled: true,
          fillColor: FlutterFlowTheme.of(context).secondaryBackground,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: FlutterFlowTheme.of(context).alternate, width: 1.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: FlutterFlowTheme.of(context).primary, width: 1.5),
            borderRadius: BorderRadius.circular(12.0),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: FlutterFlowTheme.of(context).error, width: 1.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: FlutterFlowTheme.of(context).error, width: 1.5),
            borderRadius: BorderRadius.circular(12.0),
          ),
          contentPadding:
              EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
        ),
      );

  Widget _switchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
        activeColor: FlutterFlowTheme.of(context).primary,
        title: Text(
          title,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.plusJakartaSans(),
                color: FlutterFlowTheme.of(context).primaryText,
                letterSpacing: 0.0,
              ),
        ),
      );

  /// The whole tile toggles, not just the checkbox - a bare Checkbox is a
  /// ~24pt target, which is under the 44pt minimum and easy to miss.
  Widget _attestationTile() {
    final showError = _model.showAttestationError && !_model.attested;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12.0),
            onTap: () => safeSetState(() {
              _model.attested = !_model.attested;
              if (_model.attested) _model.showAttestationError = false;
            }),
            child: Container(
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: showError
                      ? FlutterFlowTheme.of(context).error
                      : _model.attested
                          ? FlutterFlowTheme.of(context).primary
                          : FlutterFlowTheme.of(context).alternate,
                  width: (_model.attested || showError) ? 1.5 : 1.0,
                ),
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(4.0, 8.0, 12.0, 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ignores its own pointer events so the tap always resolves
                    // to the InkWell above rather than racing it in the arena.
                    IgnorePointer(
                      child: Checkbox(
                        value: _model.attested,
                        activeColor: FlutterFlowTheme.of(context).primary,
                        onChanged: (_) {},
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            0.0, 12.0, 0.0, 12.0),
                        child: Text(
                          'I confirm I am the owner of this business or am '
                          'authorized to act on its behalf, and that the '
                          'information I\'ve given is accurate.',
                          style: FlutterFlowTheme.of(context)
                              .bodySmall
                              .override(
                                font: GoogleFonts.plusJakartaSans(),
                                color: FlutterFlowTheme.of(context).primaryText,
                                letterSpacing: 0.0,
                                lineHeight: 1.4,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showError) ...[
          SizedBox(height: 8.0),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(4.0, 0.0, 0.0, 0.0),
            child: Text(
              'Please confirm the statement above before submitting your claim.',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    font: GoogleFonts.plusJakartaSans(),
                    color: FlutterFlowTheme.of(context).error,
                    letterSpacing: 0.0,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}
