import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/backend.dart';
import '/services/community_events_service.dart';

class EventCommentsPage extends StatefulWidget {
  final DocumentReference eventRef;

  const EventCommentsPage({super.key, required this.eventRef});

  @override
  State<EventCommentsPage> createState() => _EventCommentsPageState();
}

class _EventCommentsPageState extends State<EventCommentsPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController commentController = TextEditingController();

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
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.primary,
          automaticallyImplyLeading: true,
          title: Text(
            'Discussion',
            style: theme.headlineMedium.override(
              font: GoogleFonts.plusJakartaSans(
                color: theme.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          centerTitle: false,
          elevation: 0.0,
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<CommunityEventCommentsRecord>>(
                stream: CommunityEventCommentsRecord.collection
                    .where('event_ref', isEqualTo: widget.eventRef)
                    .orderBy('created_at', descending: true)
                    .snapshots()
                    .map((snapshot) => snapshot.docs
                        .map((doc) =>
                            CommunityEventCommentsRecord.fromSnapshot(doc))
                        .toList()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: theme.primary),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text('No comments yet',
                          style: theme.bodyMedium),
                    );
                  }

                  final comments = snapshot.data!;
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
                              Text(
                                comment.authorName,
                                style: theme.labelSmall.override(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                comment.commentText,
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
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                border: Border(
                  top: BorderSide(color: theme.alternate),
                ),
              ),
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
                          eventRef: widget.eventRef,
                          comment: commentController.text,
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
          ],
        ),
      ),
    );
  }
}
