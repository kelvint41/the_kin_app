import 'package:flutter/material.dart';

/// Confirms a client action just logged toward the signed-in user's Kindex
/// Score - today that's [KinServices.shareApp]'s three call sites (Share
/// KIN / Promote Your Business), the one place in the app that wrote a
/// `user_engagement_events` doc with zero feedback: `Share.share()` fired,
/// the doc landed, and nothing on screen told the person it counted for
/// anything. Kept to a plain SnackBar with a small gold accent rather than
/// a colored background or animation - the KIN Quest rare-find snackbar
/// earns a louder moment (an actual surprise), this is a routine "yes, that
/// counted" confirmation and shouldn't compete with it.
///
/// Not on [KinServices] itself - that class is deliberately UI-free (its
/// static methods take no BuildContext), so this is called by each screen
/// right after awaiting the share, the same way those screens already
/// handle their own snackbars for other actions.
void showKindexEngagementNudge(
  BuildContext context, {
  String message = 'Shared! This counts toward your Kindex Score.',
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          // Same gold used throughout the Kindex UI (KindexGauge's ring,
          // KindexTierBadge) - the one visual cue tying this confirmation
          // back to the same score a Kindex history screen would show.
          Icon(Icons.volunteer_activism_rounded,
              color: const Color(0xFFD4AF37), size: 20.0),
          SizedBox(width: 10.0),
          Expanded(child: Text(message)),
        ],
      ),
      duration: const Duration(seconds: 4),
    ),
  );
}
