import 'package:flutter/material.dart';
import '/backend/backend.dart';
import '/services/job_board_service.dart';

class JobApplyPageModel extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController coverLetterController = TextEditingController();

  JobApplyPageModel();

  Future<bool> submitApplication({
    required DocumentReference jobRef,
    required String name,
    required String email,
    required String phone,
    required String coverLetter,
  }) async {
    try {
      await JobBoardService.applyToJob(
        jobRef: jobRef,
        applicantName: name,
        applicantEmail: email,
        applicantPhone: phone,
        coverLetter: coverLetter,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    coverLetterController.dispose();
    super.dispose();
  }
}
