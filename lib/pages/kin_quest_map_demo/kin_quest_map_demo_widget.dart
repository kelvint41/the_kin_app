import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// hide LatLng: backend.dart transitively exports FlutterFlow's own LatLng
// (lib/flutter_flow/lat_lng.dart), which collides with google_maps_flutter's
// LatLng above. Only .latitude/.longitude off BusinessesRecord.businessLocation
// are ever used from it, so hiding the type entirely is safe - every LatLng(...)
// constructor call in this file should resolve to the maps package's version.
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart' hide LatLng;
import '/services/kin_services.dart';
import '/services/seasonal_theme.dart';

/// Standalone "KIN Quest" map interface - dark/light theme toggle,
/// verified/unverified quest pins, a proximity-gated real check-in flow,
/// and the etiquette/points rules explainer.
///
/// Pins load from the real `businesses` collection (filtered to the
/// `directory_import_batch` tag `seed_directory_test_batch.js` wrote on
/// the Georgia/Illinois test batch - see firebase/scripts/
/// seed_directory_test_batch.js). "Verify" now calls the real
/// `recordVerifiedVisit` callable (same one Business Profile V2's "I'm
/// Here" button and the real KIN Quest list page use), so points are
/// real KIN scavenger_points, not local widget state - the only thing
/// still simulated is the user's own position: _userLocation below is
/// fixed rather than read from a location plugin, since this page has no
/// live GPS wiring yet. Swapping that for geolocator is the one piece
/// left before this can leave beta.
///
/// A pin's amber '?' / emerald '✓' reflects businesses.is_verified - the
/// same ownership/trust flag the claim-approval flow controls, not
/// "have I personally been here before." A KIN Quest check-in deliberately
/// never sets is_verified itself (that would let anyone "verify" a
/// business's ownership just by standing near it) - the existing
/// one-check-in-per-business-per-user rule in recordVerifiedVisit is what
/// stops repeat farming, tracked locally here via _QuestPin.alreadyMine
/// so the sheet can say so without needing the pin to change color.
class KinQuestMapDemoWidget extends StatefulWidget {
  const KinQuestMapDemoWidget({super.key});

  static String routeName = 'KinQuestMapDemo';
  static String routePath = '/kinQuestMapDemo';

  @override
  State<KinQuestMapDemoWidget> createState() => _KinQuestMapDemoWidgetState();
}

/// One quest location, backed by a real business document.
class _QuestPin {
  _QuestPin({
    required this.id,
    required this.businessRef,
    required this.name,
    required this.address,
    required this.position,
    required this.isVerified,
  });

  final String id;
  final DocumentReference businessRef;
  final String name;
  final String address;
  final LatLng position;

  /// businesses.is_verified - the ownership/trust flag, not a personal
  /// visit record. See this file's top-of-file doc comment for why a
  /// check-in never changes this.
  final bool isVerified;

  /// Set locally once this session's check-in call succeeds - lets the
  /// sheet say "already checked in" without needing is_verified to change
  /// or the pin to disappear.
  bool alreadyMine = false;
}

