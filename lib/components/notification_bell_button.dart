import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';

/// The map page's bell icon, matching the hamburger button right next to
/// it (48x48, translucent white circle) - the map is every signed-in
/// user's initial route (nav.dart, initialLocation '/'), so this single
/// placement is the one spot that reaches both owners and customers.
///
/// No existing badge/unread-count component in this codebase to reuse -
/// this is new, but small and self-contained enough to drop onto other
/// pages' chrome later if wanted.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final userRef = currentUserReference;

    return Container(
      width: 48.0,
      height: 48.0,
      decoration: BoxDecoration(
        color: Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(9999.0),
        shape: BoxShape.rectangle,
        border: Border.all(color: theme.alternate, width: 1.0),
      ),
      alignment: AlignmentDirectional(0.0, 0.0),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          FlutterFlowIconButton(
            borderRadius: 8.0,
            buttonSize: 40.0,
            fillColor: Colors.transparent,
            icon: Icon(
              Icons.notifications_none_rounded,
              color: theme.primaryText,
              size: 24.0,
            ),
            onPressed: () =>
                context.pushNamed(NotificationsWidget.routeName),
          ),
          if (userRef != null)
            StreamBuilder<int>(
              stream: _unreadCountStream(userRef),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (count <= 0) return const SizedBox.shrink();
                return Positioned(
                  top: 4.0,
                  right: 4.0,
                  child: IgnorePointer(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 5.0),
                      constraints: BoxConstraints(minWidth: 16.0),
                      height: 16.0,
                      decoration: BoxDecoration(
                        color: theme.error,
                        borderRadius: BorderRadius.circular(999.0),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.0,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Stream<int> _unreadCountStream(DocumentReference userRef) =>
      queryNotificationsRecord(
        queryBuilder: (q) => q
            .where('user_ref', isEqualTo: userRef)
            .where('is_read', isEqualTo: false),
      ).map((docs) => docs.length);
}
