import 'package:flutter/material.dart';
import '/backend/backend.dart';
import '/services/job_board_service.dart';

class JobBoardListingPageModel extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  late TabController tabController;

  JobBoardListingPageModel();

  Future<List<JobPostingsRecord>> getAllJobs() async {
    try {
      final result = await JobBoardService.getAllActiveJobs();
      if (result.isSuccess) {
        return result.data ?? [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<JobPostingsRecord>> getRecentJobs() async {
    try {
      final jobs = await getAllJobs();
      jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return jobs.take(20).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<JobPostingsRecord>> getMostAppliedJobs() async {
    try {
      final jobs = await getAllJobs();
      jobs.sort((a, b) => b.applicationsCount.compareTo(a.applicationsCount));
      return jobs.take(20).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    tabController.dispose();
    super.dispose();
  }
}
