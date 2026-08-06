import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/services/kin_services.dart';
import '/services/engagement_stats.dart';
import '/components/create_promotion_sheet.dart';
import '/components/exchange_feed_item_widget.dart';
import '/components/kindex_spotlight_widget.dart';
import '/components/main_menu_button.dart';
import '/components/promo_card_widget.dart';
import '/services/exchange_post_types.dart';
import '/backend/firebase_storage/storage.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import '/pages/kin_bottom_nav2/kin_bottom_nav2_widget.dart';
import '/index.dart';
import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'the_exchange_model.dart';
export 'the_exchange_model.dart';

class TheExchangeWidget extends StatefulWidget {
  const TheExchangeWidget({
    super.key,
    required this.businessRef,
  });

  final DocumentReference? businessRef;

  static String routeName = 'TheExchange';
  static String routePath = '/theExchange';

  @override
  State<TheExchangeWidget> createState() => _TheExchangeWidgetState();
}

class _TheExchangeWidgetState extends State<TheExchangeWidget> {
  late TheExchangeModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  /// Whether the signed-in user has accepted the Exchange code of conduct.
  /// Mirrors the exchange_profiles doc that firestore.rules checks on every
  /// post; this copy only drives whether we prompt before the first post.
  bool _acceptedConduct = false;

