import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_place_picker.dart';
import '/flutter_flow/form_field_controller.dart';
import '/services/kin_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Same key already used by FlutterFlowPlacePicker on the Business Setup
// page (business_setup_page_widget.dart) - kept identical rather than
// introducing a second copy of it.
const _kGoogleMapsApiKey = 'AIzaSyD1w4m7IaWva5Bxl9fsbsZgILC7R8wf_Go';

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
  final _otherCategoryController = TextEditingController();
  final _categoryController =
      FormFieldController<String>(_kDiscoveryCategories.first);

  // Set only when the owner picks a place via FlutterFlowPlacePicker rather
  // than typing an address by hand - hand-typed addresses (e.g. a business
  // not yet indexed by Google Places) still submit fine, just without
  // coordinates, same as submitCustomerBusinessDiscovery already tolerates.
  double? _latitude;
  double? _longitude;

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _otherCategoryController.dispose();
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

    final otherCategory = _otherCategoryController.text.trim();
    final effectiveCategory = otherCategory.isNotEmpty
        ? otherCategory
        : (_categoryController.value ?? _kDiscoveryCategories.first);
    if (otherCategory.isNotEmpty) {
      await KinServices.ensureBusinessCategoryExists(otherCategory);
    }

    // An admin adding a business is the review - they're typically standing
    // in front of it with the owner's card. Skip the queue and publish, so
    // the owner can be shown their live listing and claim it on the spot.
    // Everyone else's submission still queues for review.
    //
    // Requires real coordinates: without them the listing has no geohash
    // and would never appear on the map (see adminCreateBusiness), so a
    // hand-typed address that was never resolved through the place picker
    // falls back to the normal queue rather than publishing something
    // invisible.
    final isAdmin = currentUserDocument?.isAdmin == true;
    final hasCoords = _latitude != null && _longitude != null;

    if (isAdmin && hasCoords) {
      final created = await KinServices.adminCreateBusiness(
        businessName: name,
        address: address,
        category: effectiveCategory,
        latitude: _latitude!,
        longitude: _longitude!,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      if (!created.isSuccess) {
        setState(() => _error = created.error);
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name is live on the map. They can claim it now.'),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final result = await KinServices.submitBusinessDiscovery(
      businessName: name,
      address: address,
      category: effectiveCategory,
      latitude: _latitude,
      longitude: _longitude,
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
                // Lets an owner standing at the business search/select it
                // instead of typing the address by hand, and captures real
                // coordinates in the same step - typing is still available
                // for a business Google Places doesn't have indexed yet.
                suffixIcon: FlutterFlowPlacePicker(
                  iOSGoogleMapsApiKey: _kGoogleMapsApiKey,
                  androidGoogleMapsApiKey: _kGoogleMapsApiKey,
                  webGoogleMapsApiKey: _kGoogleMapsApiKey,
                  defaultText: '',
                  // accentOnSurface, not primary/info - this icon sits
                  // directly on secondaryBackground, and both of those
                  // alternatives break in one mode (primary's dark green
                  // nearly disappears on dark mode's #242424 card; info's
                  // white nearly disappears on light mode's white card).
                  // See the light-mode-text-token-bug-class memory.
                  icon: Icon(Icons.my_location_rounded,
                      color: theme.accentOnSurface, size: 20.0),
                  onSelect: (place) {
                    setState(() {
                      _addressController.text = place.address;
                      _latitude = place.latLng.latitude;
                      _longitude = place.latLng.longitude;
                    });
                  },
                  buttonOptions: FFButtonOptions(
                    width: 40.0,
                    height: 40.0,
                    padding: EdgeInsets.zero,
                    color: Colors.transparent,
                    elevation: 0.0,
                    borderRadius:
                        BorderRadius.circular(theme.designToken.radius.sm),
                  ),
                ),
              ),
              style: theme.bodyMedium.override(color: theme.primaryText),
            ),
            SizedBox(height: theme.designToken.spacing.sm),
            StreamBuilder<List<BusinessCategoriesRecord>>(
              stream: queryBusinessCategoriesRecord(
                queryBuilder: (q) => q.orderBy('display_name'),
              ),
              builder: (context, snapshot) {
                final categoryOptions =
                    snapshot.hasData && snapshot.data!.isNotEmpty
                        ? snapshot.data!.map((c) => c.displayName).toList()
                        : _kDiscoveryCategories;
                return FlutterFlowDropDown<String>(
                  controller: _categoryController,
                  options: categoryOptions,
                  onChanged: (val) => setState(() {}),
                  width: double.infinity,
                  height: 44.0,
                  textStyle:
                      theme.bodyMedium.override(color: theme.primaryText),
                  hintText: 'Category',
                  fillColor: theme.secondaryBackground,
                  elevation: 2.0,
                  borderColor: Colors.transparent,
                  borderRadius: theme.designToken.radius.sm,
                  borderWidth: 0.0,
                  margin:
                      EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
                );
              },
            ),
            SizedBox(height: theme.designToken.spacing.sm),
            TextFormField(
              controller: _otherCategoryController,
              decoration: InputDecoration(
                hintText: "Don't see your category? Type a new one",
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
