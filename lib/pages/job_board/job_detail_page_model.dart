import 'package:flutter/material.dart';
import '/backend/backend.dart';
import '/services/job_board_service.dart';

class JobDetailPageModel extends ChangeNotifier {
  JobDetailPageModel();

  Future<void> saveJob(DocumentReference jobRef) async {
    try {
      await JobBoardService.saveJobForLater(jobRef: jobRef);
    } catch (_) {
      // Handle error
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
