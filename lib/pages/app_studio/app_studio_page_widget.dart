import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "KIN App Studio" - request a custom app build.
///
/// Deliberately reachable without an account. `FFRoute.requireAuth`
/// defaults to false and only two routes set it, so a public page costs
/// nothing architecturally - and this offer is explicitly open to people
/// who are not on KIN at all, which is most of the people who might buy it.
///
/// Writes into `agency_queue`, which was schema'd as a delivery pipeline -
/// project_type, tier_level, current_status, current_step,
/// target_delivery_date, assigned_editor - and never given a front door, so
/// nothing could ever enter it. This is that front door; the pipeline
/// fields it already has are what an admin moves a project through
/// afterwards.
///
/// What this page does NOT do, on purpose: take payment. Capturing demand
/// costs nothing and is worth having on day one - knowing who wants what,
/// and what they say they'd spend, is the thing that prices the offer.
/// Charging for it can wait until there is something to deliver.
class AppStudioPageWidget extends StatefulWidget {
  const AppStudioPageWidget({super.key});

  static String routeName = 'AppStudioPage';
  static String routePath = '/appStudio';

  @override
  State<AppStudioPageWidget> createState() => _AppStudioPageWidgetState();
}

class _AppStudioPageWidgetState extends State<AppStudioPageWidget> {
  static const _projectTypes = [
    'Booking / appointments',
    'Online ordering',
    'Loyalty / rewards',
    'Storefront or catalogue',
    'Something else',
  ];

  static const _budgets = [
    'Not sure yet',
    'Under \$1,000',
    '\$1,000 - \$5,000',
    '\$5,000+',
    'Included with my Elite Growth plan',
  ];

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _businessController = TextEditingController();
  final _briefController = TextEditingController();

  String _type = _projectTypes.first;
  String _budget = _budgets.first;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Prefills for anyone already signed in. Left empty for visitors, who
    // are the whole reason this page is public.
    _emailController.text = currentUserEmail;
    _nameController.text = currentUserDisplayName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _businessController.dispose();
    _briefController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final brief = _briefController.text.trim();

