import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/backend.dart';
import 'job_messages_page_model.dart';

export 'job_messages_page_model.dart';

class JobMessagesPage extends StatefulWidget {
  final DocumentReference applicationRef;
  final String otherUserName;

  const JobMessagesPage({
    super.key,
    required this.applicationRef,
    required this.otherUserName,
  });

  @override
  State<JobMessagesPage> createState() => _JobMessagesPageState();
}

class _JobMessagesPageState extends State<JobMessagesPage> {
  late JobMessagesPageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => JobMessagesPageModel());
  }

  @override
  void dispose() {
    _model.dispose();
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
            widget.otherUserName,
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
            // Messages list
            Expanded(
              child: StreamBuilder<List<JobApplicationMessagesRecord>>(
                stream: _model.getMessages(widget.applicationRef),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child:
                          CircularProgressIndicator(color: theme.primary),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet',
                        style: theme.bodyMedium,
                      ),
                    );
                  }

                  final messages = snapshot.data!;
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isOwn = message.senderRef == null; // Placeholder
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
                            message.messageText,
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

            // Message input
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
                      controller: _model.messageController,
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
                      if (_model.messageController.text.isNotEmpty) {
                        await _model.sendMessage(
                          applicationRef: widget.applicationRef,
                          message: _model.messageController.text,
                        );
                        _model.messageController.clear();
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