class _KinQuestMapDemoWidgetState extends State<KinQuestMapDemoWidget>
    with SingleTickerProviderStateMixin {
  bool _isDarkMode = true;
  int _score = 0;
  GoogleMapController? _mapController;
  late final AnimationController _pulseController;

  /// "You are here" - a short walk (~50m) from Busy Bee Cafe, one of the
  /// real seeded Atlanta businesses, rather than a city center. Picked
  /// deliberately close to a real pin so the Verify button has at least
  /// one guaranteed-enabled case to test on-device, alongside plenty of
  /// far-away seeded pins (Savannah/Macon/Chicago) that correctly show
  /// the button disabled - real geographic spread doing the job dummy
  /// data would have needed to fake.
  static const _userLocation = LatLng(33.7541, -84.4136);
  static const _verifyRadiusMeters = 100.0;

  List<_QuestPin> _pins = [];
  bool _loadingPins = true;
  String? _loadError;

  Future<void> _loadPins() async {
    try {
      final snapshot = await BusinessesRecord.collection
          .where('directory_import_batch', isEqualTo: 'ga_il_test_2026_08')
          .get();
      final pins = snapshot.docs
          .map(BusinessesRecord.fromSnapshot)
          .where((b) => b.businessLocation != null)
          .map((b) => _QuestPin(
                id: b.reference.id,
                businessRef: b.reference,
                name: b.businessName,
                address: '${b.address}, ${b.city}, ${b.state}',
                position: LatLng(
                  b.businessLocation!.latitude,
                  b.businessLocation!.longitude,
                ),
                isVerified: b.isVerified,
              ))
          .toList();
      if (!mounted) return;
      setState(() {
        _pins = pins;
        _loadingPins = false;
      });
      // Pins may finish loading well after onMapCreated already fired (and
      // therefore after the last camera event) - without this, newly
      // loaded pins would have no screen position until the user next
      // pans/zooms.
      _updatePinPositions();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load quest locations.';
        _loadingPins = false;
      });
    }
  }

  /// Screen-space position for every pin, recomputed on camera
  /// move/idle via GoogleMapController.getScreenCoordinate - this is what
  /// lets the badges be real Flutter widgets (real BoxShadow glow/soft
  /// drop-shadow, instant repaint on state change) instead of baked
  /// BitmapDescriptor marker icons, which can't do either cheaply.
  final Map<String, Offset> _pinScreenPositions = {};
  bool _updatingPositions = false;

  // 'kin_quest_map_rules_seen_v1' rather than a bare name - versioned so a
  // future rewrite of the rules copy can re-show it once, the same
  // reasoning legal_config/exchange_terms bumps a version to re-prompt
  // rather than trusting a stale "seen it" flag forever.
  static const _rulesSeenKey = 'kin_quest_map_rules_seen_v1';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadPins();
    _loadRealScore();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowRules());
  }

  Future<void> _loadRealScore() async {
    final userRef = currentUserReference;
    if (userRef == null) return;
    try {
      final user = await UsersRecord.getDocumentOnce(userRef);
      if (!mounted) return;
      setState(() => _score = user.scavengerPoints);
    } catch (_) {
      // Starts at 0 either way - not worth surfacing an error banner for
      // a number that'll just update again after the first check-in.
    }
  }

  Future<void> _maybeShowRules() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_rulesSeenKey) == true) return;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _RulesDialog(isDarkMode: _isDarkMode),
    );
    await prefs.setBool(_rulesSeenKey, true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _updatePinPositions() async {
    final controller = _mapController;
    if (controller == null || _updatingPositions) return;
    _updatingPositions = true;
    try {
      final entries = await Future.wait(_pins.map((pin) async {
        final sc = await controller.getScreenCoordinate(pin.position);
        return MapEntry(pin.id, Offset(sc.x.toDouble(), sc.y.toDouble()));
      }));
      if (!mounted) return;
      setState(() {
        _pinScreenPositions
          ..clear()
          ..addEntries(entries);
      });
    } catch (_) {
      // A screen coordinate lookup can fail transiently mid-gesture (map
      // not yet laid out, or disposed while awaiting) - next camera event
      // retries, so this is safe to just drop.
    } finally {
      _updatingPositions = false;
    }
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const earthRadiusMeters = 6371000.0;
    double toRad(double deg) => deg * (math.pi / 180.0);
    final dLat = toRad(b.latitude - a.latitude);
    final dLon = toRad(b.longitude - a.longitude);
    final lat1 = toRad(a.latitude);
    final lat2 = toRad(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadiusMeters * c;
  }

  String _formatDistance(double meters) =>
      meters < 1000 ? '${meters.round()}m away' : '${(meters / 1000).toStringAsFixed(1)}km away';

  /// Tapping a pin asks first, rather than dropping straight into the
  /// proximity sheet - "do you want to start the quest for this
  /// business?" per the brief, so starting one is a deliberate choice.
  Future<void> _confirmStart(_QuestPin pin) async {
    final theme = Theme.of(context);
    final start = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface,
        title: Text('Start this quest?',
            style: TextStyle(color: _onSurface, fontWeight: FontWeight.w800)),
        content: Text(
          'Head to ${pin.name} and check in when you\'re there to earn points.',
          style: TextStyle(color: _onSurface.withValues(alpha: 0.85)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.primary),
            child: const Text('Start Quest'),
          ),
        ],
      ),
    );
    if (start == true && mounted) _openPinSheet(pin);
  }

  void _openPinSheet(_QuestPin pin) {
    final distance = _distanceMeters(_userLocation, pin.position);
    final canVerify = !pin.isVerified && !pin.alreadyMine && distance <= _verifyRadiusMeters;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _QuestBottomSheet(
        pin: pin,
        distanceLabel: _formatDistance(distance),
        canVerify: canVerify,
        isDarkMode: _isDarkMode,
        seasonalEmoji: _season.rareMarkerEmoji,
        onVerify: () async {
          Navigator.pop(sheetContext);
          await _performCheckIn(pin);
        },
      ),
    );
  }

  /// The real check-in: calls the same `recordVerifiedVisit` callable
  /// Business Profile V2's "I'm Here" button uses, fed this widget's fixed
  /// _userLocation instead of a live GPS fix (see the class doc comment).
  /// Points, the mystery-tier random range, the one-per-business rule -
  /// all of it runs server-side exactly as it does for a real check-in,
  /// because this *is* a real check-in.
  Future<void> _performCheckIn(_QuestPin pin) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking in...'), duration: Duration(seconds: 1)),
    );
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable(
        'recordVerifiedVisit',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
      )
          .call<Map<String, dynamic>>({
        'businessRefPath': pin.businessRef.path,
        'latitude': _userLocation.latitude,
        'longitude': _userLocation.longitude,
      });
      final data = result.data;
      final pointsAwarded = (data['pointsAwarded'] as num?)?.toInt() ?? 0;
      final totalPoints = (data['totalPoints'] as num?)?.toInt();
      if (!mounted) return;
      setState(() {
        pin.alreadyMine = true;
        if (totalPoints != null) _score = totalPoints;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pointsAwarded > 0
                ? 'Checked in at ${pin.name}! +$pointsAwarded points.'
                : 'Checked in at ${pin.name}.',
          ),
        ),
      );
      // The survey is about businesses the community hasn't confirmed yet
      // - a verified pin has nothing left to ask.
      if (!pin.isVerified && mounted) {
        await _askOwnershipSurvey(pin);
      }
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Couldn't check you in.")),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't check you in. Please try again.")),
      );
    }
  }

  /// Crowd-sourced signal only - see reportBusinessOwnership's own doc
  /// comment. Never blocks or alters the check-in that already happened;
  /// this is a follow-up question, not a gate.
  Future<void> _askOwnershipSurvey(_QuestPin pin) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface,
        title: Text('Quick question',
            style: TextStyle(color: _onSurface, fontWeight: FontWeight.w800)),
        content: Text(
          'Is ${pin.name} a Black-owned business?',
          style: TextStyle(color: _onSurface.withValues(alpha: 0.85)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("No / not sure"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (answer == null) return; // dismissed without answering - not logged
    final result = await KinServices.reportBusinessOwnership(
      businessRef: pin.businessRef,
      isBlackOwned: answer,
    );
    if (!mounted || !result.isSuccess) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thanks - that helps us keep the map accurate.')),
    );
  }

  // ---- theme tokens ---------------------------------------------------

  Color get _bg => _isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFFFFF);
  Color get _surface => _isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
  Color get _onSurface => _isDarkMode ? const Color(0xFFF2F2F2) : const Color(0xFF1A1A1A);
  // Deep blue accent for dark mode's "stealth" feel, warm amber-brown for
  // light mode's accent per the brief - two different accent hues on
  // purpose, not the same color reused across both themes. Deliberately
  // not seasonal like kin_quest_widget.dart's _accent - that would fight
  // the dark/light system this whole widget exists to demo. Only the
  // mystery pin's glyph below borrows from the season, same scope the
  // real KIN Quest page already gives it (rareMarkerEmoji only, nothing
  // wider).
  Color get _accent => _isDarkMode ? const Color(0xFF3B82F6) : const Color(0xFFB5651D);

  /// Same source the real KIN Quest page reads
  /// (services/seasonal_theme.dart) - only rareMarkerEmoji is used here,
  /// and only on the mystery '?' pins, matching that page's own scope
  /// exactly (see kin_quest_widget.dart's own use of this getter).
  SeasonalTheme get _season => currentSeasonalTheme();

  String get _darkMapStyle => _mapStyleJson(
        landscape: '#121212',
        water: '#0B1A2A',
        roadFill: '#1E1E1E',
        roadStroke: '#2A2A2E',
        poiFill: '#181818',
        labelFill: '#B8B8C0',
        labelStroke: '#0A0A0A',
        adminBorder: '#3A3A40',
      );

  String get _lightMapStyle => _mapStyleJson(
        landscape: '#F5F5F5',
        water: '#CFE3F5',
        roadFill: '#FFFFFF',
        roadStroke: '#E0E0E0',
        poiFill: '#EDEDED',
        labelFill: '#5B5B63',
        labelStroke: '#FFFFFF',
        adminBorder: '#D8D8DC',
      );

  String _mapStyleJson({
    required String landscape,
    required String water,
    required String roadFill,
    required String roadStroke,
    required String poiFill,
    required String labelFill,
    required String labelStroke,
    required String adminBorder,
  }) =>
      '''
[
  {"elementType": "geometry", "stylers": [{"color": "$landscape"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "$labelFill"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "$labelStroke"}]},
  {"featureType": "administrative", "elementType": "geometry.stroke", "stylers": [{"color": "$adminBorder"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "$poiFill"}]},
  {"featureType": "poi", "elementType": "labels", "stylers": [{"visibility": "off"}]},
  {"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "$roadFill"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "$roadStroke"}]},
  {"featureType": "road", "elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "$water"}]}
]
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        iconTheme: IconThemeData(color: _onSurface),
        title: Row(
          children: [
            Text('🧭', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'KIN Quest',
              style: TextStyle(
                color: _onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          // Score - the AppBar target for "State Change ... updates the
          // user's score in the AppBar" in the brief.
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: _isDarkMode ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _accent.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars_rounded, size: 16, color: _accent),
                const SizedBox(width: 4),
                Text(
                  '$_score pts',
                  style: TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(_isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: _userLocation, zoom: 16),
            style: _isDarkMode ? _darkMapStyle : _lightMapStyle,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              _updatePinPositions();
            },
            onCameraMove: (_) => _updatePinPositions(),
            onCameraIdle: _updatePinPositions,
          ),
          // Quest pins, positioned via the screen coordinates computed
          // above. IgnorePointer isn't used here - each pin is its own
          // tap target, on top of the map's own pan/zoom gestures.
          for (final pin in _pins)
            if (_pinScreenPositions[pin.id] != null)
              Positioned(
                left: _pinScreenPositions[pin.id]!.dx - 22,
                top: _pinScreenPositions[pin.id]!.dy - 44,
                child: _QuestPinBadge(
                  isVerified: pin.isVerified,
                  isDarkMode: _isDarkMode,
                  seasonalEmoji: _season.rareMarkerEmoji,
                  onTap: () => _confirmStart(pin),
                ),
              ),
          // User location - fixed at the screen's focal point rather than
          // converted from a real GPS lat/lng, matching the brief
          // ("positioned as the focal point of the screen") and this
          // widget's dummy-data scope.
          IgnorePointer(
            child: Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) => _UserPulseMarker(progress: _pulseController.value),
              ),
            ),
          ),
          if (_loadingPins || _loadError != null)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: IgnorePointer(
                ignoring: _loadError == null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: (_loadError != null ? Colors.redAccent : _accent)
                            .withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_loadingPins)
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
                        )
                      else
                        const Icon(Icons.error_outline, size: 16, color: Colors.redAccent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _loadError ?? 'Loading quest locations from Firestore...',
                          style: TextStyle(color: _onSurface, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A quest pin's on-map badge: amber '?' for unverified, emerald '✓' for
/// verified, with a glowing halo in dark mode and a soft drop-shadow in
/// light mode - real BoxShadow, not a baked marker icon, so this repaints
/// instantly the moment a pin flips from unverified to verified.
class _QuestPinBadge extends StatelessWidget {
  const _QuestPinBadge({
    required this.isVerified,
    required this.isDarkMode,
    required this.onTap,
    this.seasonalEmoji,
  });

  final bool isVerified;
  final bool isDarkMode;
  final VoidCallback onTap;

  /// SeasonalTheme.rareMarkerEmoji - only replaces the '?' glyph on an
  /// unverified pin, only when the current season sets one (Halloween
  /// today). A verified pin's checkmark never changes; matches the real
  /// KIN Quest page's own scope for this exactly.
  final String? seasonalEmoji;

  static const _amber = Color(0xFFFFC107);
  static const _emerald = Color(0xFF2ECC71);

  @override
  Widget build(BuildContext context) {
    final color = isVerified ? _emerald : _amber;
    final glow = isDarkMode
        ? [
            BoxShadow(
              color: color.withValues(alpha: 0.65),
              blurRadius: 18,
              spreadRadius: 3,
            ),
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 32,
              spreadRadius: 6,
            ),
          ]
        : [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ];

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDarkMode ? Colors.black.withValues(alpha: 0.4) : Colors.white,
                width: 2,
              ),
              boxShadow: glow,
            ),
            child: Text(
              isVerified
                  ? '✓'
                  : (seasonalEmoji ?? '?'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          // Small pointer so the badge reads as a map pin, not a floating
          // chip.
          CustomPaint(size: const Size(10, 6), painter: _PinTailPainter(color)),
        ],
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  _PinTailPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter oldDelegate) => oldDelegate.color != color;
}

/// The user's own location - a solid center dot plus two expanding,
/// fading radar rings driven by a single repeating AnimationController.
class _UserPulseMarker extends StatelessWidget {
  const _UserPulseMarker({required this.progress});

  final double progress;
  static const _blue = Color(0xFF2F80FF);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final offset in [0.0, 0.5])
            _ring((progress + offset) % 1.0),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _blue,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(color: _blue.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double t) {
    final size = 18.0 + t * 70.0;
    final alpha = (1 - t).clamp(0.0, 1.0) * 0.55;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _blue.withValues(alpha: alpha), width: 2),
        color: _blue.withValues(alpha: alpha * 0.2),
      ),
    );
  }
}

/// The proximity-verification bottom sheet - status badge, business
/// details, live distance, and the gated "Verify Location" action.
class _QuestBottomSheet extends StatelessWidget {
  const _QuestBottomSheet({
    required this.pin,
    required this.distanceLabel,
    required this.canVerify,
    required this.isDarkMode,
    required this.onVerify,
    this.seasonalEmoji,
  });

  final _QuestPin pin;
  final String distanceLabel;
  final bool canVerify;
  final bool isDarkMode;
  final VoidCallback onVerify;
  final String? seasonalEmoji;

  static const _amber = Color(0xFFFFC107);
  static const _emerald = Color(0xFF2ECC71);

  @override
  Widget build(BuildContext context) {
    final surface = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final onSurface = isDarkMode ? const Color(0xFFF2F2F2) : const Color(0xFF1A1A1A);
    final onSurfaceMuted = isDarkMode ? const Color(0xFFA0A0AB) : const Color(0xFF6B6B75);
    final statusColor = pin.isVerified ? _emerald : _amber;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDarkMode ? Colors.white12 : Colors.black12,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: onSurfaceMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Top status badge.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: isDarkMode ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: statusColor.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(pin.isVerified ? '✓' : (seasonalEmoji ?? '?'),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 6),
                  Text(
                    pin.isVerified ? 'Verified Black-Owned' : 'Unverified Quest Location',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              pin.name,
              style: TextStyle(color: onSurface, fontWeight: FontWeight.w800, fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(pin.address, style: TextStyle(color: onSurfaceMuted, fontSize: 13.5)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.near_me_rounded, size: 15, color: onSurfaceMuted),
                const SizedBox(width: 4),
                Text(
                  distanceLabel,
                  style: TextStyle(
                    color: onSurfaceMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (pin.isVerified || pin.alreadyMine)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _emerald.withValues(alpha: isDarkMode ? 0.16 : 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _emerald.withValues(alpha: 0.5)),
                ),
                child: Text(
                  pin.isVerified ? '✓ Already verified' : '✓ Already checked in',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _emerald, fontWeight: FontWeight.w700),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canVerify ? onVerify : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _amber,
                    disabledBackgroundColor:
                        isDarkMode ? Colors.white12 : const Color(0xFFE0E0E0),
                    foregroundColor: Colors.black,
                    disabledForegroundColor: onSurfaceMuted,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    elevation: 0,
                  ),
                  child: Text(
                    // No fixed point amount shown anymore - a mystery
                    // business pays a random 10-50, so promising a specific
                    // number here would just be wrong most of the time.
                    canVerify ? 'Verify Location' : "Get closer to verify",
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// First-time explainer, shown once per device (SharedPreferences flag in
/// the parent State) before anyone can start a quest: how points work and
/// the one etiquette ask, so nobody is guessing at either.
class _RulesDialog extends StatelessWidget {
  const _RulesDialog({required this.isDarkMode});

  final bool isDarkMode;

  static const _amber = Color(0xFFFFC107);
  static const _emerald = Color(0xFF2ECC71);
  static const _blue = Color(0xFF2F80FF);

  @override
  Widget build(BuildContext context) {
    final surface = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final onSurface = isDarkMode ? const Color(0xFFF2F2F2) : const Color(0xFF1A1A1A);
    final onSurfaceMuted = isDarkMode ? const Color(0xFFA0A0AB) : const Color(0xFF6B6B75);

    Widget rule(String emoji, Color color, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 15)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: onSurface, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(body,
                        style: TextStyle(color: onSurfaceMuted, fontSize: 12.5, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        );

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How KIN Quest works',
                style: TextStyle(color: onSurface, fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 16),
            rule('✓', _emerald, 'Verified businesses',
                "Check in at an already-verified business and you'll earn its standard points."),
            rule('?', _amber, 'Mystery businesses',
                "The amber '?' pins haven't been verified yet - check in for a random point bonus, and you may be asked a quick yes/no about whether it's Black-owned. That's just a signal for our team, it doesn't change your points."),
            rule('🆕', _blue, 'Found one that isn\'t listed at all?',
                "Submit it from the app. Once our team confirms it's real, you'll earn a guaranteed 50 points plus a bonus - the biggest reward on the map, for the rarest kind of find."),
            rule('🤝', _blue, 'One ask',
                'Please actually visit and support the businesses you find - even just stopping in counts. This works because real people show up for real businesses.'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Let's go"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