    // Mirrors the Firestore rule so a rejection arrives as a sentence
    // rather than a permission error.
    if (!email.contains('@') || email.length < 5) {
      setState(() => _error = 'We need an email address to reply to.');
      return;
    }
    if (brief.length < 20) {
      setState(() => _error =
          'Tell us a bit more - at least a sentence about what you want built.');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await AgencyQueueRecord.collection.doc().set(createAgencyQueueRecordData(
            contactName: _nameController.text.trim(),
            contactEmail: email,
            businessName: _businessController.text.trim(),
            projectType: _type,
            budgetBand: _budget,
            brief: brief,
            // The pipeline starts here; an admin moves it on from `new`.
            currentStatus: 'new',
            currentStep: 0,
            userRef: currentUserReference,
            submittedAt: getCurrentTimestamp,
          ));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Could not send that. Please try again.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.secondaryBackground,
        elevation: 0.0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.accentOnSurface),
          onPressed: () => context.safePop(),
        ),
        title: Text(
          'KIN App Studio',
          style: theme.titleMedium.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            color: theme.primaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _sent ? _thanks(theme) : _form(theme),
      ),
    );
  }

  Widget _thanks(FlutterFlowTheme theme) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: theme.accentOnSurface, size: 56.0),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 20, 0, 8),
                child: Text(
                  'Got it.',
                  style: theme.headlineSmall.override(
                    font: GoogleFonts.playfairDisplay(
                        fontWeight: FontWeight.bold),
                    color: theme.primaryText,
                    letterSpacing: 0.0,
                  ),
                ),
              ),
              Text(
                "You're on the list. We'll read it properly and come back to "
                'you by email when the studio opens - no charge for the '
                'conversation, and no obligation.',
                textAlign: TextAlign.center,
                style: theme.bodyMedium.override(
                  font: GoogleFonts.plusJakartaSans(),
                  color: theme.secondaryText,
                  letterSpacing: 0.0,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _form(FlutterFlowTheme theme) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: theme.alternate),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Says plainly that this is not live yet. Apple's
                  // guideline 2.1 (App Completeness) rejects placeholder
                  // features, but a working waitlist that honestly describes
                  // itself as a waitlist is not a placeholder - it does
                  // exactly what it says. What gets rejected is a button
                  // that does nothing, or a purchase that cannot complete.
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 5.0),
                    decoration: BoxDecoration(
                      color: theme.accent1,
                      borderRadius: BorderRadius.circular(999.0),
                    ),
                    child: Text(
                      'COMING SOON',
                      style: theme.labelSmall.override(
                        font: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold),
                        color: theme.primary,
                        fontSize: 10.0,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Need an app for your business?',
                    style: theme.titleMedium.override(
                      font: GoogleFonts.playfairDisplay(
                          fontWeight: FontWeight.bold),
                      color: theme.accentOnSurface,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 0),
                    child: Text(
                      "We're building a studio that makes simple, useful apps "
                      'and websites for small businesses - booking, ordering, '
                      "loyalty, or something of your own. It isn't open yet, "
                      "but we're taking requests now and working through them "
                      'in order.\n\n'
                      "Tell us what you need and we'll come back with what it "
                      'would take. You do not need a KIN account, and there is '
                      'no charge to ask.',
                      style: theme.bodyMedium.override(
                        font: GoogleFonts.plusJakartaSans(),
                        color: theme.secondaryText,
                        letterSpacing: 0.0,
                        lineHeight: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _field(theme, 'Your name', _nameController),
            _field(theme, 'Email', _emailController,
                keyboard: TextInputType.emailAddress),
            _field(theme, 'Business name (optional)', _businessController),
            _dropdown(theme, 'What kind of app?', _projectTypes, _type,
                (v) => setState(() => _type = v)),
            _dropdown(theme, 'Budget', _budgets, _budget,
                (v) => setState(() => _budget = v)),
            _field(theme, 'What should it do?', _briefController,
                maxLines: 5, maxLength: 2000),
            if (_error != null)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 4, 0, 0),
                child: Text(
                  _error!,
                  style: theme.bodySmall.override(
                    font: GoogleFonts.plusJakartaSans(),
                    color: theme.error,
                    letterSpacing: 0.0,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0, 20, 0, 0),
              child: FFButtonWidget(
                onPressed: _sending ? null : _submit,
                text: _sending ? 'Sending...' : 'Send my request',
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 52.0,
                  color: theme.accent1,
                  textStyle: theme.titleSmall.override(
                    font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold),
                    color: theme.primary,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                  ),
                  elevation: 0.0,
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ].divide(const SizedBox(height: 14.0)),
        ),
      );

  Widget _field(
    FlutterFlowTheme theme,
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboard,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboard,
        style: theme.bodyMedium.override(
          font: GoogleFonts.plusJakartaSans(),
          color: theme.primaryText,
          letterSpacing: 0.0,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.labelMedium.override(
            font: GoogleFonts.plusJakartaSans(),
            color: theme.secondaryText,
            letterSpacing: 0.0,
          ),
          filled: true,
          fillColor: theme.secondaryBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: theme.alternate),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: theme.alternate),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: theme.accentOnSurface),
          ),
        ),
      );

  Widget _dropdown(FlutterFlowTheme theme, String label, List<String> options,
          String value, ValueChanged<String> onChanged) =>
      InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.labelMedium.override(
            font: GoogleFonts.plusJakartaSans(),
            color: theme.secondaryText,
            letterSpacing: 0.0,
          ),
          filled: true,
          fillColor: theme.secondaryBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: theme.alternate),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: theme.alternate),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: theme.secondaryBackground,
            style: theme.bodyMedium.override(
              font: GoogleFonts.plusJakartaSans(),
              color: theme.primaryText,
              letterSpacing: 0.0,
            ),
            items: [
              for (final o in options)
                DropdownMenuItem(value: o, child: Text(o)),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      );
}
