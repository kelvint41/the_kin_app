import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/business_profile_v2/business_profile_v2_widget.dart';
import '/services/engagement_stats.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom sheet shown when tapping an Exchange post author's name/avatar.
///
/// ExchangeFeedItemWidget only carries the denormalized authorName/
/// authorPhoto a post was written with (see ExchangePostsRecord's doc
/// comment on why), so handle/bio/post_count need their own read of
/// exchange_profiles/{uid} here. That doc can be missing entirely, or
/// exist with only agreed_to_conduct set and nothing else (see
/// ExchangeProfilesRecord.isComplete) - either way this still renders
/// using whatever the tapped post carried, rather than an empty sheet.
class ExchangeProfileSheet extends StatelessWidget {
  const ExchangeProfileSheet({
    super.key,
    required this.userRef,
    this.fallbackName,
    this.fallbackPhotoUrl,
  });

  final DocumentReference userRef;
  final String? fallbackName;
  final String? fallbackPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('exchange_profiles')
          .doc(userRef.id)
          .snapshots(),
      builder: (context, snapshot) {
        final profile = snapshot.hasData && snapshot.data!.exists
            ? ExchangeProfilesRecord.fromSnapshot(snapshot.data!)
            : null;
        final name = (profile?.displayName ?? '').isNotEmpty
            ? profile!.displayName
            : (fallbackName?.isNotEmpty ?? false)
                ? fallbackName!
                : 'KIN Member';
        final photoUrl = (profile?.photoUrl ?? '').isNotEmpty
            ? profile!.photoUrl
            : (fallbackPhotoUrl ?? '');
        final postCount = profile?.postCount ?? 0;
        final businessRef = profile?.businessRef;

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
                    margin:
                        EdgeInsets.only(bottom: theme.designToken.spacing.md),
                    decoration: BoxDecoration(
                      color: theme.alternate,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(theme.designToken.radius.full),
                      child: Container(
                        width: 56.0,
                        height: 56.0,
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.divider, width: 1.0),
                        ),
                        child: photoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                fadeInDuration: Duration(milliseconds: 0),
                                fadeOutDuration: Duration(milliseconds: 0),
                                imageUrl: photoUrl,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: theme.secondaryBackground,
                                alignment: Alignment.center,
                                child: Text(
                                  businessInitials(name),
                                  style: theme.titleMedium.override(
                                    font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold),
                                    color: theme.primaryText,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.0,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: theme.designToken.spacing.md),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: theme.titleMedium.override(
                              font: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold),
                              color: theme.primaryText,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.0,
                            ),
                          ),
                          if ((profile?.handle ?? '').isNotEmpty)
                            Text(
                              '@${profile!.handle}',
                              style: theme.bodySmall.override(
                                font: GoogleFonts.plusJakartaSans(),
                                color: theme.secondaryText,
                                letterSpacing: 0.0,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if ((profile?.bio ?? '').isNotEmpty) ...[
                  SizedBox(height: theme.designToken.spacing.md),
                  Text(
                    profile!.bio,
                    style: theme.bodyMedium.override(
                      font: GoogleFonts.plusJakartaSans(),
                      color: theme.primaryText,
                      letterSpacing: 0.0,
                    ),
                  ),
                ],
                SizedBox(height: theme.designToken.spacing.md),
                Row(
                  children: [
                    Icon(Icons.forum_outlined,
                        size: 16.0, color: theme.secondaryText),
                    SizedBox(width: theme.designToken.spacing.xs),
                    Text(
                      '$postCount post${postCount == 1 ? '' : 's'} in The Exchange',
                      style: theme.bodySmall.override(
                        font: GoogleFonts.plusJakartaSans(),
                        color: theme.secondaryText,
                        letterSpacing: 0.0,
                      ),
                    ),
                  ],
                ),
                if (businessRef != null) ...[
                  SizedBox(height: theme.designToken.spacing.lg),
                  FFButtonWidget(
                    onPressed: () {
                      Navigator.pop(context);
                      context.pushNamed(
                        BusinessProfileV2Widget.routeName,
                        queryParameters: {
                          'businessDocument': serializeParam(
                            businessRef,
                            ParamType.DocumentReference,
                          ),
                        }.withoutNulls,
                      );
                    },
                    text: 'View Business',
                    icon: const Icon(Icons.storefront_outlined, size: 18.0),
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 44.0,
                      color: theme.primary,
                      textStyle:
                          theme.titleSmall.override(color: theme.onPrimary),
                      elevation: 0.0,
                      borderRadius:
                          BorderRadius.circular(theme.designToken.radius.sm),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
