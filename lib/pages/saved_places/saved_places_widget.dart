import '/backend/backend.dart';
import '/components/business_image_widget.dart';
import '/components/favorite_heart_button.dart';
import '/components/kin_back_button.dart';
import '/components/main_menu_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/business_profile_v2/business_profile_v2_widget.dart';
import '/services/local/favorites_local_store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// V1 Favorites - "Saved Places" list.
///
/// DRAFT: reads business ids from [FavoritesLocalStore] (device-local, see
/// its doc comment) and resolves each to a live [BusinessesRecord] via a
/// single `whereIn` query - same pattern nearby_feed_widget.dart uses for
/// its own batched business lookup, including its 30-id Firestore cap.
class SavedPlacesWidget extends StatefulWidget {
  const SavedPlacesWidget({super.key});

  static String routeName = 'SavedPlaces';
  static String routePath = '/savedPlaces';

  @override
  State<SavedPlacesWidget> createState() => _SavedPlacesWidgetState();
}

class _SavedPlacesWidgetState extends State<SavedPlacesWidget> {
  final _store = FavoritesLocalStore.instance;

  @override
  void initState() {
    super.initState();
    _store.ensureLoaded();
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 0.0, 0.0),
          child: KinBackButton(floating: true),
        ),
        title: Text(
          'Saved Places',
          style: theme.headlineSmall.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            color: theme.primaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0.0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: MainMenuButton(),
          ),
        ],
      ),
      body: SafeArea(
        top: true,
        child: !_store.isLoaded
            ? _loading(theme)
            : _store.savedIds.isEmpty
                ? _emptyState(theme)
                : _list(theme),
      ),
    );
  }

  Widget _loading(FlutterFlowTheme theme) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
        ),
      );

  Widget _emptyState(FlutterFlowTheme theme) => Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border_rounded,
                color: theme.secondaryText,
                size: 48.0,
              ),
              SizedBox(height: 16.0),
              Text(
                'No saved places yet',
                style: theme.titleMedium.override(
                  color: theme.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'Tap the heart on any business profile to bookmark it here.',
                textAlign: TextAlign.center,
                style: theme.bodyMedium.override(
                  color: theme.secondaryText,
                  lineHeight: 1.4,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _list(FlutterFlowTheme theme) {
    // Firestore's whereIn caps at 30 values. Favorites is a personal list a
    // shopper builds one tap at a time, not a bulk import, so this is a
    // generous ceiling in practice - same tradeoff nearby_feed_widget.dart
    // makes for its own batched lookup.
    final ids = _store.savedIds.take(30).toList();
    return StreamBuilder<QuerySnapshot>(
      stream: BusinessesRecord.collection
          .where(FieldPath.documentId, whereIn: ids)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _loading(theme);
        }
        final businesses = snapshot.data!.docs
            .map((doc) => BusinessesRecord.getDocumentFromData(
                doc.data() as Map<String, dynamic>, doc.reference))
            .toList()
          ..sort((a, b) => a.businessName.compareTo(b.businessName));

        return ListView.separated(
          padding: EdgeInsets.all(16.0),
          itemCount: businesses.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.0),
          itemBuilder: (context, index) => _savedRow(theme, businesses[index]),
        );
      },
    );
  }

  Widget _savedRow(FlutterFlowTheme theme, BusinessesRecord business) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.0),
      onTap: () => context.pushNamed(
        BusinessProfileV2Widget.routeName,
        queryParameters: {
          'businessDocument':
              serializeParam(business.reference, ParamType.DocumentReference),
        }.withoutNulls,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: theme.alternate, width: 1.0),
        ),
        padding: EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: BusinessImage(
                imageUrl: business.heroImage,
                width: 56.0,
                height: 56.0,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.businessName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleSmall.override(
                      color: theme.primaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.0),
                  Text(
                    [business.category, business.city]
                        .where((p) => p.trim().isNotEmpty)
                        .join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall.override(
                      font: GoogleFonts.plusJakartaSans(),
                      color: theme.secondaryText,
                    ),
                  ),
                  if (business.hasKindexScore())
                    Padding(
                      padding: EdgeInsets.only(top: 6.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              color: theme.secondary, size: 14.0),
                          SizedBox(width: 4.0),
                          Text(
                            'KINDEX ${business.kindexScore.round()}',
                            style: theme.labelSmall.override(
                              font: GoogleFonts.plusJakartaSans(),
                              color: theme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            FavoriteHeartButton(
              businessId: business.reference.id,
              onImageOverlay: false,
              size: 40.0,
              iconSize: 22.0,
            ),
          ],
        ),
      ),
    );
  }
}
