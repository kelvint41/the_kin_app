import 'dart:async';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notifications_model.dart';
export 'notifications_model.dart';

/// The in-app notification inbox - one row per `notifications` doc
/// (see NotificationsRecord / firebase/custom_cloud_functions/notifications.js).
/// Every row is server-written (claim approved, KIN Quest check-in
/// confirmed, mystery reward unlocked); the only thing the client ever
/// writes back is `is_read`, on open.
class NotificationsWidget extends StatefulWidget {
  const NotificationsWidget({super.key});

  static String routeName = 'Notifications';
  static String routePath = '/notifications';

  @override
  State<NotificationsWidget> createState() => _NotificationsWidgetState();
}

class _NotificationsWidgetState extends State<NotificationsWidget> {
  late NotificationsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NotificationsModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _open(NotificationsRecord notification) async {
    if (!notification.isRead) {
      // Best-effort - firestore.rules only allows this exact field, so a
      // failure here is a network blip, not a permission problem worth
      // surfacing to the user over.
      unawaited(notification.reference.update({'is_read': true}));
    }
    if (notification.routeName.isNotEmpty) {
      await context.pushNamed(notification.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final userRef = currentUserReference;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        automaticallyImplyLeading: false,
        leading: FlutterFlowIconButton(
          borderRadius: 8.0,
          buttonSize: 40.0,
          fillColor: Colors.transparent,
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: theme.primaryText, size: 20.0),
          onPressed: () => context.safePop(),
        ),
        title: Text(
          'Notifications',
          style: theme.headlineMedium.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            color: theme.primaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0.0,
      ),
      body: SafeArea(
        top: true,
        child: userRef == null
            ? const SizedBox.shrink()
            : StreamBuilder<List<NotificationsRecord>>(
                stream: queryNotificationsRecord(
                  queryBuilder: (q) => q
                      .where('user_ref', isEqualTo: userRef)
                      .orderBy('created_at', descending: true),
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(theme.primary),
                      ),
                    );
                  }
                  final notifications = snapshot.data!;
                  if (notifications.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'Nothing yet. Check-ins, reward unlocks, and claim '
                          'approvals will show up here.',
                          textAlign: TextAlign.center,
                          style: theme.bodyMedium
                              .override(color: theme.secondaryText),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.all(16.0),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8.0),
                    itemBuilder: (context, index) =>
                        _row(theme, notifications[index]),
                  );
                },
              ),
      ),
    );
  }

  Widget _row(FlutterFlowTheme theme, NotificationsRecord notification) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.0),
      onTap: () => _open(notification),
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: notification.isRead
              ? theme.secondaryBackground
              : theme.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: theme.alternate, width: 1.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!notification.isRead)
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 6.0, 10.0, 0.0),
                child: Container(
                  width: 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    color: theme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: theme.bodyMedium.override(
                      font: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold),
                      color: theme.primaryText,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    notification.body,
                    style: theme.bodySmall.override(
                      color: theme.secondaryText,
                      lineHeight: 1.4,
                    ),
                  ),
                  SizedBox(height: 6.0),
                  Text(
                    _relativeTime(notification.createdAt),
                    style: theme.labelSmall.override(
                      color: theme.secondaryText,
                      letterSpacing: 0.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
