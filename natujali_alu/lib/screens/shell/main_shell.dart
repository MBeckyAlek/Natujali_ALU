import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../report_form/report_form_screen.dart';
import '../reports/campus_reports_screen.dart';
import 'app_bottom_nav.dart';

/// The signed-in student's app: three tabs plus the centre "Report" button.
/// IndexedStack keeps each tab alive so scroll position and search text
/// survive switching tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: const [HomeScreen(), CampusReportsScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _tabIndex,
        onTabSelected: (index) => setState(() => _tabIndex = index),
        onReportPressed: () => ReportFormScreen.open(context),
      ),
    );
  }
}
