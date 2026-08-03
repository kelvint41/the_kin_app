import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/job_board_service.dart';

/// Post a job.
///
/// Two rules shape this form:
///
///  1. **Pay is required, with no "negotiable" escape hatch.** "Every job on
///     KIN says what it pays" only holds if there is no way to opt out - the
///     moment one exists it becomes the default. The pay-type selector is
///     what makes that liveable: a salaried manager, a commission stylist
///     and a server on tips all fit without anyone inventing an hourly range.
///  2. **KIN never takes a resume.** The owner picks how candidates reach
///     them - in-app thread, their own email, or their own site - so
///     applicant files never touch this app. See JobBoardService.applyMethods.
class JobCreatePage extends StatefulWidget {
  final String businessId;

  const JobCreatePage({super.key, required this.businessId});

  @override
  State<JobCreatePage> createState() => _JobCreatePageState();
}

class _JobCreatePageState extends State<JobCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final requirementsController = TextEditingController();
  final addressController = TextEditingController();
  final rateMinController = TextEditingController();
  final rateMaxController = TextEditingController();
  final applyEmailController = TextEditingController();
  final applyUrlController = TextEditingController();

  String jobType = 'part_time';
  String workLocation = 'on_site';
  String payType = 'hourly';
  String applyMethod = 'in_app';
  bool isSingleRate = false;
  bool isCreating = false;

  /// A street address is meaningless for a fully remote role, so it is only
  /// required for on-site and hybrid.
  bool get _addressRequired => workLocation != 'remote';

  /// What the min/max boxes are actually measuring, so the labels tell the
  /// truth for whichever pay type is selected.
  String get _payUnit {
    switch (payType) {
      case 'salary':
        return 'per year';
      case 'commission':
        return '% or amount';
      default:
        return 'per hour';
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    requirementsController.dispose();
    addressController.dispose();
    rateMinController.dispose();
    rateMaxController.dispose();
    applyEmailController.dispose();
    applyUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isCreating = true);
    try {
      final min = double.tryParse(rateMinController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      final max = isSingleRate
          ? min
          : double.tryParse(rateMaxController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

      await JobBoardService.createJobPosting(
        businessRef: widget.businessId,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        requirements: requirementsController.text.trim(),
        jobType: jobType,
        workLocation: workLocation,
        address: addressController.text.trim(),
        payType: payType,
        rateMin: min,
        rateMax: max,
        isSingleRate: isSingleRate,
        applyMethod: applyMethod,
        applyEmail: applyEmailController.text.trim(),
        applyUrl: applyUrlController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't post that job. Try again.")),
      );
    }
  }

  InputDecoration _dec(FlutterFlowTheme theme, String label,
      {bool required = false, String? hint}) {
    return InputDecoration(
      label: RichText(
        text: TextSpan(
          text: label,
          style: theme.labelSmall,
          children: required
              ? [TextSpan(text: ' *', style: theme.labelSmall.override(color: theme.error))]
              : null,
        ),
      ),
      hintText: hint,
      hintStyle: theme.labelSmall,
      alignLabelWithHint: true,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: theme.alternate),
        borderRadius: BorderRadius.circular(8.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: theme.primary, width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.primary,
          automaticallyImplyLeading: true,
          title: Text(
            'Post a Job',
            style: theme.headlineMedium.override(
              font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              color: theme.info,
            ),
          ),
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fields marked * are required',
                      style: theme.bodySmall.override(color: theme.secondaryText)),
                  const SizedBox(height: 16.0),

                  TextFormField(
                    controller: titleController,
                    decoration: _dec(theme, 'Job title', required: true, hint: 'Line cook'),
                    style: theme.bodyMedium,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Add a job title' : null,
                  ),
                  const SizedBox(height: 16.0),

                  DropdownButtonFormField<String>(
                    value: jobType,
                    decoration: _dec(theme, 'Job type', required: true),
                    items: const [
                      DropdownMenuItem(value: 'part_time', child: Text('Part-time')),
                      DropdownMenuItem(value: 'full_time', child: Text('Full-time')),
                      DropdownMenuItem(value: 'contract', child: Text('Contract')),
                      DropdownMenuItem(value: 'seasonal', child: Text('Seasonal')),
                    ],
                    onChanged: (v) => setState(() => jobType = v ?? 'part_time'),
                  ),
                  const SizedBox(height: 16.0),

                  DropdownButtonFormField<String>(
                    value: workLocation,
                    decoration: _dec(theme, 'Work location', required: true),
                    items: JobBoardService.workLocations.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => workLocation = v ?? 'on_site'),
                  ),
                  const SizedBox(height: 16.0),

                  TextFormField(
                    controller: addressController,
                    decoration: _dec(
                      theme,
                      _addressRequired ? 'Address' : 'Address (optional for remote)',
                      required: _addressRequired,
                      hint: '1438 S Presa St, San Antonio',
                    ),
                    style: theme.bodyMedium,
                    validator: (v) => (_addressRequired && (v == null || v.trim().isEmpty))
                        ? 'Add where the work happens'
                        : null,
                  ),
                  const SizedBox(height: 24.0),

                  // Pay block, visually grouped because it's the one thing
                  // this board refuses to let an owner skip.
                  Container(
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pay *',
                            style: theme.titleSmall.override(
                                color: theme.primary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4.0),
                        Text('Every job on KIN shows what it pays.',
                            style:
                                theme.labelSmall.override(color: theme.secondaryText)),
                        const SizedBox(height: 12.0),
                        DropdownButtonFormField<String>(
                          value: payType,
                          decoration: _dec(theme, 'Pay type', required: true),
                          items: JobBoardService.payTypes.entries
                              .map((e) =>
                                  DropdownMenuItem(value: e.key, child: Text(e.value)))
                              .toList(),
                          onChanged: (v) => setState(() => payType = v ?? 'hourly'),
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: rateMinController,
                                keyboardType: TextInputType.number,
                                decoration: _dec(
                                    theme, isSingleRate ? 'Rate' : 'Minimum',
                                    required: true, hint: _payUnit),
                                style: theme.bodyMedium,
                                validator: (v) {
                                  final n = double.tryParse(
                                      (v ?? '').replaceAll(RegExp(r'[^0-9.]'), ''));
                                  if (n == null || n <= 0) return 'Required';
                                  return null;
                                },
                              ),
                            ),
                            if (!isSingleRate) ...[
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: TextFormField(
                                  controller: rateMaxController,
                                  keyboardType: TextInputType.number,
                                  decoration: _dec(theme, 'Maximum',
                                      required: true, hint: _payUnit),
                                  style: theme.bodyMedium,
                                  validator: (v) {
                                    final n = double.tryParse(
                                        (v ?? '').replaceAll(RegExp(r'[^0-9.]'), ''));
                                    if (n == null || n <= 0) return 'Required';
                                    final min = double.tryParse(rateMinController.text
                                        .replaceAll(RegExp(r'[^0-9.]'), ''));
                                    if (min != null && n < min) {
                                      return 'Below minimum';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                        CheckboxListTile(
                          value: isSingleRate,
                          onChanged: (v) => setState(() => isSingleRate = v ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text('Single fixed rate (no range)',
                              style: theme.bodySmall),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  TextFormField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: _dec(theme, 'Description',
                        required: true, hint: 'What the role involves day to day'),
                    style: theme.bodyMedium,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Describe the role'
                        : null,
                  ),
                  const SizedBox(height: 16.0),

                  TextFormField(
                    controller: requirementsController,
                    maxLines: 3,
                    decoration: _dec(theme, 'Requirements',
                        hint: 'Experience, certifications, availability'),
                    style: theme.bodyMedium,
                  ),
                  const SizedBox(height: 24.0),

                  Text('How candidates reach you *',
                      style: theme.titleSmall.override(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4.0),
                  Text('KIN never stores resumes or applicant files.',
                      style: theme.labelSmall.override(color: theme.secondaryText)),
                  const SizedBox(height: 8.0),
                  ...JobBoardService.applyMethods.entries.map(
                    (e) => RadioListTile<String>(
                      value: e.key,
                      groupValue: applyMethod,
                      onChanged: (v) => setState(() => applyMethod = v ?? 'in_app'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(e.value, style: theme.bodyMedium),
                    ),
                  ),
                  if (applyMethod == 'email')
                    TextFormField(
                      controller: applyEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _dec(theme, 'Your hiring email',
                          required: true, hint: 'hiring@yourbusiness.com'),
                      style: theme.bodyMedium,
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Add an email';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
                          return 'Check that email';
                        }
                        return null;
                      },
                    ),
                  if (applyMethod == 'website')
                    TextFormField(
                      controller: applyUrlController,
                      keyboardType: TextInputType.url,
                      decoration: _dec(theme, 'Application page',
                          required: true, hint: 'https://yourbusiness.com/careers'),
                      style: theme.bodyMedium,
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Add a link';
                        final uri = Uri.tryParse(s);
                        if (uri == null || !uri.isScheme('HTTPS') && !uri.isScheme('HTTP')) {
                          return 'Start with https://';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 32.0),

                  FFButtonWidget(
                    onPressed: isCreating ? null : _submit,
                    text: isCreating ? 'Posting...' : 'Post Job',
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 56.0,
                      color: theme.primary,
                      textStyle: theme.titleSmall.override(
                        font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                        color: theme.info,
                      ),
                      elevation: 0.0,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
