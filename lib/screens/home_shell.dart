import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/top_bar.dart';
import '../widgets/sidebar.dart';
import 'login_screen.dart';
import 'regional/overview_content.dart';
import 'regional/incident_tracker_content.dart';
import 'regional/endpoint_security_content.dart';
import 'regional/threat_intelligence_content.dart';
import 'regional/vulnerabilities_content.dart';
import 'regional/regulatory_compliance_content.dart';
import 'regional/file_integrity_content.dart';
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

  // Starts as a loading placeholder so the account's email never flashes
  // on screen before the Firestore displayName lookup resolves.
  String _userLabel = '...';

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  /// Looks up the signed-in user's UID in the `users` collection
  /// (document ID = UID, field = `displayName`) and swaps the top bar
  /// label to that name once it arrives. If no matching document or field
  /// exists, the email fallback is used instead of leaving the loading
  /// placeholder displayed indefinitely.
  Future<void> _loadDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final emailFallback = user?.email ?? 'User';

    if (uid == null) {
      if (mounted) setState(() => _userLabel = emailFallback);
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final name = doc.data()?['displayName'] as String?;
      if (mounted) {
        setState(() {
          _userLabel =
              (name != null && name.trim().isNotEmpty) ? name : emailFallback;
        });
      }
    } catch (_) {
      // Firestore lookup failed (offline, missing doc, etc.) — fall back
      // to the email instead of leaving the loading placeholder stuck.
      if (mounted) setState(() => _userLabel = emailFallback);
    }
  }

  Widget _regionalContent() {
    switch (_module) {
      case RegionalModule.overview:
        return const OverviewContent();
      case RegionalModule.incidentTracker:
        return const IncidentTrackerContent();
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
        userLabel: _userLabel,
        onModeChanged: (m) => setState(() => _mode = m),
        onLogout: () async {
          await FirebaseAuth.instance.signOut();
          if (!context.mounted) return;
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
                      child:
                          Sidebar(selected: _module, onSelect: _selectModule),
                    ),
                    const VerticalDivider(
                        width: 1, color: AppColors.sidebarBorder),
                    Expanded(child: _regionalContent()),
                  ],
                )
              : _regionalContent())
          : const ProvincialView(),
    );
  }
}