  /// Media picked in the persistent bottom composer, staged until Send is
  /// tapped. The "New Post" dialog keeps its own equivalent locally (via
  /// the dialog's StatefulBuilder) since it opens and closes independently
  /// of this widget's own rebuilds.
  SelectedFile? _pendingMedia;
  bool _pendingMediaIsVideo = false;
  bool _uploadingPendingMedia = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TheExchangeModel());
    _loadConductAcceptance();
  }

  Future<void> _loadConductAcceptance() async {
    final uid = currentUserUid;
    if (uid.isEmpty) return;
    final accepted = await KinServices.hasAcceptedExchangeConduct(uid);
    if (mounted && accepted) setState(() => _acceptedConduct = true);
  }

  /// Opens the photo-or-video picker and validates the result's format.
  /// Shared by both composers so the picker options, the storage folder,
  /// and the format-rejection message stay identical between them.
  ///
  /// Uploads land under the uploading user's own `users/{uid}/...` path -
  /// the only prefix `storage.rules` opens for writes - just organized
  /// under an `exchange_posts` subfolder rather than the shared default
  /// `uploads/` used elsewhere.
  Future<SelectedFile?> _pickPostMedia(BuildContext context) async {
    final media = await selectMediaWithSourceBottomSheet(
      context: context,
      allowPhoto: true,
      allowVideo: true,
      storageFolderPath: 'users/$currentUserUid/uploads/exchange_posts',
    );
    if (media == null || media.isEmpty) return null;
    final file = media.first;
    if (!validateFileFormat(file.storagePath, context)) return null;
    return file;
  }

  /// Uploads a picked file, returning its download URL or null on failure.
  /// Mirrors `ImageUploadButton`'s upload try/catch shape rather than
  /// inventing a new one.
  Future<String?> _uploadPostMedia(SelectedFile file) async {
    try {
      return await uploadData(file.storagePath, file.bytes);
    } catch (_) {
      return null;
    }
  }

  /// A standing notice for anyone who hasn't accepted the terms yet.
  ///
  /// Reading the feed is deliberately not blocked - the liability that
  /// matters here attaches to posting, and gating the feed would mean
  /// nobody could see what the Exchange is before agreeing to join it. What
  /// this fixes is the timing: the terms used to appear only at the moment
  /// someone tried to post, which is the worst time to meet them. Tapping
  /// through accepts on the spot, so the first post isn't interrupted.
  ///
  /// Renders nothing once accepted, so it never nags.
  Widget _buildTermsBanner() {
    if (_acceptedConduct || currentUserUid.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
          theme.designToken.spacing.lg, 0.0, theme.designToken.spacing.lg, 12.0),
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(theme.designToken.radius.md),
          border: Border.all(color: theme.accent1.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.gavel_rounded, size: 20.0,
                color: theme.accentOnSurface),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Browse freely. To post, agree to the Terms.',
                    style: theme.bodyMedium.override(
                      color: theme.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Keep it respectful: no harassment, no spam, no false '
                    'claims about a business.',
                    style: theme.bodySmall
                        .override(color: theme.secondaryText),
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    children: [
                      InkWell(
                        onTap: () async {
                          final ok = await _ensureConductAccepted();
                          if (ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Thanks - you can post in the Exchange now.'),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Review & agree',
                          style: theme.bodyMedium.override(
                            color: theme.accentOnSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20.0),
                      InkWell(
                        onTap: () => context
                            .pushNamed(TermsOfServicePageWidget.routeName),
                        child: Text(
                          'Terms of Service',
                          style: theme.bodyMedium.override(
                            color: theme.secondaryText,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Prompts for the code of conduct if it has not been accepted yet.
  ///
  /// Returns true when the user may post. Posting without this would simply
  /// be rejected by firestore.rules, so the prompt is what turns a silent
  /// permission-denied into an explicit, answerable question.
  Future<bool> _ensureConductAccepted() async {
    if (_acceptedConduct) return true;
    final uid = currentUserUid;
    if (uid.isEmpty) return false;

    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        title: Text('Before you post',
            style: FlutterFlowTheme.of(context).headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The Exchange is for supporting local businesses and the people '
              'behind them.\n\nKeep it respectful: no harassment, no spam, no '
              'false claims about a business. You are responsible for what you '
              'post, and you can delete your own posts at any time.',
              style: FlutterFlowTheme.of(context).bodyMedium,
            ),
            const SizedBox(height: 16.0),
            // The summary above is a plain-language précis, not the
            // agreement itself. Agreeing here is agreeing to the Terms, so
            // they have to be reachable from the point of consent rather
            // than living on an unlinked page.
            InkWell(
              onTap: () => context.pushNamed(
                  TermsOfServicePageWidget.routeName),
              child: Text(
                'Read the full Terms of Service',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      color: FlutterFlowTheme.of(context).primaryText,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      color: FlutterFlowTheme.of(context).secondaryText,
                    )),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('I agree to the Terms',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      color: FlutterFlowTheme.of(context).secondaryText,
                      fontWeight: FontWeight.bold,
                    )),
          ),
        ],
      ),
    );
    if (agreed != true) return false;

    final result = await KinServices.acceptExchangeConduct(
      uid: uid,
      displayName: currentUserDisplayName,
    );
    if (!result.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Could not save agreement.')),
        );
      }
      return false;
    }
    if (mounted) setState(() => _acceptedConduct = true);
    return true;
  }

  /// The "New Post" composer dialog for a verified business owner.
  ///
  /// Both the header's add_box_outlined button and the "Your Story" tile
  /// open this. It used to skip the conduct check entirely and write
  /// straight to Firestore with no try/catch - firestore.rules requires
  /// exchange_profiles.agreed_to_conduct for every exchange_posts create, so
  /// an owner who hadn't accepted yet got an unhandled permission-denied
  /// exception and no feedback. This mirrors the persistent composer's
  /// _ensureConductAccepted + try/catch instead.
  Future<void> _showNewPostDialog(
    BuildContext context,
    DocumentReference? businessRef,
  ) async {
    if (!await _ensureConductAccepted()) return;
    if (!context.mounted) return;
    final theme = FlutterFlowTheme.of(context);
    // Chip selection only makes sense here - this dialog is reached only
    // via isVerifiedBusinessOwner's add_box_outlined button, unlike the
    // persistent bottom composer which any signed-in user (including a
    // customer with no business) can use. Local to this call, not _model,
    // since it resets every time the dialog opens.
    ExchangePostType? selectedType;
    // Local to this call, same reasoning as selectedType - the dialog opens
    // and closes independently of this widget's own state, so nothing here
    // needs to survive past a single showDialog invocation.
    SelectedFile? selectedMedia;
    bool selectedMediaIsVideo = false;
    bool isPosting = false;
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.secondaryBackground,
              title: Text('New Post', style: theme.headlineSmall),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _model.postTextController,
                      focusNode: _model.postTextFieldFocusNode,
                      autofocus: true,
                      maxLines: 4,
                      style: theme.bodyMedium.override(color: theme.primaryText),
                      decoration: InputDecoration(
                        hintText: 'What\'s happening at your business?',
                        hintStyle: theme.bodyMedium.override(color: theme.hint),
                      ),
                    ),
                    SizedBox(height: theme.designToken.spacing.sm),
                    Text(
                      'Tag this post (optional)',
                      style: theme.labelSmall
                          .override(color: theme.secondaryText),
                    ),
                    SizedBox(height: theme.designToken.spacing.xs),
                    Wrap(
                      spacing: theme.designToken.spacing.xs,
                      runSpacing: theme.designToken.spacing.xs,
                      children: kExchangePostTypes.map((type) {
                        final isSelected = selectedType?.key == type.key;
                        return ChoiceChip(
                          avatar: Icon(type.icon,
                              size: 16.0,
                              color: isSelected
                                  ? theme.onPrimary
                                  : theme.secondaryText),
                          label: Text(type.label),
                          selected: isSelected,
                          onSelected: (selected) => setDialogState(() {
                            selectedType = selected ? type : null;
                          }),
                          selectedColor: theme.primary,
                          backgroundColor: theme.primaryBackground,
                          side: BorderSide(color: theme.alternate),
                          labelStyle: theme.labelSmall.override(
                            color: isSelected
                                ? theme.onPrimary
                                : theme.primaryText,
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: theme.designToken.spacing.sm),
                    if (selectedMedia == null)
                      OutlinedButton.icon(
                        onPressed: () async {
                          final media = await _pickPostMedia(dialogContext);
                          if (media == null) return;
                          setDialogState(() {
                            selectedMedia = media;
                            selectedMediaIsVideo =
                                media.storagePath.endsWith('.mp4');
                          });
                        },
                        icon: Icon(Icons.attach_file, size: 16.0,
                            color: theme.secondaryText),
                        label: Text('Add photo or video',
                            style: theme.labelSmall
                                .override(color: theme.secondaryText)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.alternate),
                        ),
                      )
                    else
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                                theme.designToken.radius.sm),
                            child: selectedMediaIsVideo
                                ? Container(
                                    width: 56.0,
                                    height: 56.0,
                                    color: Colors.black87,
                                    child: const Icon(Icons.videocam,
                                        color: Colors.white, size: 24.0),
                                  )
                                : Image.memory(
                                    selectedMedia!.bytes,
                                    width: 56.0,
                                    height: 56.0,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          SizedBox(width: theme.designToken.spacing.xs),
                          Text(
                            selectedMediaIsVideo ? 'Video attached'
                                : 'Photo attached',
                            style: theme.bodySmall
                                .override(color: theme.secondaryText),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, size: 18.0,
                                color: theme.secondaryText),
                            onPressed: () =>
                                setDialogState(() => selectedMedia = null),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isPosting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text('Cancel',
                      style: theme.bodyMedium
                          .override(color: theme.secondaryText)),
                ),
                TextButton(
                  onPressed: isPosting
                      ? null
                      : () async {
                    final postText =
                        _model.postTextController!.text.trim();
                    if (postText.isEmpty || currentUserReference == null) {
                      return;
                    }
                    setDialogState(() => isPosting = true);
                    String? uploadedUrl;
                    if (selectedMedia != null) {
                      uploadedUrl = await _uploadPostMedia(selectedMedia!);
                      if (uploadedUrl == null) {
                        setDialogState(() => isPosting = false);
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Upload failed. Please try again.')),
                          );
                        }
                        return;
                      }
                    }
                    final exchangePostsRecordReference =
                        ExchangePostsRecord.collection.doc();
                    try {
                      await exchangePostsRecordReference.set(
                        createExchangePostsRecordData(
                          postId: exchangePostsRecordReference.id,
                          userRef: currentUserReference,
                          businessRef: businessRef,
                          postText: postText,
                          postImage: selectedMediaIsVideo
                              ? null : uploadedUrl,
                          postVideo: selectedMediaIsVideo
                              ? uploadedUrl : null,
                          timestamp: getCurrentTimestamp,
                          likesCount: 0,
                          // Copied onto the post so the feed never has to read
                          // another user's document to render a byline.
                          authorName: currentUserDisplayName,
                          authorPhoto: currentUserPhoto,
                          postType: selectedType?.key,
                          ctaType: selectedType?.ctaType,
                        ),
                      );
                    } catch (e) {
                      setDialogState(() => isPosting = false);
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Could not post: $e')),
                        );
                      }
                      return;
                    }
                    try {
                      await UserEngagementEventsRecord.collection.doc().set(
                            createUserEngagementEventsRecordData(
                              userRef: currentUserReference,
                              businessRef: businessRef,
                              targetRef: exchangePostsRecordReference,
                              eventType: 'post',
                              createdAt: getCurrentTimestamp,
                            ),
                          );
                    } catch (_) {}
                    unawaited(KinServices
                        .incrementExchangePostCount(currentUserReference!));
                    _model.postTextController?.clear();
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: isPosting
                      ? SizedBox(
                          width: 18.0,
                          height: 18.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(theme.primary),
                          ),
                        )
                      : Text('Post',
                          style: theme.bodyMedium.override(
                              color: theme.primaryText,
                              fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  /// Shown instead of the feed when the Exchange is opened for a specific
  /// business that no owner has claimed yet.
  Widget _buildUnclaimedState(
    BuildContext context,
    BusinessesRecord business,
  ) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        automaticallyImplyLeading: true,
        // The default back arrow was left to Flutter's own light/dark
        // guess against a solid brand-green bar - explicit here so it's a
        // deliberate choice, matching the title text's color, rather than
        // whatever Material happens to compute.
        foregroundColor: theme.info,
        title: Text(
          'The Exchange',
          style: theme.headlineMedium.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            color: theme.info,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
            child: MainMenuButton(),
          ),
        ],
        centerTitle: false,
        elevation: 0.0,
      ),
      bottomNavigationBar: KinBottomNav2Widget(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_outlined, size: 56.0, color: theme.primary),
              const SizedBox(height: 20.0),
              Text(
                'Not claimed yet',
                textAlign: TextAlign.center,
                style: theme.headlineSmall,
              ),
              const SizedBox(height: 12.0),
              Text(
                '${business.businessName} hasn\'t been claimed by its owner. '
                'The Exchange unlocks once they claim and verify the '
                'business.',
                textAlign: TextAlign.center,
                style: theme.bodyMedium.override(color: theme.secondaryText),
              ),
              const SizedBox(height: 24.0),
              FFButtonWidget(
                onPressed: () => context.pushNamed(
                  ClaimBusinessWidget.routeName,
                  queryParameters: {
                    'businessRef': serializeParam(
                      business.reference,
                      ParamType.DocumentReference,
                    ),
                  }.withoutNulls,
                ),
                text: 'Claim This Business',
                icon: const Icon(Icons.verified_outlined, size: 18.0),
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 48.0,
                  iconColor: theme.info,
                  color: theme.primary,
                  textStyle: theme.titleSmall.override(
                    font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600),
                    color: theme.info,
                  ),
                  elevation: 0.0,
                  borderRadius: BorderRadius.circular(
                      theme.designToken.radius.sm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The Exchange is a per-business feed, but not every entry point knows
    // which business that is. The Directory tab opens CustomerProfilePage
    // with no businessRef, so its "The Exchange" card forwards a null one
    // (queryParameters uses .withoutNulls, which drops the key entirely).
    // Force-unwrapping that here crashed the page for anyone arriving from
    // the bottom nav - the common path. Fall back to the business the
    // signed-in user owns, and show an empty state when there is none.
    final businessRef =
        widget.businessRef ?? currentUserDocument?.ownedBusiness;

    // No business is now an ordinary state, not a wall. The Exchange is a
    // place anyone can be - a customer who owns nothing gets the same feed
    // and the same composer as an owner. Previously this returned
    // _buildNoBusinessState and the entire page was unreachable for them,
    // which is most of the people the Exchange is meant to be for.
    return StreamBuilder<BusinessesRecord?>(
      stream: businessRef == null
          ? Stream<BusinessesRecord?>.value(null)
          : BusinessesRecord.getDocument(businessRef)
              .map<BusinessesRecord?>((r) => r)
              .handleError((_) {}),
      builder: (context, snapshot) {
        // A reference can outlive the document it points at - the businesses
        // collection was re-imported at least once, which left several
        // users.owned_business refs pointing at deleted docs. fromSnapshot
        // throws on a non-existent document, so without this the page sat on
        // the spinner forever instead of ever resolving.
        // A dangling business ref is no longer a dead end either - the feed
        // is global, so a broken owned_business just means no business tag.
        // Fall through with a null record rather than replacing the page.
        //
        // Waiting is checked by connectionState, not hasData. `hasData` is
        // false when the value *is* null, so once no-business became a legal
        // state this guard held the page on its spinner forever for exactly
        // the users the global feed was opened up for.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).secondaryText,
                  ),
                ),
              ),
            ),
          );
        }

        final theExchangeBusinessesRecord = snapshot.data;

        // A specific business was requested (a profile page's Exchange
        // button, the shoutout carousel, a deep link) and it hasn't been
        // claimed yet. Every business is listed the moment an admin adds it
        // - is_claimed only flips once an owner's claim is approved - so
        // without this an admin-added, never-claimed business (nobody
        // accountable for what gets posted under its name) would get the
        // exact same Exchange access as one with a verified owner behind it.
        //
        // This deliberately does NOT apply to the null-businessRef case
        // (bottom nav / main menu, which falls back to the signed-in user's
        // *own* owned_business above) - that business only has an owner_ref
        // at all because a claim was already approved for it.
        if (widget.businessRef != null &&
            theExchangeBusinessesRecord != null &&
            !theExchangeBusinessesRecord.isClaimed) {
          return _buildUnclaimedState(context, theExchangeBusinessesRecord);
        }

        final isVerifiedBusinessOwner = currentUserReference != null &&
            theExchangeBusinessesRecord?.ownerRef == currentUserReference &&
            (theExchangeBusinessesRecord?.isVerified ?? false);
        _model.postTextController ??= TextEditingController();
        _model.postTextFieldFocusNode ??= FocusNode();
        _model.feedComposerController ??= TextEditingController();
        _model.feedComposerFocusNode ??= FocusNode();

        return Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          // The Exchange had no app bar, no back control and no nav bar, so
          // once you were here the only way out was the system back-swipe -
          // and on a tab that is pushed rather than popped, that isn't
          // obvious. Same dead end, and the same fix, as
          // CustomerProfilePage.
          bottomNavigationBar: KinBottomNav2Widget(),
          body: SafeArea(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 140.0),
                    child: SingleChildScrollView(
                      primary: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .primaryBackground,
                            ),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  FlutterFlowTheme.of(context)
                                      .designToken
                                      .spacing
                                      .lg,
                                  FlutterFlowTheme.of(context)
                                      .designToken
                                      .spacing
                                      .md,
                                  FlutterFlowTheme.of(context)
                                      .designToken
                                      .spacing
                                      .lg,
                                  FlutterFlowTheme.of(context)
                                      .designToken
                                      .spacing
                                      .md),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      MainMenuButton(),
                                      SizedBox(width: 12.0),
                                      Text(
                                        'The Exchange',
                                        style: FlutterFlowTheme.of(context)
                                            .headlineMedium
                                            .override(
                                              font: GoogleFonts
                                                  .plusJakartaSans(
                                                fontWeight: FontWeight.bold,
                                                fontStyle:
                                                    FlutterFlowTheme.of(
                                                            context)
                                                        .headlineMedium
                                                        .fontStyle,
                                              ),
                                              color: FlutterFlowTheme.of(
                                                      context)
                                                  .primaryText,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .headlineMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      if (isVerifiedBusinessOwner)
                                        FlutterFlowIconButton(
                                          buttonSize: 42.0,
                                          icon: Icon(
                                            Icons.add_box_outlined,
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            size: 26.0,
                                          ),
                                          onPressed: () async {
                                            if (!isVerifiedBusinessOwner) {
                                              return;
                                            }
                                            await _showNewPostDialog(
                                              context,
                                              theExchangeBusinessesRecord
                                                  ?.reference,
                                            );
                                            safeSetState(() {});
                                          },
                                        ),
                                      // Removed: a forum icon, on the forum
                                      // page, painted in the dark brand
                                      // green against a dark background so
                                      // it was barely visible, wired to
                                      // `print('IconButton pressed ...')`.
                                      // It pointed at nothing and did
                                      // nothing.
                                    ].divide(SizedBox(
                                        width: FlutterFlowTheme.of(context)
                                            .designToken
                                            .spacing
                                            .sm)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _buildTermsBanner(),
                          const _DailyPromptBanner(),
                          KindexSpotlightWidget(),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                FlutterFlowTheme.of(context)
                                    .designToken
                                    .spacing
                                    .lg,
                                0.0,
                                FlutterFlowTheme.of(context)
                                    .designToken
                                    .spacing
                                    .lg,
                                FlutterFlowTheme.of(context)
                                    .designToken
                                    .spacing
                                    .md),
                            // The global feed. This used to filter on
                            // business_ref == the business being viewed,
                            // which made the Exchange one business's wall
                            // rather than a place: 8 posts existed and the
                            // page read "No posts yet" because they belonged
                            // to other businesses. A post's business_ref is
                            // now a tag on the post, not the thing that
                            // decides whether you can see it.
                            //
                            // Ordered newest-first and bounded - an
                            // unbounded feed re-reads every post ever
                            // written on each open.
                            child: StreamBuilder<List<ExchangePostsRecord>>(
                              stream: queryExchangePostsRecord(
                                queryBuilder: (exchangePostsRecord) =>
                                    exchangePostsRecord.orderBy('timestamp',
                                        descending: true),
                                limit: 50,
                              ),
                              builder: (context, snapshot) {
                                // Customize what your widget looks like when it's loading.
                                if (!snapshot.hasData) {
                                  return Center(
                                    child: SizedBox(
                                      width: 50.0,
                                      height: 50.0,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          FlutterFlowTheme.of(context)
                                              .secondaryText,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                List<ExchangePostsRecord>
                                    columnExchangePostsRecordList =
                                    snapshot.data!;

                                if (columnExchangePostsRecordList.isEmpty) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: FlutterFlowTheme.of(context)
                                            .designToken
                                            .spacing
                                            .xl),
                                    child: Text(
                                      'No posts yet. Be the first to join the conversation.',
                                      textAlign: TextAlign.center,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.plusJakartaSans(),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                  );
                                }

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: List.generate(
                                      columnExchangePostsRecordList.length,
                                      (columnIndex) {
                                    final columnExchangePostsRecord =
                                        columnExchangePostsRecordList[
                                            columnIndex];
                                    // No per-post user lookup. Reading
                                    // users/{uid} for another user is denied
                                    // by firestore.rules, so this used to
                                    // render a spinner that never resolved -
                                    // one per post, forever. The author's
                                    // name and avatar now travel on the post
                                    // itself (see ExchangePostsRecord).
                                    //
                                    // Posts written before that field existed
                                    // fall back to 'Member' rather than a
                                    // spinner: an unnamed byline is a far
                                    // better failure than a feed that never
                                    // finishes loading.
                                    return ExchangeFeedItemWidget(
                                      key: Key(
                                          'Keyt40_${columnExchangePostsRecord.reference.id}'),
                                      postRecord: columnExchangePostsRecord,
                                      businessRef:
                                          columnExchangePostsRecord.businessRef,
                                      authorDisplayName:
                                          columnExchangePostsRecord
                                                  .authorName.isNotEmpty
                                              ? columnExchangePostsRecord
                                                  .authorName
                                              : 'Member',
                                      authorPhotoUrl: columnExchangePostsRecord
                                          .authorPhoto,
                                    );
                                  }),
                                );
                              },
                            ),
                          ),
                          // Was 5 hardcoded stock photos ("The Grind",
                          // "Heritage", "Pearl Gold"...) with fake labels,
                          // identical for every viewer and unrelated to any
                          // real business - decorative content presented as
                          // if it were real. Replaced with a live rail of
                          // exchange_promotions: the same collection
                          // Customer Profile's "Exclusive Connection
                          // Stream" already reads but that always showed
                          // "No live offers", because nothing in the app
                          // ever wrote to it. CreatePromotionSheet is that
                          // missing write path.
                          StreamBuilder<List<ExchangePromotionsRecord>>(
                            stream: queryExchangePromotionsRecord(
                              queryBuilder: (exchangePromotionsRecord) =>
                                  exchangePromotionsRecord.orderBy(
                                      'created_at',
                                      descending: true),
                              limit: 20,
                            ),
                            builder: (context, promoSnapshot) {
                              final now = DateTime.now();
                              final livePromos = (promoSnapshot.data ?? [])
                                  .where((promo) =>
                                      countdownLabel(promo.expiresAt,
                                          now: now) !=
                                      null)
                                  .toList();
                              if (!isVerifiedBusinessOwner &&
                                  livePromos.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                decoration: BoxDecoration(),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      FlutterFlowTheme.of(context)
                                          .designToken
                                          .spacing
                                          .lg,
                                      0.0,
                                      FlutterFlowTheme.of(context)
                                          .designToken
                                          .spacing
                                          .lg,
                                      0.0),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        if (isVerifiedBusinessOwner)
                                          GestureDetector(
                                            onTap: () async {
                                              final businessRef =
                                                  theExchangeBusinessesRecord
                                                      ?.reference;
                                              if (businessRef == null) return;
                                              await showModalBottomSheet(
                                                isScrollControlled: true,
                                                backgroundColor:
                                                    Colors.transparent,
                                                context: context,
                                                builder: (sheetContext) =>
                                                    Padding(
                                                  padding: MediaQuery
                                                      .viewInsetsOf(
                                                          sheetContext),
                                                  child: CreatePromotionSheet(
                                                      businessRef:
                                                          businessRef),
                                                ),
                                              );
                                            },
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 72.0,
                                                  height: 72.0,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            FlutterFlowTheme
                                                                    .of(
                                                                        context)
                                                                .designToken
                                                                .radius
                                                                .full),
                                                    border: Border.all(
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .divider,
                                                      width: 1.0,
                                                    ),
                                                  ),
                                                  alignment:
                                                      AlignmentDirectional(
                                                          0.0, 0.0),
                                                  child: Icon(
                                                    Icons.add_rounded,
                                                    color: FlutterFlowTheme
                                                            .of(context)
                                                        .primary,
                                                    size: 24.0,
                                                  ),
                                                ),
                                                Text(
                                                  'Add Promo',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .labelSmall
                                                      .override(
                                                        font: GoogleFonts
                                                            .plusJakartaSans(
                                                          fontWeight:
                                                              FlutterFlowTheme
                                                                      .of(
                                                                          context)
                                                                  .labelSmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme
                                                                      .of(
                                                                          context)
                                                                  .labelSmall
                                                                  .fontStyle,
                                                        ),
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .secondaryText,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme
                                                                    .of(
                                                                        context)
                                                                .labelSmall
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme
                                                                    .of(
                                                                        context)
                                                                .labelSmall
                                                                .fontStyle,
                                                      ),
                                                ),
                                              ].divide(SizedBox(
                                                  height: FlutterFlowTheme.of(
                                                          context)
                                                      .designToken
                                                      .spacing
                                                      .xs)),
                                            ),
                                          ),
                                        ...livePromos.map(
                                          (promo) => _PromoStoryTile(
                                              key: Key(
                                                  'promo_${promo.reference.id}'),
                                              promo: promo),
                                        ),
                                      ].divide(SizedBox(
                                          width: FlutterFlowTheme.of(context)
                                              .designToken
                                              .spacing
                                              .md)),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                FlutterFlowTheme.of(context)
                                    .designToken
                                    .spacing
                                    .lg,
                                0.0,
                                FlutterFlowTheme.of(context)
                                    .designToken
                                    .spacing
                                    .lg,
                                FlutterFlowTheme.of(context)
                                    .designToken
                                    .spacing
                                    .xl),
                            child: Divider(
                              thickness: 1.0,
                              color: FlutterFlowTheme.of(context).divider,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(),
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 15.0,
                          sigmaY: 15.0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                FlutterFlowTheme.of(context)
                                    .designToken
                                    .spacing
                                    .lg,
                                FlutterFlowTheme.of(context)
                                    .designToken
                                    .spacing
                                    .md,
                                FlutterFlowTheme.of(context)
                                    .designToken
                                    .spacing
                                    .lg,
                                FlutterFlowTheme.of(context)
                                    .designToken
                                    .spacing
                                    .lg),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          FlutterFlowTheme.of(context)
                                              .designToken
                                              .radius
                                              .full),
                                      child: Container(
                                        width: 44.0,
                                        height: 44.0,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              FlutterFlowTheme.of(context)
                                                  .designToken
                                                  .radius
                                                  .full),
                                          border: Border.all(
                                            color: FlutterFlowTheme.of(context)
                                                .divider,
                                            width: 1.0,
                                          ),
                                        ),
                                        // Was a hardcoded stock photo
                                        // regardless of whether the
                                        // signed-in user has a real photo -
                                        // not a fallback, just always wrong.
                                        // Now shows currentUserPhoto when
                                        // set, and the same initials-on-flat-
                                        // color fallback _PromoStoryTile uses
                                        // below when it isn't.
                                        child: currentUserPhoto.isNotEmpty
                                            ? CachedNetworkImage(
                                                fadeInDuration:
                                                    Duration(milliseconds: 0),
                                                fadeOutDuration:
                                                    Duration(milliseconds: 0),
                                                imageUrl: currentUserPhoto,
                                                fit: BoxFit.cover,
                                                memCacheWidth: (44.0 *
                                                        MediaQuery
                                                            .devicePixelRatioOf(
                                                                context))
                                                    .round(),
                                                memCacheHeight: (44.0 *
                                                        MediaQuery
                                                            .devicePixelRatioOf(
                                                                context))
                                                    .round(),
                                              )
                                            : Container(
                                                color: FlutterFlowTheme.of(
                                                        context)
                                                    .secondaryBackground,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  businessInitials(
                                                      currentUserDisplayName),
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        font: GoogleFonts
                                                            .plusJakartaSans(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .primaryText,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        letterSpacing: 0.0,
                                                      ),
                                                ),
                                              ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        height: 48.0,
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .primaryBackground,
                                          borderRadius: BorderRadius.circular(
                                              FlutterFlowTheme.of(context)
                                                  .designToken
                                                  .radius
                                                  .full),
                                          border: Border.all(
                                            color: FlutterFlowTheme.of(context)
                                                .divider,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  FlutterFlowTheme.of(context)
                                                      .designToken
                                                      .spacing
                                                      .md,
                                                  0.0,
                                                  FlutterFlowTheme.of(context)
                                                      .designToken
                                                      .spacing
                                                      .md,
                                                  0.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                flex: 1,
                                                // Was gated on
                                                // isVerifiedBusinessOwner, so
                                                // the field itself did not
                                                // exist for anyone - no
                                                // business has an owner yet.
                                                // The Exchange is a
                                                // conversation, so anyone
                                                // signed in gets the composer;
                                                // the code of conduct is
                                                // checked on send.
                                                child:
                                                    currentUserReference != null
                                                        ? TextFormField(
                                                            controller: _model
                                                                .feedComposerController,
                                                            focusNode: _model
                                                                .feedComposerFocusNode,
                                                            decoration:
                                                                InputDecoration(
                                                              hintText:
                                                                  'Join the conversation...',
                                                              hintStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .hint,
                                                                      ),
                                                              border:
                                                                  InputBorder
                                                                      .none,
                                                              isDense: true,
                                                            ),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium,
                                                          )
                                                        : Text(
                                                            'Join the conversation...',
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .plusJakartaSans(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .hint,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                          ),
                                              ),
                                              if (_pendingMedia != null) ...[
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .designToken
                                                              .radius
                                                              .sm),
                                                  child: _pendingMediaIsVideo
                                                      ? Container(
                                                          width: 32.0,
                                                          height: 32.0,
                                                          color:
                                                              Colors.black87,
                                                          child: const Icon(
                                                              Icons.videocam,
                                                              color: Colors
                                                                  .white,
                                                              size: 16.0),
                                                        )
                                                      : Image.memory(
                                                          _pendingMedia!
                                                              .bytes,
                                                          width: 32.0,
                                                          height: 32.0,
                                                          fit: BoxFit.cover,
                                                        ),
                                                ),
                                                InkWell(
                                                  onTap: () => safeSetState(
                                                      () =>
                                                          _pendingMedia =
                                                              null),
                                                  child: Icon(Icons.close,
                                                      size: 16.0,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText),
                                                ),
                                              ] else
                                                InkWell(
                                                  // A signed-in user with no
                                                  // media selected yet gets
                                                  // the attach control; the
                                                  // composer field above is
                                                  // already gated on
                                                  // currentUserReference, so
                                                  // this mirrors that.
                                                  onTap:
                                                      currentUserReference ==
                                                                  null ||
                                                              _uploadingPendingMedia
                                                          ? null
                                                          : () async {
                                                              final media =
                                                                  await _pickPostMedia(
                                                                      context);
                                                              if (media ==
                                                                  null) {
                                                                return;
                                                              }
                                                              safeSetState(
                                                                  () {
                                                                _pendingMedia =
                                                                    media;
                                                                _pendingMediaIsVideo =
                                                                    media.storagePath
                                                                        .endsWith(
                                                                            '.mp4');
                                                              });
                                                            },
                                                  child: Icon(
                                                      Icons.attach_file,
                                                      size: 20.0,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText),
                                                ),
                                            ].divide(SizedBox(
                                                width:
                                                    FlutterFlowTheme.of(context)
                                                        .designToken
                                                        .spacing
                                                        .sm)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _uploadingPendingMedia
                                          ? null
                                          : () async {
                                        print(
                                            'TheExchangeWidget: composer send tapped');
                                        final composerText = _model
                                            .feedComposerController?.text
                                            .trim();
                                        if (composerText == null ||
                                            composerText.isEmpty ||
                                            currentUserReference == null) {
                                          print(
                                              'TheExchangeWidget: composer send ignored (empty text or not logged in)');
                                          return;
                                        }
                                        if (!await _ensureConductAccepted()) {
                                          print(
                                              'TheExchangeWidget: composer send ignored (conduct not accepted)');
                                          return;
                                        }
                                        // The upload has to land before the
                                        // Firestore write - post_video/
                                        // post_image can only ever be set on
                                        // the create call, firestore.rules
                                        // forbids patching either in later.
                                        String? uploadedUrl;
                                        final pendingMedia = _pendingMedia;
                                        final pendingMediaIsVideo =
                                            _pendingMediaIsVideo;
                                        if (pendingMedia != null) {
                                          safeSetState(() =>
                                              _uploadingPendingMedia = true);
                                          uploadedUrl = await _uploadPostMedia(
                                              pendingMedia);
                                          safeSetState(() =>
                                              _uploadingPendingMedia = false);
                                          if (uploadedUrl == null) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                      content: Text(
                                                          'Upload failed. Please try again.')));
                                            }
                                            return;
                                          }
                                        }
                                        final exchangePostsRecordReference =
                                            ExchangePostsRecord.collection
                                                .doc();
                                        await exchangePostsRecordReference.set(
                                          createExchangePostsRecordData(
                                            postId:
                                                exchangePostsRecordReference.id,
                                            userRef: currentUserReference,
                                            businessRef:
                                                theExchangeBusinessesRecord
                                                    ?.reference,
                                            postText: composerText,
                                            postImage: pendingMediaIsVideo
                                                ? null
                                                : uploadedUrl,
                                            postVideo: pendingMediaIsVideo
                                                ? uploadedUrl
                                                : null,
                                            timestamp: getCurrentTimestamp,
                                            likesCount: 0,
                                            // This composer used to omit
                                            // both - _showNewPostDialog set
                                            // them, this one didn't, so a
                                            // post from here rendered with
                                            // ExchangeFeedItemWidget's
                                            // 'Member' fallback and the
                                            // default headshot regardless of
                                            // who actually posted.
                                            authorName: currentUserDisplayName,
                                            authorPhoto: currentUserPhoto,
                                          ),
                                        );
                                        unawaited(KinServices
                                            .incrementExchangePostCount(
                                                currentUserReference!));
                                        try {
                                          await UserEngagementEventsRecord
                                              .collection
                                              .doc()
                                              .set(
                                                createUserEngagementEventsRecordData(
                                                  userRef: currentUserReference,
                                                  businessRef:
                                                      theExchangeBusinessesRecord
                                                          ?.reference,
                                                  targetRef:
                                                      exchangePostsRecordReference,
                                                  eventType: 'post',
                                                  createdAt:
                                                      getCurrentTimestamp,
                                                ),
                                              );
                                        } catch (_) {}
                                        _model.feedComposerController?.clear();
                                        _pendingMedia = null;
                                        safeSetState(() {});
                                      },
                                      child: Container(
                                        width: 48.0,
                                        height: 48.0,
                                        decoration: BoxDecoration(
                                          // Was secondaryText (near-black
                                          // in light mode) with a primary
                                          // (dark green) icon - both dark,
                                          // so the send icon was nearly
                                          // invisible in light mode. primary
                                          // is the same forest green in
                                          // both themes; paired with
                                          // onPrimary (white, both themes)
                                          // it's legible either way.
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          borderRadius: BorderRadius.circular(
                                              FlutterFlowTheme.of(context)
                                                  .designToken
                                                  .radius
                                                  .full),
                                        ),
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0),
                                        child: _uploadingPendingMedia
                                            ? SizedBox(
                                                width: 20.0,
                                                height: 20.0,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.0,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                              Color>(
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .onPrimary),
                                                ),
                                              )
                                            : Icon(
                                                Icons.send_rounded,
                                                color: FlutterFlowTheme.of(
                                                        context)
                                                    .onPrimary,
                                                size: 20.0,
                                              ),
                                      ),
                                    ),
                                  ].divide(SizedBox(
                                      width: FlutterFlowTheme.of(context)
                                          .designToken
                                          .spacing
                                          .md)),
                                ),
                              ].divide(SizedBox(
                                  height: FlutterFlowTheme.of(context)
                                      .designToken
                                      .spacing
                                      .md)),
                            ),
                          ),
                        ),
                      ),
                    ),
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

