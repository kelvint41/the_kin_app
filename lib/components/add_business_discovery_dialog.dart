import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/form_field_controller.dart';
import '/services/kin_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kDiscoveryCategories = [
  'Salon & Beauty',
  'Restaurant & Food',
  'Retail',
  'Professional Services',
  'Health & Wellness',
];

/// "Add a Business" flow - the discovery event that
/// businesses_discovered_count (and mystery_reward_engine.js) tracks toward
/// the 5/15/30 reward milestones. Opened as a bottom sheet from the owner
/// dashboard, same convention as AiMarketingSheetWidget.
class AddBusinessDiscoveryDialog extends StatefulWidget {
  const AddBusinessDiscoveryDialog({super.key});

  @override
  State<AddBusinessDiscoveryDialog> createState() =>
      _AddBusinessDiscoveryDialogState();
}

class _AddBusinessDiscoveryDialogState
    extends State<AddBusinessDiscoveryDialog> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _categoryController =
      FormFieldController<String>(_kDiscoveryCategories.first);

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    if (name.isEmpty || address.isEmpty) {
      setState(() => _error = 'Business name and address are required.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await KinServices.submitBusinessDiscovery(
      businessName: name,
      address: address,
      category: _categoryController.value ?? _kDiscoveryCategories.first,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.isSuccess) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Thanks for growing the directory!'),
      ));
    } else {
      setState(() => _error = result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(theme.designToken.radius.lg),
          topRight: Radius.circular(theme.designToken.radius.lg),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          theme.designToken.spacing.lg,
          theme.designToken.spacing.md,
          theme.designToken.spacing.lg,
          MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              theme.designToken.spacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.0,
                height: 4.0,
                margin: EdgeInsets.only(bottom: theme.designToken.spacing.md),
                decoration: BoxDecoration(
                  color: theme.alternate,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.explore_rounded, color: theme.primaryText, size: 20.0),
                SizedBox(width: theme.designToken.spacing.xs),
                Text(
                  'Add a Business',
                  style: theme.titleMedium.override(
                    font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold),
                    color: theme.primaryText,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.0,
                  ),
                ),
              ],
            ),
            SizedBox(height: theme.designToken.spacing.xs),
            Text(
              'Found a business that belongs in KINDEX? Add it here. '
              'Every 5 discoveries unlocks a mystery reward.',
              style: theme.bodySmall.override(color: theme.secondaryText),
            ),
            SizedBox(height: theme.designToken.spacing.md),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Business name',
                hintStyle: theme.bodySmall.override(color: theme.hint),
                filled: true,
                fillColor: theme.secondaryBackground,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(theme.designToken.radius.sm),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.all(theme.designToken.spacing.sm),
              ),
              style: theme.bodyMedium.override(color: theme.primaryText),
            ),
            SizedBox(height: theme.designToken.spacing.sm),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'Address',
                hintStyle: theme.bodySmall.override(color: theme.hint),
                filled: true,
                fillColor: theme.secondaryBackground,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(theme.designToken.radius.sm),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.all(theme.designToken.spacing.sm),
              ),
              style: theme.bodyMedium.override(color: theme.primaryText),
            ),
            SizedBox(height: theme.designToken.spacing.sm),
            FlutterFlowDropDown<String>(
              controller: _categoryController,
              options: _kDiscoveryCategories,
              onChanged: (val) => setState(() {}),
              width: double.infinity,
              height: 44.0,
              textStyle: theme.bodyMedium.override(color: theme.primaryText),
              hintText: 'Category',
              fillColor: theme.secondaryBackground,
              elevation: 2.0,
              borderColor: Colors.transparent,
              borderRadius: theme.designToken.radius.sm,
              borderWidth: 0.0,
              margin: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
            ),
            if (_error != null) ...[
              SizedBox(height: theme.designToken.spacing.sm),
              Text(
                _error!,
                style: theme.bodySmall.override(color: theme.error),
              ),
            ],
            SizedBox(height: theme.designToken.spacing.md),
            FFButtonWidget(
              onPressed: _submitting ? null : _submit,
              text: _submitting ? 'Submitting...' : 'Submit Discovery',
              icon: _submitting
                  ? null
                  : const Icon(Icons.add_location_alt_rounded, size: 18.0),
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
          ],
        ),
      ),
    );
  }
}
