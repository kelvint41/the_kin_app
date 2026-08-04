import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/business_image_widget.dart';
import '/components/exchange_feed_item_widget.dart' show kQuickReactions;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/kin_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'marketplace_item_card_model.dart';
export 'marketplace_item_card_model.dart';

/// A Marketplace item card - used by both the "Popular near you" rail and the
/// full grid. Resolves the parent business via a live stream (for its name
/// and to route to BusinessProfileV2Widget on tap) rather than
/// denormalizing the business name/photo onto the item doc, so a business
/// rename never leaves an item card showing stale info.
///
/// Reactions reuse kQuickReactions (the same five Exchange reactions) via
/// a compact pill that opens a picker sheet - tapping a reaction there is
/// its own tap target and does not trigger the card's navigation.
class MarketplaceItemCardWidget extends StatefulWidget {
  const MarketplaceItemCardWidget({
    super.key,
    required this.item,
    // Was 150.0 - the "Popular near you" row (the only caller that doesn't
    // override this) truncated '$businessName · $priceDisplay' down to just
    // "$..." with no digits, while "Browse all items" passes width:
    // double.infinity and renders the identical string in full.
    this.width = 200.0,
  });

  final BusinessItemsRecord item;
  final double width;

  @override
  State<MarketplaceItemCardWidget> createState() =>
      _MarketplaceItemCardWidgetState();
}

class _MarketplaceItemCardWidgetState extends State<MarketplaceItemCardWidget> {
  late MarketplaceItemCardModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MarketplaceItemCardModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  /// The public grid had no way to remove your own listing at all - item
  /// management otherwise only exists in My Items, an extra hop away.
  /// Mirrors the confirm-then-delete shape used there.
  Future<void> _confirmDelete(BuildContext context) async {
    final theme = FlutterFlowTheme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${widget.item.title}?'),
        content: Text(
            'This removes it from the Marketplace for everyone. This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Remove', style: TextStyle(color: theme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.item.reference.delete();
    }
  }

  void _openReactionPicker(BuildContext context, DocumentReference businessRef) {
    final theme = FlutterFlowTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(theme.designToken.radius.lg),
            topRight: Radius.circular(theme.designToken.radius.lg),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: theme.designToken.spacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.0,
                  height: 4.0,
                  margin: EdgeInsets.only(bottom: theme.designToken.spacing.md),
                  decoration: BoxDecoration(
                    color: theme.alternate,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                Text(widget.item.title, style: theme.titleSmall),
                SizedBox(height: theme.designToken.spacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: kQuickReactions.map((reaction) {
                    return InkWell(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        KinServices.recordItemReaction(
                          itemRef: widget.item.reference,
                          businessRef: businessRef,
                          eventType: reaction.eventType,
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            reaction.icon,
                            size: 22.0,
                            color: reaction.activeColor(theme),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 2.0, 0.0, 0.0),
                            child: Text(
                              reaction.label,
                              style: theme.labelSmall.override(
                                font: GoogleFonts.plusJakartaSans(),
                                fontSize: 10.0,
                                color: theme.secondaryText,
                                letterSpacing: 0.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final item = widget.item;
    return StreamBuilder<BusinessesRecord>(
      stream: BusinessesRecord.getDocument(item.businessRef!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(width: widget.width, height: 150.0);
        }
        final business = snapshot.data!;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.pushNamed(
            BusinessProfileV2Widget.routeName,
            queryParameters: {
              'businessDocument':
                  serializeParam(item.businessRef, ParamType.DocumentReference),
            }.withoutNulls,
          ),
          child: Container(
            width: widget.width,
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: theme.alternate, width: 1.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    BusinessImage(
                      imageUrl: item.photoUrl,
                      width: widget.width,
                      height: 84.0,
                      fit: BoxFit.cover,
                    ),
                    // Only the owner sees this - management otherwise lives
                    // exclusively in My Items, an extra hop from here.
                    if (business.ownerRef == currentUserReference)
                      Positioned(
                        top: 4.0,
                        right: 4.0,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999.0),
                          onTap: () => _confirmDelete(context),
                          child: Container(
                            width: 28.0,
                            height: 28.0,
                            decoration: BoxDecoration(
                              color: Color(0xE6FFFFFF),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 16.0,
                              color: theme.error,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodySmall.override(
                          font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold),
                          fontWeight: FontWeight.bold,
                          color: theme.primaryText,
                          letterSpacing: 0.0,
                        ),
                      ),
                      Text(
                        '${business.businessName} · ${item.priceDisplay}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.labelSmall.override(
                          font: GoogleFonts.plusJakartaSans(),
                          color: theme.secondaryText,
                          letterSpacing: 0.0,
                        ),
                      ),
                      SizedBox(height: 6.0),
                      InkWell(
                        onTap: () =>
                            _openReactionPicker(context, item.businessRef!),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: theme.primaryBackground,
                            borderRadius: BorderRadius.circular(999.0),
                            border: Border.all(
                                color: theme.alternate, width: 1.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.diversity_3_rounded,
                                size: 13.0,
                                color: theme.accentOnSurface,
                              ),
                              SizedBox(width: 4.0),
                              Text(
                                '${item.interestCount}',
                                style: theme.labelSmall.override(
                                  font: GoogleFonts.plusJakartaSans(),
                                  color: theme.secondaryText,
                                  letterSpacing: 0.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
