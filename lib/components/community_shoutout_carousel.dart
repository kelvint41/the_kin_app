import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// A single card the carousel can show - either a review left on this
/// business, or a post pulled from the wider Exchange feed. One shape so
/// the carousel doesn't need to know which kind it's holding.
class _Shoutout {
  _Shoutout.review(ReviewsRecord r)
      : isExchangePost = false,
        text = r.reviewText.isNotEmpty ? r.reviewText : null,
        rating = r.rating,
        userRef = r.userRef,
        timestamp = r.timestamp,
        likesCount = null;

  _Shoutout.exchangePost(ExchangePostsRecord p)
      : isExchangePost = true,
        text = p.postText.isNotEmpty ? p.postText : null,
        rating = null,
        userRef = p.userRef,
        timestamp = p.timestamp,
        likesCount = p.likesCount;

  final bool isExchangePost;
  final String? text;
  final double? rating;
  final DocumentReference? userRef;
  final DateTime? timestamp;
  final int? likesCount;
}

/// A rotating carousel mixing a business's real reviews with recent posts
/// from The Exchange feed, styled as quote cards rather than a data list.
///
/// Replaces the KINDEX gauge that used to sit here: the score already has
/// a home in the stat tile above, so the gauge duplicated it. Folding in
/// Exchange posts (not just this business's own reviews) gives an owner a
/// reason to tap through to the feed itself, rather than a dead end.
class CommunityShoutoutCarousel extends StatefulWidget {
  const CommunityShoutoutCarousel({super.key, required this.businessRef});

  final DocumentReference businessRef;

  @override
  State<CommunityShoutoutCarousel> createState() =>
      _CommunityShoutoutCarouselState();
}

class _CommunityShoutoutCarouselState
    extends State<CommunityShoutoutCarousel> {
  final _pageController = PageController(viewportFraction: 1.0);
  Timer? _autoAdvance;
  int _page = 0;
  int _pageCount = 0;

  List<ReviewsRecord>? _reviews;
  List<ExchangePostsRecord>? _posts;
  StreamSubscription<List<ReviewsRecord>>? _reviewsSub;
  StreamSubscription<List<ExchangePostsRecord>>? _postsSub;

  @override
  void initState() {
    super.initState();
    _reviewsSub = queryReviewsRecord(
      queryBuilder: (q) => q
          .where('business_ref', isEqualTo: widget.businessRef)
          .orderBy('timestamp', descending: true),
      limit: 6,
    ).listen((data) => setState(() => _reviews = data));
    _postsSub = queryExchangePostsRecord(
      queryBuilder: (q) => q.orderBy('timestamp', descending: true),
      limit: 6,
    ).listen((data) => setState(() => _posts = data));
  }

  void _startAutoAdvance() {
    _autoAdvance?.cancel();
    if (_pageCount <= 1) return;
    _autoAdvance = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pageController.hasClients) return;
      final next = (_page + 1) % _pageCount;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    _reviewsSub?.cancel();
    _postsSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _openExchange(BuildContext context) {
    context.pushNamed(
      TheExchangeWidget.routeName,
      queryParameters: {
        'businessRef': serializeParam(
          widget.businessRef,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    const gold = Color(0xFFD4AF37);

    if (_reviews == null || _posts == null) {
      return const SizedBox(
        height: 200.0,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Reviews about this business first, then Exchange posts interleaved
    // in - so an owner sees their own feedback before the wider feed.
    final shoutouts = <_Shoutout>[
      ..._reviews!.map(_Shoutout.review),
      ..._posts!.map(_Shoutout.exchangePost),
    ].where((s) => s.text != null || s.rating != null).toList();

    if (shoutouts.isEmpty) {
      return GestureDetector(
        onTap: () => _openExchange(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: Column(
            children: [
              const Text('✨', style: TextStyle(fontSize: 32.0)),
              const SizedBox(height: 8.0),
              Text(
                'Nothing here yet - tap to see what\'s happening on The Exchange.',
                textAlign: TextAlign.center,
                style: theme.bodyMedium.override(
                  font: GoogleFonts.playfairDisplay(),
                  color: theme.secondaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_pageCount != shoutouts.length) {
      _pageCount = shoutouts.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoAdvance());
    }

    return Column(
      children: [
        SizedBox(
          height: 190.0,
          child: PageView.builder(
            controller: _pageController,
            itemCount: shoutouts.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => _ShoutoutCard(
              shoutout: shoutouts[i],
              onTap: () => _openExchange(context),
            ),
          ),
        ),
        if (shoutouts.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(shoutouts.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  width: active ? 18.0 : 6.0,
                  height: 6.0,
                  decoration: BoxDecoration(
                    color: active ? gold : theme.alternate,
                    borderRadius: BorderRadius.circular(999.0),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _ShoutoutCard extends StatelessWidget {
  const _ShoutoutCard({required this.shoutout, required this.onTap});

  final _Shoutout shoutout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    const gold = Color(0xFFD4AF37);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(24.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  shoutout.isExchangePost ? '💬' : '❝',
                  style: const TextStyle(fontSize: 24.0),
                ),
                const SizedBox(width: 6.0),
                Text(
                  shoutout.isExchangePost ? 'On The Exchange' : 'A review',
                  style: theme.labelSmall.override(
                    font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                    color: theme.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (shoutout.rating != null)
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < shoutout.rating!.round();
                      return Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        color: gold,
                        size: 16.0,
                      );
                    }),
                  )
                else if (shoutout.likesCount != null &&
                    shoutout.likesCount! > 0)
                  Row(
                    children: [
                      Icon(Icons.favorite_rounded, color: gold, size: 14.0),
                      const SizedBox(width: 4.0),
                      Text(
                        '${shoutout.likesCount}',
                        style: theme.labelSmall.override(
                          font: GoogleFonts.plusJakartaSans(),
                          color: theme.secondaryText,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: Text(
                shoutout.text ?? 'Left a rating.',
                style: theme.bodyMedium.override(
                  font: GoogleFonts.playfairDisplay(fontStyle: FontStyle.italic),
                  color: theme.primaryText,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8.0),
            StreamBuilder<UsersRecord>(
              stream: shoutout.userRef != null
                  ? UsersRecord.getDocument(shoutout.userRef!)
                  : null,
              builder: (context, userSnapshot) {
                final name = userSnapshot.data?.displayName;
                return Row(
                  children: [
                    Text(
                      valueOrDefault<String>(name, 'A KIN member'),
                      style: theme.labelSmall.override(
                        font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                        color: theme.primaryText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(' · '),
                    Text(
                      dateTimeFormat('relative', shoutout.timestamp),
                      style: theme.labelSmall.override(
                        font: GoogleFonts.plusJakartaSans(),
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
