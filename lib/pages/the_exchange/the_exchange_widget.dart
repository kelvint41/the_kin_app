import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/services/kin_services.dart';
import '/components/exchange_feed_item_widget.dart';
import '/components/kindex_spotlight_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/old_designs/premium_story/premium_story_widget.dart';
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
        content: Text(
          'The Exchange is for supporting local businesses and the people '
          'behind them.\n\nKeep it respectful: no harassment, no spam, no '
          'false claims about a business. You are responsible for what you '
          'post, and you can delete your own posts at any time.',
          style: FlutterFlowTheme.of(context).bodyMedium,
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
            child: Text('I agree',
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

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  /// Shown when there is no business to display a feed for - reached from the
  /// Directory tab by a user who does not own a business yet.
  Widget _buildNoBusinessState(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(32.0, 0.0, 32.0, 0.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.storefront_outlined,
                color: FlutterFlowTheme.of(context).secondaryText,
                size: 48.0,
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 8.0),
                child: Text(
                  'No business selected',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).headlineSmall,
                ),
              ),
              Text(
                'Open The Exchange from a business profile, or claim your own '
                'business to start posting.',
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 0.0),
                child: TextButton(
                  onPressed: () => context.safePop(),
                  child: Text(
                    'Go back',
                    // Not `primary` - that token is the brand dark green,
                    // which is close to unreadable on the dark background
                    // this page uses.
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          color: FlutterFlowTheme.of(context).secondaryText,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
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
    if (businessRef == null) {
      return _buildNoBusinessState(context);
    }

    return StreamBuilder<BusinessesRecord>(
      stream: BusinessesRecord.getDocument(businessRef),
      builder: (context, snapshot) {
        // A reference can outlive the document it points at - the businesses
        // collection was re-imported at least once, which left several
        // users.owned_business refs pointing at deleted docs. fromSnapshot
        // throws on a non-existent document, so without this the page sat on
        // the spinner forever instead of ever resolving.
        if (snapshot.hasError) {
          return _buildNoBusinessState(context);
        }
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
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

        final theExchangeBusinessesRecord = snapshot.data!;
        final isVerifiedBusinessOwner = currentUserReference != null &&
            theExchangeBusinessesRecord.ownerRef == currentUserReference &&
            theExchangeBusinessesRecord.isVerified;
        _model.postTextController ??= TextEditingController();
        _model.postTextFieldFocusNode ??= FocusNode();
        _model.feedComposerController ??= TextEditingController();
        _model.feedComposerFocusNode ??= FocusNode();

        return Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
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
                                  Text(
                                    'The Exchange',
                                    style: FlutterFlowTheme.of(context)
                                        .headlineMedium
                                        .override(
                                          font: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .headlineMedium
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .headlineMedium
                                                  .fontStyle,
                                        ),
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
                                            await showDialog(
                                              context: context,
                                              builder: (dialogContext) {
                                                return AlertDialog(
                                                  title: Text('New Post'),
                                                  content: TextFormField(
                                                    controller: _model
                                                        .postTextController,
                                                    focusNode: _model
                                                        .postTextFieldFocusNode,
                                                    autofocus: true,
                                                    maxLines: 4,
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          'What\'s happening at your business?',
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              dialogContext),
                                                      child: Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        final postText = _model
                                                            .postTextController!
                                                            .text
                                                            .trim();
                                                        if (postText.isEmpty ||
                                                            currentUserReference ==
                                                                null) {
                                                          return;
                                                        }
                                                        final exchangePostsRecordReference =
                                                            ExchangePostsRecord
                                                                .collection
                                                                .doc();
                                                        await exchangePostsRecordReference
                                                            .set(
                                                          createExchangePostsRecordData(
                                                            postId:
                                                                exchangePostsRecordReference
                                                                    .id,
                                                            userRef:
                                                                currentUserReference,
                                                            businessRef:
                                                                theExchangeBusinessesRecord
                                                                    .reference,
                                                            postText: postText,
                                                            timestamp:
                                                                getCurrentTimestamp,
                                                            likesCount: 0,
                                                          ),
                                                        );
                                                        try {
                                                          await UserEngagementEventsRecord
                                                              .collection
                                                              .doc()
                                                              .set(
                                                                createUserEngagementEventsRecordData(
                                                                  userRef:
                                                                      currentUserReference,
                                                                  businessRef:
                                                                      theExchangeBusinessesRecord
                                                                          .reference,
                                                                  targetRef:
                                                                      exchangePostsRecordReference,
                                                                  eventType:
                                                                      'post',
                                                                  createdAt:
                                                                      getCurrentTimestamp,
                                                                ),
                                                              );
                                                        } catch (_) {}
                                                        _model
                                                            .postTextController
                                                            ?.clear();
                                                        if (dialogContext
                                                            .mounted) {
                                                          Navigator.pop(
                                                              dialogContext);
                                                        }
                                                      },
                                                      child: Text('Post'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                            safeSetState(() {});
                                          },
                                        ),
                                      FlutterFlowIconButton(
                                        buttonSize: 42.0,
                                        icon: Icon(
                                          Icons.forum_outlined,
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          size: 26.0,
                                        ),
                                        onPressed: () {
                                          print('IconButton pressed ...');
                                        },
                                      ),
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
                            child: StreamBuilder<List<ExchangePostsRecord>>(
                              stream: queryExchangePostsRecord(
                                queryBuilder: (exchangePostsRecord) =>
                                    exchangePostsRecord.where(
                                  'business_ref',
                                  isEqualTo:
                                      theExchangeBusinessesRecord.reference,
                                ),
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
                                    return StreamBuilder<UsersRecord>(
                                      stream: UsersRecord.getDocument(
                                          columnExchangePostsRecord.userRef!),
                                      builder: (context, snapshot) {
                                        // Customize what your widget looks like when it's loading.
                                        if (!snapshot.hasData) {
                                          return Center(
                                            child: SizedBox(
                                              width: 50.0,
                                              height: 50.0,
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        final feedItemUsersRecord =
                                            snapshot.data!;

                                        return ExchangeFeedItemWidget(
                                          key: Key(
                                              'Keyt40_${columnExchangePostsRecord.reference.id}'),
                                          postRecord: columnExchangePostsRecord,
                                          businessRef:
                                              theExchangeBusinessesRecord
                                                  .reference,
                                          authorDisplayName:
                                              feedItemUsersRecord.displayName,
                                          authorPhotoUrl:
                                              feedItemUsersRecord.photoUrl,
                                        );
                                      },
                                    );
                                  }),
                                );
                              },
                            ),
                          ),
                          Container(
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
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (isVerifiedBusinessOwner)
                                      Column(
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
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .designToken
                                                          .radius
                                                          .full),
                                              border: Border.all(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .divider,
                                                width: 1.0,
                                              ),
                                            ),
                                            alignment:
                                                AlignmentDirectional(0.0, 0.0),
                                            child: Icon(
                                              Icons.add_rounded,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              size: 24.0,
                                            ),
                                          ),
                                          Text(
                                            'Your Story',
                                            style: FlutterFlowTheme.of(context)
                                                .labelSmall
                                                .override(
                                                  font: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelSmall
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelSmall
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelSmall
                                                          .fontStyle,
                                                ),
                                          ),
                                        ].divide(SizedBox(
                                            height: FlutterFlowTheme.of(context)
                                                .designToken
                                                .spacing
                                                .xs)),
                                      ),
                                    wrapWithModel(
                                      model: _model.premiumStoryModel1,
                                      updateCallback: () => safeSetState(() {}),
                                      child: PremiumStoryWidget(
                                        img_desc:
                                            'https://dimg.dreamflow.cloud/v1/image/smiling%20black%20woman%20coffee%20shop%20owner',
                                        label: 'The Grind',
                                      ),
                                    ),
                                    wrapWithModel(
                                      model: _model.premiumStoryModel2,
                                      updateCallback: () => safeSetState(() {}),
                                      child: PremiumStoryWidget(
                                        img_desc:
                                            'https://dimg.dreamflow.cloud/v1/image/black%20male%20chef%20portrait',
                                        label: 'Heritage',
                                      ),
                                    ),
                                    wrapWithModel(
                                      model: _model.premiumStoryModel3,
                                      updateCallback: () => safeSetState(() {}),
                                      child: PremiumStoryWidget(
                                        img_desc:
                                            'https://dimg.dreamflow.cloud/v1/image/stylish%20black%20woman%20boutique%20owner',
                                        label: 'Pearl Gold',
                                      ),
                                    ),
                                    wrapWithModel(
                                      model: _model.premiumStoryModel4,
                                      updateCallback: () => safeSetState(() {}),
                                      child: PremiumStoryWidget(
                                        img_desc:
                                            'https://dimg.dreamflow.cloud/v1/image/black%20man%20in%20creative%20studio',
                                        label: 'Urban Soul',
                                      ),
                                    ),
                                    wrapWithModel(
                                      model: _model.premiumStoryModel5,
                                      updateCallback: () => safeSetState(() {}),
                                      child: PremiumStoryWidget(
                                        img_desc:
                                            'https://dimg.dreamflow.cloud/v1/image/black%20woman%20yoga%20instructor',
                                        label: 'Kindred',
                                      ),
                                    ),
                                  ].divide(SizedBox(
                                      width: FlutterFlowTheme.of(context)
                                          .designToken
                                          .spacing
                                          .md)),
                                ),
                              ),
                            ),
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
                                        child: CachedNetworkImage(
                                          fadeInDuration:
                                              Duration(milliseconds: 0),
                                          fadeOutDuration:
                                              Duration(milliseconds: 0),
                                          imageUrl:
                                              'https://dimg.dreamflow.cloud/v1/image/modern%20professional%20black%20woman%20headshot',
                                          fit: BoxFit.cover,
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
                                              Icon(
                                                Icons.gif_box_outlined,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                size: 22.0,
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
                                      onTap: () async {
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
                                                    .reference,
                                            postText: composerText,
                                            timestamp: getCurrentTimestamp,
                                            likesCount: 0,
                                          ),
                                        );
                                        try {
                                          await UserEngagementEventsRecord
                                              .collection
                                              .doc()
                                              .set(
                                                createUserEngagementEventsRecordData(
                                                  userRef: currentUserReference,
                                                  businessRef:
                                                      theExchangeBusinessesRecord
                                                          .reference,
                                                  targetRef:
                                                      exchangePostsRecordReference,
                                                  eventType: 'post',
                                                  createdAt:
                                                      getCurrentTimestamp,
                                                ),
                                              );
                                        } catch (_) {}
                                        _model.feedComposerController?.clear();
                                        safeSetState(() {});
                                      },
                                      child: Container(
                                        width: 48.0,
                                        height: 48.0,
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          borderRadius: BorderRadius.circular(
                                              FlutterFlowTheme.of(context)
                                                  .designToken
                                                  .radius
                                                  .full),
                                        ),
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0),
                                        child: Icon(
                                          Icons.send_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
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
