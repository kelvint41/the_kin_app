import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/main_menu_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/kin_services.dart';
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

  // Mirrors the App Studio pricing ladder. This drives the automatic
  // target_delivery_date a Cloud Function stamps on the request - see
  // scheduleAgencyQueueTarget - so the values here must match its
  // DELIVERY_WINDOW_DAYS keys exactly.
  static const _tierLevels = [
    'Not sure yet',
    'Single page',
    'Business site',
    'Site with booking',
    'Essential',
    'Professional',
    'Advanced',
  ];

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _businessController = TextEditingController();
  final _briefController = TextEditingController();
  final _logoStyleController = TextEditingController();
  final _logoColorController = TextEditingController();

  String _type = _projectTypes.first;
  String _budget = _budgets.first;
  String _tier = _tierLevels.first;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  // The form used to be a single 700px-tall column of every field at once -
  // reasonable in scope (11 inputs is not unusual for an intake form) but
  // it read as one undifferentiated wall of boxes with no sense of
  // progress. Splitting the same fields across 3 focused steps (About you /
  // Your project / Design) gives each screen one job instead of all of them
  // at once - no fields were removed or made optional that weren't already.
  int _step = 0;
  static const int _stepCount = 3;
  static const _stepTitles = ['About you', 'Your project', 'Design'];

  // File uploads and logo service
  List<String> _uploadedFiles = [];
  bool _needsLogoDesign = false;

  // AI logo preview generation - independent of the main _sending/_error
  // pair above, since generating previews and submitting the request are
  // two different actions a visitor can do in either order.
  bool _generatingLogos = false;
  List<String> _logoPreviewUrls = [];
  String? _logoPreviewError;

  // Asked once per page visit rather than persisted - re-generating after a
  // first accepted disclosure isn't a new decision, but leaving the app and
  // coming back to Studio later is.
  bool _aiConsentGiven = false;

  static const int _minDescriptionLength = 150;

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
    _logoStyleController.dispose();
    _logoColorController.dispose();
    super.dispose();
  }

  bool get _hasValidContact {
    final email = _emailController.text.trim();
    return _nameController.text.trim().isNotEmpty &&
        email.contains('@') &&
        email.length >= 5;
  }

  bool get _hasValidBrief =>
      _briefController.text.trim().length >= _minDescriptionLength;

  /// Whether step [step] is complete enough to move past. Design (step 2)
  /// has nothing required - every field on it already says "(optional)" -
  /// so only the first two steps gate.
  bool _stepIsValid(int step) {
    switch (step) {
      case 0:
        return _hasValidContact;
      case 1:
        return _hasValidBrief;
      default:
        return true;
    }
  }

  // Only shown after a blocked attempt to advance, not proactively on a
  // fresh step - nagging someone before they've typed anything is worse
  // than saying nothing.
  bool _showStepError = false;

  void _goNext() {
    if (!_stepIsValid(_step)) {
      setState(() => _showStepError = true);
      return;
    }
    if (_step < _stepCount - 1) {
      setState(() {
        _step += 1;
        _showStepError = false;
      });
    } else {
      _submit();
    }
  }

  void _goBack() {
    if (_step > 0) {
      setState(() {
        _step -= 1;
        _showStepError = false;
      });
    }
  }

  /// Whether the main form fields are valid enough to request logo
  /// previews - same bar as [_submit] checks before writing to
  /// agency_queue, so a preview is never generated for a request that
  /// couldn't be sent anyway.
  bool get _canGeneratePreviews => _hasValidContact && _hasValidBrief;

  /// Discloses that the brief/business name/style inputs are about to be
  /// sent to a third-party AI image model before any of them leave the
  /// device. Required before [_generateLogoPreviews] is allowed to call
  /// [KinServices.generateAppStudioLogos].
  Future<bool> _confirmAiConsent() async {
    if (_aiConsentGiven) return true;
    final theme = FlutterFlowTheme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.secondaryBackground,
        title: Text('Generate logo previews with AI?', style: theme.titleMedium),
        content: Text(
          'The business name, brief, and style/color preferences you\'ve '
          'entered will be sent to a third-party AI image model (Google '
          'Imagen) to generate logo previews. Please don\'t include '
          'anything you don\'t want processed by an external AI service.',
          style: theme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: theme.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Continue',
              style: theme.bodyMedium.override(color: theme.primary),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    _aiConsentGiven = true;
    return true;
  }

  Future<void> _generateLogoPreviews() async {
    if (!_canGeneratePreviews || _generatingLogos) return;
    if (!await _confirmAiConsent()) return;
    if (!mounted) return;
    setState(() {
      _generatingLogos = true;
      _logoPreviewError = null;
    });

    final result = await KinServices.generateAppStudioLogos(
      contactName: _nameController.text.trim(),
      contactEmail: _emailController.text.trim(),
      brief: _briefController.text.trim(),
      businessName: _businessController.text.trim(),
      style: _logoStyleController.text.trim(),
      colorPreference: _logoColorController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _generatingLogos = false;
      if (result.isSuccess) {
        _logoPreviewUrls = result.data!;
      } else {
        _logoPreviewError = result.error;
      }
    });
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
    if (brief.length < _minDescriptionLength) {
      setState(() =>
          _error = 'Please provide more detail - at least 150 characters. '
              'Tell us about features, pages, who it\'s for, and any examples you like. '
              'The more specific you are, the better our estimate will be.');
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
            tierLevel: _tier,
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
        title: Text(
          'KIN App Studio',
          style: theme.titleMedium.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            color: theme.primaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: MainMenuButton(),
          )
        ],
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

  // Was one 700px column of all 11 fields at once. Split into three focused
  // steps - the fields themselves are unchanged, just grouped by what
  // they're actually for, with a Back/Continue pair replacing the single
  // giant scroll. Design (step 2) keeps its own scroll since the AI logo
  // previews can grow that step tall.
  Widget _form(FlutterFlowTheme theme) => Column(
        children: [
          _stepHeader(theme),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_step == 0) _stepAbout(theme),
                  if (_step == 1) _stepProject(theme),
                  if (_step == 2) _stepDesign(theme),
                ],
              ),
            ),
          ),
          _stepNav(theme),
        ],
      );

  Widget _stepHeader(FlutterFlowTheme theme) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step ${_step + 1} of $_stepCount · ${_stepTitles[_step]}',
              style: theme.labelMedium.override(
                font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                color: theme.secondaryText,
                letterSpacing: 0.0,
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                for (var i = 0; i < _stepCount; i++) ...[
                  if (i > 0) const SizedBox(width: 6.0),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999.0),
                      child: Container(
                        height: 4.0,
                        color: i <= _step ? theme.accent1 : theme.alternate,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );

  Widget _stepNav(FlutterFlowTheme theme) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          border: Border(top: BorderSide(color: theme.alternate)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showStepError && !_stepIsValid(_step))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _step == 0
                        ? 'Please enter your name and a valid email to continue.'
                        : 'Please describe your project in at least '
                            '$_minDescriptionLength characters to continue.',
                    style: theme.bodySmall.override(
                      font: GoogleFonts.plusJakartaSans(),
                      color: theme.error,
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _error!,
                    style: theme.bodySmall.override(
                      font: GoogleFonts.plusJakartaSans(),
                      color: theme.error,
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
              Row(
                children: [
                  if (_step > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _sending ? null : _goBack,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          side: BorderSide(color: theme.alternate),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: Text(
                          'Back',
                          style: theme.labelMedium.override(
                            font: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600),
                            color: theme.primaryText,
                            letterSpacing: 0.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                  ],
                  Expanded(
                    flex: 2,
                    child: FFButtonWidget(
                      onPressed: _sending ? null : _goNext,
                      text: _sending
                          ? 'Sending...'
                          : (_step == _stepCount - 1
                              ? 'Send my request'
                              : 'Continue'),
                      options: FFButtonOptions(
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
                ],
              ),
            ],
          ),
        ),
      );

  Widget _stepAbout(FlutterFlowTheme theme) => Column(
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
          const SizedBox(height: 14.0),
          _field(theme, 'Your name', _nameController),
          const SizedBox(height: 14.0),
          _field(theme, 'Email', _emailController,
              keyboard: TextInputType.emailAddress),
          const SizedBox(height: 14.0),
          _field(theme, 'Business name (optional)', _businessController),
        ],
      );

  Widget _stepProject(FlutterFlowTheme theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _dropdown(theme, 'What kind of app?', _projectTypes, _type,
              (v) => setState(() => _type = v)),
          const SizedBox(height: 14.0),
          _dropdown(theme, 'Which package?', _tierLevels, _tier,
              (v) => setState(() => _tier = v)),
          const SizedBox(height: 14.0),
          _dropdown(theme, 'Budget', _budgets, _budget,
              (v) => setState(() => _budget = v)),
          const SizedBox(height: 14.0),
          _field(theme, 'What should it do?', _briefController,
              maxLines: 8,
              maxLength: 2000,
              helperText:
                  'Required: At least 150 characters. Be very specific - '
                  'what features do you need? What pages? Who is it for? '
                  'Any examples or references? More detail = faster, better estimates.'),
        ],
      );

  Widget _stepDesign(FlutterFlowTheme theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // File upload section
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: theme.alternate),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.upload_file_rounded,
                        color: theme.accentOnSurface, size: 20.0),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Design files (optional)',
                        style: theme.labelMedium.override(
                          font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600),
                          color: theme.primaryText,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Do you have existing designs, logos, mockups, or references? '
                  'Upload them here so we can understand your vision better.',
                  style: theme.bodySmall.override(
                    font: GoogleFonts.plusJakartaSans(),
                    color: theme.secondaryText,
                    letterSpacing: 0.0,
                    lineHeight: 1.4,
                  ),
                ),
                const SizedBox(height: 10.0),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: theme.primaryBackground,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                        color: theme.alternate, style: BorderStyle.solid),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          color: theme.secondaryText, size: 32.0),
                      const SizedBox(height: 8.0),
                      Text(
                        _uploadedFiles.isEmpty
                            ? 'Tap to upload design files'
                            : '${_uploadedFiles.length} file(s) selected',
                        style: theme.bodySmall.override(
                          font: GoogleFonts.plusJakartaSans(),
                          color: theme.secondaryText,
                          letterSpacing: 0.0,
                        ),
                      ),
                      if (_uploadedFiles.isNotEmpty) ...[
                        const SizedBox(height: 8.0),
                        Wrap(
                          spacing: 4.0,
                          runSpacing: 4.0,
                          children: _uploadedFiles
                              .map((file) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 4.0),
                                    decoration: BoxDecoration(
                                      color: theme.accent1,
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                    child: Text(
                                      file.split('/').last,
                                      style: theme.labelSmall.override(
                                        font: GoogleFonts.plusJakartaSans(),
                                        color: theme.primary,
                                        fontSize: 11.0,
                                        letterSpacing: 0.0,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Supported: Images (PNG, JPG), PDFs, Figma links, or Sketch files',
                  style: theme.labelSmall.override(
                    font: GoogleFonts.plusJakartaSans(),
                    color: theme.secondaryText,
                    fontSize: 11.0,
                    letterSpacing: 0.0,
                  ),
                ),
              ],
            ),
          ),
          // Logo design service checkbox
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: theme.alternate),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _needsLogoDesign,
                      onChanged: (v) =>
                          setState(() => _needsLogoDesign = v ?? false),
                      fillColor: WidgetStateProperty.all(_needsLogoDesign
                          ? theme.accent1
                          : Colors.transparent),
                      side: BorderSide(
                        color: theme.alternate,
                        width: 1.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'I need logo design',
                            style: theme.labelMedium.override(
                              font: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600),
                              color: theme.primaryText,
                              letterSpacing: 0.0,
                            ),
                          ),
                          Text(
                            'Standalone: \$75-150 | Bundled with app: Included',
                            style: theme.labelSmall.override(
                              font: GoogleFonts.plusJakartaSans(),
                              color: theme.accentOnSurface,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Need just a logo? We create custom, AI-enhanced designs. '
                  'Want it with your app? Logo design is included in your package.',
                  style: theme.bodySmall.override(
                    font: GoogleFonts.plusJakartaSans(),
                    color: theme.secondaryText,
                    letterSpacing: 0.0,
                    lineHeight: 1.4,
                  ),
                ),
                if (_needsLogoDesign) ...[
                  const SizedBox(height: 12.0),
                  Divider(color: theme.alternate, height: 1.0),
                  const SizedBox(height: 12.0),
                  _field(theme, 'Style / vibe (e.g. modern, playful, classic)',
                      _logoStyleController),
                  const SizedBox(height: 10.0),
                  _field(theme, 'Preferred colors (optional)',
                      _logoColorController),
                  const SizedBox(height: 10.0),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: (_canGeneratePreviews && !_generatingLogos)
                          ? _generateLogoPreviews
                          : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        side: BorderSide(color: theme.accentOnSurface),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: _generatingLogos
                          ? SizedBox(
                              width: 18.0,
                              height: 18.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.accentOnSurface),
                              ),
                            )
                          : Text(
                              'Generate logo previews',
                              style: theme.labelMedium.override(
                                font: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600),
                                color: theme.accentOnSurface,
                                letterSpacing: 0.0,
                              ),
                            ),
                    ),
                  ),
                  if (!_canGeneratePreviews && !_generatingLogos) ...[
                    const SizedBox(height: 6.0),
                    Text(
                      'Fill in your name, email, and a project brief of '
                      'at least $_minDescriptionLength characters above to '
                      'unlock previews.',
                      style: theme.labelSmall.override(
                        font: GoogleFonts.plusJakartaSans(),
                        color: theme.secondaryText,
                        fontSize: 11.0,
                        letterSpacing: 0.0,
                      ),
                    ),
                  ],
                  if (_logoPreviewError != null) ...[
                    const SizedBox(height: 8.0),
                    Text(
                      _logoPreviewError!,
                      style: theme.bodySmall.override(
                        font: GoogleFonts.plusJakartaSans(),
                        color: theme.error,
                        letterSpacing: 0.0,
                      ),
                    ),
                  ],
                  if (_logoPreviewUrls.isNotEmpty) ...[
                    const SizedBox(height: 12.0),
                    SizedBox(
                      height: 120.0,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _logoPreviewUrls.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 10.0),
                        itemBuilder: (context, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.network(
                            _logoPreviewUrls[i],
                            width: 120.0,
                            height: 120.0,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Container(
                              width: 120.0,
                              height: 120.0,
                              color: theme.primaryBackground,
                              alignment: Alignment.center,
                              child: Icon(Icons.broken_image_outlined,
                                  color: theme.secondaryText),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          // No card details are taken anywhere on this page: a build is a
          // real-world service delivered outside the app, so submitting
          // this form is not an in-app purchase - it's a request that gets
          // a follow-up quote, not a charge. Error and submit now live in
          // _stepNav, shared across all three steps.
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: theme.alternate),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded,
                    color: theme.accentOnSurface, size: 20.0),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 0, 0),
                    child: Text(
                      'Nothing is charged today. We\'ll follow up with '
                      'pricing and next steps once the studio opens.',
                      style: theme.bodySmall.override(
                        font: GoogleFonts.plusJakartaSans(),
                        color: theme.secondaryText,
                        letterSpacing: 0.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ].divide(const SizedBox(height: 14.0)),
      );

  Widget _field(
    FlutterFlowTheme theme,
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboard,
    String? helperText,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboard,
        // Re-evaluates _canGeneratePreviews as the visitor types, so the
        // "Generate logo previews" button (and its "fill in the form"
        // hint) reflect the current field values rather than whatever they
        // were on the last unrelated rebuild.
        onChanged: (_) => setState(() {}),
        style: theme.bodyMedium.override(
          font: GoogleFonts.plusJakartaSans(),
          color: theme.primaryText,
          letterSpacing: 0.0,
        ),
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          helperMaxLines: 3,
          labelStyle: theme.labelMedium.override(
            font: GoogleFonts.plusJakartaSans(),
            color: theme.secondaryText,
            letterSpacing: 0.0,
          ),
          helperStyle: theme.bodySmall.override(
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
