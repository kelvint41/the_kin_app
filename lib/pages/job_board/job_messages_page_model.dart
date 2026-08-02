import 'package:flutter/material.dart';
import '/backend/backend.dart';
import '/services/job_board_service.dart';

class JobMessagesPageModel extends ChangeNotifier {
  final TextEditingController messageController = TextEditingController();

  JobMessagesPageModel();

  Stream<List<JobApplicationMessagesRecord>> getMessages(
    DocumentReference applicationRef,
  ) {
    return JobApplicationMessagesRecord.collection
        .where('application_ref', isEqualTo: applicationRef)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobApplicationMessagesRecord.fromSnapshot(doc))
            .toList());
  }

  Future<void> sendMessage({
    required DocumentReference applicationRef,
    required String message,
  }) async {
    try {
      await JobBoardService.sendApplicationMessage(
        applicationRef: applicationRef,
        message: message,
      );
    } catch (_) {
      // Handle error
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}
