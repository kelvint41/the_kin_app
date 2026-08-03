import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/users_record.dart';
import '/services/community_events_service.dart';

class EventCommentsPage extends StatefulWidget {
  final String eventId;

  const EventCommentsPage({super.key, required this.eventId});

  @override
  State<EventCommentsPage> createState() => _EventCommentsPageState();
}

class _EventCommentsPageState extends State<EventCommentsPage> {
  final commentController = TextEditingController();

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.primary,
          automaticallyImplyLeading: true,
          title: Text(
            'Discussion',
            style: theme.headlineMedium.override(
                font: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                ),
                color: theme.info),
          ),
          centerTitle: false,
          elevation: 0.0,
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: CommunityEventsService.getEventComments(widget.eventId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: theme.primary),
                    );
                  }
                  final comments = snapshot.data ?? [];
                  if (comments.isEmpty) {
                    return Center(
                      child: Text('No comments yet', style: theme.bodyMedium),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.secondaryBackground,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: theme.alternate),
                          ),
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _AuthorName(
                                  authorId: comment['authorId'] as String?),
                              const SizedBox(height: 4.0),
                              Text(
                                comment['text'] as String? ?? '',
                                style: theme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // See JobMessagesPage for why SafeArea sits inside the decorated
            // container - keeps the send button clear of Android's nav bar.
            Container(
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                border: Border(top: BorderSide(color: theme.alternate)),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    16, 16, 16, 16 + MediaQuery.viewPaddingOf(context).bottom),
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: theme.labelSmall,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: theme.alternate),
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: theme.primary, width: 2.0),
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                          ),
                          style: theme.bodySmall,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      IconButton(
                        onPressed: () async {
                          if (commentController.text.isNotEmpty) {
                            await CommunityEventsService.addComment(
                              eventId: widget.eventId,
                              userId: currentUserUid,
                              text: commentController.text,
                            );
                            commentController.clear();
                          }
                        },
                        icon: const Icon(Icons.send),
                        color: theme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorName extends StatelessWidget {
  final String? authorId;

  const _AuthorName({required this.authorId});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    if (authorId == null) {
      return Text('Member',
          style: theme.labelSmall.override(fontWeight: FontWeight.w600));
    }
    return FutureBuilder<UsersRecord>(
      future: UsersRecord.getDocumentOnce(UsersRecord.collection.doc(authorId)),
      builder: (context, snapshot) {
        final name = snapshot.data?.displayName;
        return Text(
          (name == null || name.isEmpty) ? 'Member' : name,
          style: theme.labelSmall.override(fontWeight: FontWeight.w600),
        );
      },
    );
  }
}
