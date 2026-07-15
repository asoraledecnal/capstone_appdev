import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/top_bar.dart';
import '../widgets/sidebar.dart';
import 'login_screen.dart';
import 'regional/overview_content.dart';
import 'regional/endpoint_security_content.dart';
import 'regional/threat_intelligence_content.dart';
import 'regional/vulnerabilities_content.dart';
import 'regional/regulatory_compliance_content.dart';
import 'regional/file_integrity_content.dart';
// TODO: Create this file next for the IT 332 CRUD requirement
import 'regional/incident_tracker_content.dart'; 
import 'provincial/provincial_view.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  ViewMode _mode = ViewMode.regional;
  RegionalModule _module = RegionalModule.overview;

  Widget _regionalContent() {
    switch (_module) {
      case RegionalModule.overview:
        return const OverviewContent();
      case RegionalModule.endpointSecurity:
        return const EndpointSecurityContent();
      case RegionalModule.threatIntelligence:
        return const ThreatIntelligenceContent();
      case RegionalModule.vulnerabilities:
        return const VulnerabilitiesContent();
      case RegionalModule.regulatoryCompliance:
        return const RegulatoryComplianceContent();
      case RegionalModule.fileIntegrity:
        return const FileIntegrityContent();
      case RegionalModule.incidentTracker:
        // Dinagdag ang route papunta sa bagong CRUD screen
        return const IncidentTrackerContent();
    }
  }

  void _selectModule(RegionalModule m) {
    setState(() => _module = m);
    // On phones the sidebar lives in a Drawer, so close it after picking
    // a module instead of leaving it open over the content.
    if (!context.isWide) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;
    final showDrawer = !wide && _mode == ViewMode.regional;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: showDrawer
          ? Drawer(
              backgroundColor: AppColors.panelDark,
              width: 260,
              child: SafeArea(
                child: Sidebar(selected: _module, onSelect: _selectModule),
              ),
            )
          : null,
      appBar: TopBar(
        mode: _mode,
        showMenuButton: showDrawer,
        onModeChanged: (m) => setState(() => _mode = m),
        onLogout: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
      ),
      body: _mode == ViewMode.regional
          ? (wide
              ? Row(
                  children: [
                    SizedBox(
                      width: 240,
                      child: Sidebar(selected: _module, onSelect: _selectModule),
                    ),
                    const VerticalDivider(width: 1, color: AppColors.sidebarBorder),
                    Expanded(child: _regionalContent()),
                  ],
                )
              : _regionalContent())
          : const ProvincialView(),
    );
  }
}