import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_place_picker.dart';
import '/flutter_flow/form_field_controller.dart';
import '/services/geocoding_service.dart';
import '/services/kin_services.dart';
import '/services/nearby_feed.dart' show distanceKm;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Same key as AddBusinessDiscoveryDialog and the Business Setup page - kept
// identical rather than introducing a third copy.
const _kGoogleMapsApiKey = 'AIzaSyD1w4m7IaWva5Bxl9fsbsZgILC7R8wf_Go';

/// How close the submitter has to be to the business for the submission to
/// count as verified on the ground rather than vouched-for remotely.
const _kOnSiteRadiusMeters = 250.0;

/// Reuses the same haversine the nearby feed uses, so "close by" means the
/// same thing here as everywhere else in the app.
double _metersBetween(double lat1, double lng1, double lat2, double lng2) =>
    distanceKm(lat1, lng1, lat2, lng2) * 1000;

const _kDiscoveryCategories = [
  'Salon & Beauty',
  'Restaurant & Food',
  'Retail',
  'Professional Services',
  'Health & Wellness',
];

/// Customer-side counterpart to [AddBusinessDiscoveryDialog] - opened from
/// the KIN Quest search screen when a traveling user can't find a business
/// in the directory. Reuses the same field set and layout, but captures the
/// device's current GPS fix as the submission's starting location (the
/// owner-side dialog has no equivalent need, since an owner is filling this
/// out about their own already-located business) and calls
/// [KinServices.submitTravelerBusinessDiscovery] instead, which has no
/// owned-business gate and runs duplicate-detection server-side.
class AddTravelerDiscoveryDialog extends StatefulWidget {
  const AddTravelerDiscoveryDialog({super.key, this.initialName});

  /// Pre-fills the name field from whatever the user just searched for, so
  /// they don't have to retype it.
  final String? initialName;

  @override
  State<AddTravelerDiscoveryDialog> createState() =>
      _AddTravelerDiscoveryDialogState();
}

class _AddTravelerDiscoveryDialogState
    extends State<AddTravelerDiscoveryDialog> {
  late final _nameController =
      TextEditingController(text: widget.initialName ?? '');
  final _addressController = TextEditingController();
  final _otherCategoryController = TextEditingController();
  final _categoryController =
      FormFieldController<String>(_kDiscoveryCategories.first);

  /// Coordinates of the *business*, set when the user picks a real place
  /// from the address autocomplete.
  ///
  /// This is the whole point of the picker. Before it existed, the dialog
  /// stamped the submitter's own GPS onto the submission - fine for someone
  /// standing outside the shop, badly wrong for the case this screen
  /// actually invites ("I have their business card"), which would have
  /// filed a New York bakery at the submitter's house in Texas.
  double? _placeLat;
  double? _placeLng;

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

    // A fresh fix, not the cached one from page-load - if the user IS at the
    // business, this is what proves it.
    final location = await getCurrentUserLocation(
      defaultLocation: const LatLng(0, 0),
      cached: false,
    );

    if (!mounted) return;

    final hasGps = !(location.latitude == 0 && location.longitude == 0);
    var hasPickedPlace = _placeLat != null && _placeLng != null;

    // Typing an address and moving on - rather than tapping the dropdown
    // suggestion - used to fall straight through to the GPS fallback below,
    // or to this hard failure if GPS was also off. Geocoding the typed text
    // directly recovers the same case the picker would have resolved,
    // without depending on that specific tap landing.
    if (!hasPickedPlace) {
      final geocoded = await GeocodingService.geocodeAddress(address);
      if (geocoded != null) {
        _placeLat = geocoded.latitude;
        _placeLng = geocoded.longitude;
        hasPickedPlace = true;
      }
    }

    // Location is no longer required, only *some* way to place the business.
    // Requiring GPS made it impossible to add a business you aren't standing
    // at - which is exactly what this dialog exists for when someone is
    // adding a place they visited on a trip.
    if (!hasPickedPlace && !hasGps) {
      setState(() {
        _submitting = false;
        _error = 'Pick the address from the suggestions so we know where '
            'this business is, or turn on location if you\'re there now.';
      });
      return;
    }

    // The business's own coordinates always win. The submitter's GPS is only
    // a fallback for the on-site case where they typed the address by hand.
    final submitLat = hasPickedPlace ? _placeLat! : location.latitude;
    final submitLng = hasPickedPlace ? _placeLng! : location.longitude;

    // "Did this person actually stand here?" - true only when we have both
    // fixes and they agree. A submission from a business card is still
    // welcome, it just isn't ground-truth, and KIN lists verified
    // Black-owned businesses, so the two can't be recorded as the same
    // thing.
    final onSite = hasGps &&
        (!hasPickedPlace ||
            _metersBetween(
                  location.latitude,
                  location.longitude,
                  _placeLat!,
                  _placeLng!,
                ) <=
                _kOnSiteRadiusMeters);

    final otherCategory = _otherCategoryController.text.trim();
    final effectiveCategory = otherCategory.isNotEmpty
        ? otherCategory
        : (_categoryController.value ?? _kDiscoveryCategories.first);
    if (otherCategory.isNotEmpty) {
      await KinServices.ensureBusinessCategoryExists(otherCategory);
    }

    final result = await KinServices.submitTravelerBusinessDiscovery(
      businessName: name,
      address: address,
      category: effectiveCategory,
      latitude: submitLat,
      longitude: submitLng,
      verifiedOnSite: onSite,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.isSuccess) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          "Thanks! We'll review it - it'll show up once it's approved.",
        ),
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
                Icon(Icons.add_location_alt_rounded,
                    color: theme.primaryText, size: 20.0),
                SizedBox(width: theme.designToken.spacing.xs),
                Text(
                  'Not in KIN Yet?',
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
              "Know a Black-owned business that isn't listed? Add it and "
              "we'll review it. Search the address to place it on the map - "
              "you don't have to be there.",
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
                // Address autocomplete, same picker the owner-side dialog
                // uses. Beyond saving typing, this is what supplies the
                // business's real coordinates - without it the submission
                // falls back to the submitter's GPS, which puts a business
                // they're telling us about from a business card wherever
                // they happen to be sitting.
                suffixIcon: FlutterFlowPlacePicker(
                  iOSGoogleMapsApiKey: _kGoogleMapsApiKey,
                  androidGoogleMapsApiKey: _kGoogleMapsApiKey,
                  webGoogleMapsApiKey: _kGoogleMapsApiKey,
                  defaultText: '',
                  // accentOnSurface for the same reason as the owner dialog:
                  // this icon sits on secondaryBackground and both primary
                  // and info vanish in one of the two themes. See the
                  // light-mode-text-token-bug-class memory.
                  icon: Icon(Icons.search_rounded,
                      color: theme.accentOnSurface, size: 20.0),
                  onSelect: (place) {
                    setState(() {
                      _addressController.text = place.address;
                      _placeLat = place.latLng.latitude;
                      _placeLng = place.latLng.longitude;
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
              // Typing by hand invalidates any previously picked place -
              // otherwise an edited address would keep the old pin.
              onChanged: (_) {
                if (_placeLat != null) {
                  setState(() {
                    _placeLat = null;
                    _placeLng = null;
                  });
                }
              },
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
              text: _submitting ? 'Submitting...' : 'Submit for Review',
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