/// Pinned "Daily Founder Topic" banner above the feed. Looks for today's
/// exchange_prompts doc first (activeDate matching the calendar day);
/// falls back to the most recent pinned==true doc if there's no match for
/// today, so a gap in the admin's daily schedule shows an evergreen
/// prompt instead of nothing. Renders nothing (not a loading spinner) if
/// neither query turns anything up - a missing prompt should be invisible,
/// not a placeholder the feed has to explain.
class _DailyPromptBanner extends StatefulWidget {
  const _DailyPromptBanner();

  @override
  State<_DailyPromptBanner> createState() => _DailyPromptBannerState();
}

class _DailyPromptBannerState extends State<_DailyPromptBanner> {
  late final Future<ExchangePromptsRecord?> _future = _loadTodayPrompt();

  Future<ExchangePromptsRecord?> _loadTodayPrompt() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    try {
      final todaySnap = await ExchangePromptsRecord.collection
          .where('active_date', isGreaterThanOrEqualTo: startOfDay)
          .where('active_date', isLessThan: endOfDay)
          .limit(1)
          .get();
      if (todaySnap.docs.isNotEmpty) {
        return ExchangePromptsRecord.fromSnapshot(todaySnap.docs.first);
      }
      // Fallback query needs a composite index (pinned equality + orderBy
      // on a different field) - Firestore throws FAILED_PRECONDITION with
      // a console link the first time this runs until that index exists.
      // Caught below like any other failure: the banner just doesn't show.
      final pinnedSnap = await ExchangePromptsRecord.collection
          .where('pinned', isEqualTo: true)
          .orderBy('active_date', descending: true)
          .limit(1)
          .get();
      if (pinnedSnap.docs.isNotEmpty) {
        return ExchangePromptsRecord.fromSnapshot(pinnedSnap.docs.first);
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return FutureBuilder<ExchangePromptsRecord?>(
      future: _future,
      builder: (context, snapshot) {
        final prompt = snapshot.data;
        if (prompt == null || prompt.text.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
              theme.designToken.spacing.lg,
              0.0,
              theme.designToken.spacing.lg,
              theme.designToken.spacing.md),
          child: Container(
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(theme.designToken.radius.md),
              border: Border.all(color: theme.accent1.withValues(alpha: 0.35)),
            ),
            child: Padding(
              padding: EdgeInsets.all(theme.designToken.spacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.push_pin_rounded,
                      size: 18.0, color: theme.accentOnSurface),
                  SizedBox(width: theme.designToken.spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TODAY\'S TOPIC',
                          style: theme.labelSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold),
                            color: theme.accentOnSurface,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4.0),
                        Text(
                          prompt.text,
                          style: theme.bodyMedium.override(
                            font: GoogleFonts.plusJakartaSans(),
                            color: theme.primaryText,
                            letterSpacing: 0.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One tile in the promo rail: a real business's live exchange_promotions
/// doc, in the same circular-avatar-plus-label shape the old fake story
/// tiles used. Silently renders nothing if the business can't be resolved -
/// same "cannot honestly render without both halves" rule Customer
/// Profile's _loadPromos applies to the same collection.
class _PromoStoryTile extends StatelessWidget {
  const _PromoStoryTile({super.key, required this.promo});

  final ExchangePromotionsRecord promo;

  void _openDetail(BuildContext context, BusinessesRecord business) {
    final theme = FlutterFlowTheme.of(context);
    final countdown = countdownLabel(promo.expiresAt, now: DateTime.now());
    if (countdown == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.all(theme.designToken.spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PromoCardWidget(
              initial: businessInitials(business.businessName),
              business: business.businessName,
              time: countdown,
              deal: promo.body.isNotEmpty ? promo.body : promo.title,
            ),
            SizedBox(height: theme.designToken.spacing.md),
            FFButtonWidget(
              onPressed: () {
                Navigator.pop(sheetContext);
                context.pushNamed(
                  BusinessProfileV2Widget.routeName,
                  queryParameters: {
                    'businessDocument': serializeParam(
                      business.reference,
                      ParamType.DocumentReference,
                    ),
                  }.withoutNulls,
                );
              },
              text: 'View Business',
              options: FFButtonOptions(
                width: double.infinity,
                height: 44.0,
                color: theme.primary,
                textStyle: theme.titleSmall.override(color: theme.onPrimary),
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

  @override
  Widget build(BuildContext context) {
    final businessRef = promo.businessRef;
    if (businessRef == null) return const SizedBox.shrink();
    final theme = FlutterFlowTheme.of(context);
    return StreamBuilder<BusinessesRecord>(
      stream: BusinessesRecord.getDocument(businessRef),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.businessName.isEmpty) {
          return const SizedBox.shrink();
        }
        final business = snapshot.data!;
        return GestureDetector(
          onTap: () => _openDetail(context, business),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 72.0,
                height: 72.0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.accent1, theme.secondary],
                    stops: [0.0, 1.0],
                    begin: AlignmentDirectional(-1.0, 1.0),
                    end: AlignmentDirectional(1.0, -1.0),
                  ),
                  borderRadius:
                      BorderRadius.circular(theme.designToken.radius.full),
                ),
                child: Padding(
                  padding: EdgeInsets.all(2.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.primaryBackground,
                      borderRadius: BorderRadius.circular(
                          theme.designToken.radius.full),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(3.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                            theme.designToken.radius.full),
                        child: promo.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                fadeInDuration: Duration(milliseconds: 0),
                                fadeOutDuration: Duration(milliseconds: 0),
                                imageUrl: promo.imageUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: (72.0 *
                                        MediaQuery.devicePixelRatioOf(
                                            context))
                                    .round(),
                                memCacheHeight: (72.0 *
                                        MediaQuery.devicePixelRatioOf(
                                            context))
                                    .round(),
                              )
                            : Container(
                                color: theme.secondaryBackground,
                                alignment: Alignment.center,
                                child: Text(
                                  businessInitials(business.businessName),
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
                  ),
                ),
              ),
              SizedBox(height: theme.designToken.spacing.xs),
              SizedBox(
                width: 72.0,
                child: Text(
                  business.businessName,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelSmall.override(
                    font: GoogleFonts.plusJakartaSans(),
                    color: theme.primaryText,
                    letterSpacing: 0.0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
