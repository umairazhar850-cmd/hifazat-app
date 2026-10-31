import 'package:flutter/material.dart';
import '../../testing/screens/result_screen.dart';
import '../../../models/test_result_model.dart';

/// Shows a past test result. Deliberately reuses ResultScreen's layout since
/// a historical result and a fresh result should look identical — only the
/// entry point differs.
class HistoryDetailScreen extends StatelessWidget {
  final TestResultModel result;
  const HistoryDetailScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return ResultScreen(result: result);
  }
}
