import '/backend/backend.dart';
import '/components/exchange_feed_item_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/nearby_feed.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'nearby_feed_model.dart';
export 'nearby_feed_model.dart';

/// The Feed tab: Exchange posts from businesses near the user.
///
/// The Exchange stores one wall per business (`exchange_posts.business_ref`),
/// with no global feed document. Rather than restructure that, this page reads
/// several walls at once: it finds the businesses closest to the user, then
/// issues a single `business_ref whereIn [...]` query across them.
///
/// That `whereIn` is capped at 30 values by Firestore, which is why
/// [selectNearby] truncates to the closest [kNearbyFeedMaxBusinesses]. In a
/// dense metro the feed is therefore the 30 nearest businesses, not every
/// business in the radius - see kNearbyFeedRadiusKm.
///
/// Tapping a post opens that post's own business wall
/// ([TheExchangeWidget]), which is still the place you post from.
class NearbyFeedWidget extends StatefulWidget {
  const NearbyFeedWidget({super.key});

  static String routeName = 'NearbyFeed';
  static String routePath = '/nearbyFeed';

  @override
  State<NearbyFeedWidget> createState() => _NearbyFeedWidgetState();
}

class _NearbyFeedWidgetState extends State<NearbyFeedWidget> {
  late NearbyFeedModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  /// Fallback when location permission is denied or unavailable: downtown San
  /// Antonio, the same default the map page centres on
  /// (google_map_page_widget.dart's initialLocation). Using the same origin
  /// keeps the Feed consistent with what the user just saw on the map.
  static const LatLng _defaultLocation = LatLng(29.4241, -98.4936);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NearbyFeedModel());
    getCurrentUserLocation(defaultLocation: _defaultLocation, cached: true)
        .then((loc) {
      if (!mounted) return;
      safeSetState(() {
        _model.userLocation = loc;
        _model.locationResolved = true;
      });
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        automaticallyImplyLeading: false,
        title: Text(
          'Nearby',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                // `primary` is the deep green brand colour - unreadable on
                // this page's dark primaryBackground app bar.
                color: FlutterFlowTheme.of(context).primaryText,
                letterSpacing: 0.0,
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: false,
        elevation: 0.0,
      ),
      body: SafeArea(
        top: true,
        child: !_model.locationResolved
            ? _centeredSpinner()
            : FutureBuilder<List<BusinessesRecord>>(
                // Same unfiltered read the map page does - Firestore can't
                // range-query a GeoPoint on both axes, and these documents
                // carry no geohash, so proximity is computed client-side.
                future: _model.businesses(),
                builder: (context, businessSnapshot) {
                  if (!businessSnapshot.hasData) return _centeredSpinner();

                  final nearby = selectNearby(
                    businessSnapshot.data!,
                    originLat: _model.userLocation!.latitude,
                    originLng: _model.userLocation!.longitude,
                    latOf: (b) => b.businessLocation?.latitude,
                    lngOf: (b) => b.businessLocation?.longitude,
                  );

                  if (nearby.isEmpty) {
                    return _emptyState(
                      'Nothing nearby yet',
                      'We couldn\'t find any KIN businesses within '
                          '${kNearbyFeedRadiusKm.round()} km of you. Try the map to '
                          'explore further out.',
                    );
                  }

                  final nearbyRefs = nearby.map((b) => b.reference).toList();
                  final businessesByPath = {
                    for (final b in nearby) b.reference.path: b,
                  };

                  return StreamBuilder<List<ExchangePostsRecord>>(
                    // Deliberately no `.orderBy('timestamp')` here: combining
                    // it with `whereIn` on a different field would require a
                    // composite index on exchange_posts that doesn't exist
                    // yet, so the feed would throw until someone ran
                    // `firebase deploy --only firestore:indexes`. Sorting
                    // below instead keeps this working with no deploy. Revisit
                    // if the feed ever needs server-side pagination - the
                    // result set is bounded by 30 businesses today.
                    stream: queryExchangePostsRecord(
                      queryBuilder: (q) =>
                          q.where('business_ref', whereIn: nearbyRefs),
                    ),
                    builder: (context, postSnapshot) {
                      if (!postSnapshot.hasData) return _centeredSpinner();
                      final posts = postSnapshot.data!.toList()
                        ..sort((a, b) {
                          final at = a.timestamp;
                          final bt = b.timestamp;
                          // Posts with no timestamp sink to the bottom rather
                          // than jumping to the top of the feed.
                          if (at == null && bt == null) return 0;
                          if (at == null) return 1;
                          if (bt == null) return -1;
                          return bt.compareTo(at);
                        });

                      if (posts.isEmpty) {
                        return _emptyState(
                          'No posts yet',
                          '${nearby.length} ${nearby.length == 1 ? 'business is' : 'businesses are'} '
                              'near you, but none have posted yet. Check back soon.',
                        );
                      }

                      return ListView.separated(
                        padding: EdgeInsets.all(16.0),
                        itemCount: posts.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12.0),
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          final business =
                              businessesByPath[post.businessRef?.path];
                          return _feedItem(post, business);
                        },
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  /// Resolves the post's author before handing off to [ExchangeFeedItemWidget].
  ///
  /// The per-business Exchange page shows a full-size spinner per post while
  /// the author loads, which makes a multi-post feed flash badly. Here the
  /// post renders immediately and the author name/photo fill in when they
  /// arrive.
  Widget _feedItem(ExchangePostsRecord post, BusinessesRecord? business) {
    final businessRef = post.businessRef ?? business?.reference;
    if (businessRef == null) return SizedBox.shrink();

    if (post.userRef == null) {
      return ExchangeFeedItemWidget(
        key: Key('nearbyFeed_${post.reference.id}'),
        postRecord: post,
        businessRef: businessRef,
      );
    }

    return StreamBuilder<UsersRecord>(
      stream: UsersRecord.getDocument(post.userRef!),
      builder: (context, snapshot) {
        final author = snapshot.data;
        return ExchangeFeedItemWidget(
          key: Key('nearbyFeed_${post.reference.id}'),
          postRecord: post,
          businessRef: businessRef,
          authorDisplayName: author?.displayName,
          authorPhotoUrl: author?.photoUrl,
        );
      },
    );
  }

  Widget _centeredSpinner() => Center(
        child: SizedBox(
          width: 40.0,
          height: 40.0,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
                FlutterFlowTheme.of(context).primary),
          ),
        ),
      );

  Widget _emptyState(String title, String body) => Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(context).titleMedium.override(
                      font: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold),
                      color: FlutterFlowTheme.of(context).primaryText,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 8.0),
              Text(
                body,
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.plusJakartaSans(),
                      color: FlutterFlowTheme.of(context).secondaryText,
                      letterSpacing: 0.0,
                      lineHeight: 1.4,
                    ),
              ),
            ],
          ),
        ),
      );
}
