import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/services/job_board_service.dart';

class JobMessagesPage extends StatefulWidget {
  final String applicationId;
  final String otherUserId;
  final String otherUserName;

  const JobMessagesPage({
    super.key,
    required this.applicationId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<JobMessagesPage> createState() => _JobMessagesPageState();
}

class _JobMessagesPageState extends State<JobMessagesPage> {
  final messageController = TextEditingController();

  @override
  void dispose() {
    messageController.dispose();
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
            widget.otherUserName,
            style: theme.headlineMedium.override(
              font: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
              ),
              color: theme.info
            ),
          ),
          centerTitle: false,
          elevation: 0.0,
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: JobBoardService.getApplicationMessages(
                    widget.applicationId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: theme.primary),
                    );
                  }
                  final messages = snapshot.data ?? [];
                  if (messages.isEmpty) {
                    return Center(
                      child: Text('No messages yet', style: theme.bodyMedium),
                    );
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final fromRef = message['fromRef'];
                      final isOwn = fromRef != null &&
                          fromRef.id == currentUserUid;
                      return Align(
                        alignment: isOwn
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isOwn
                                ? theme.primary
                                : theme.secondaryBackground,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            message['messageText'] as String? ?? '',
                            style: theme.bodyMedium.override(
                              color: isOwn ? theme.info : theme.primaryText,
                            ),
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
                border: Border(top: BorderSide(color: theme.alternate)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
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
                      style: theme.bodyMedium,
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  IconButton(
                    onPressed: () async {
                      if (messageController.text.isNotEmpty) {
                        await JobBoardService.sendMessage(
                          applicationId: widget.applicationId,
                          fromUserId: currentUserUid,
                          toUserId: widget.otherUserId,
                          messageText: messageController.text,
                        );
                        messageController.clear();
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
