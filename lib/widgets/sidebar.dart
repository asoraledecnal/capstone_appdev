import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// Idinagdag ang 'incidentTracker' para sa IT 332 CRUD integration
enum RegionalModule {
  overview,
  endpointSecurity,
  threatIntelligence,
  vulnerabilities,
  regulatoryCompliance,
  fileIntegrity,
  incidentTracker, 
}

class Sidebar extends StatelessWidget {
  final RegionalModule selected;
  final ValueChanged<RegionalModule> onSelect;

  const Sidebar({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.panelDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: const _NoScrollbarBehavior(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 20, 14, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SENTINEL IV-A MANAGER',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.dns_outlined,
                            color: AppColors.teal, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Batangas Hub',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel('DASHBOARDS'),
                    const SizedBox(height: 6),
                    _NavItem(
                      icon: Icons.dashboard_customize_outlined,
                      label: 'Overview',
                      selected: selected == RegionalModule.overview,
                      onTap: () => onSelect(RegionalModule.overview),
                    ),
                    const SizedBox(height: 20),
                    const _SectionLabel('MODULES'),
                    const SizedBox(height: 6),
                    _NavItem(
                      icon: Icons.verified_user_outlined,
                      label: 'Endpoint Security',
                      selected: selected == RegionalModule.endpointSecurity,
                      onTap: () => onSelect(RegionalModule.endpointSecurity),
                    ),
                    _NavItem(
                      icon: Icons.track_changes_outlined,
                      label: 'Threat Intelligence',
                      selected: selected == RegionalModule.threatIntelligence,
                      onTap: () => onSelect(RegionalModule.threatIntelligence),
                    ),
                    _NavItem(
                      icon: Icons.bug_report_outlined,
                      label: 'Vulnerabilities',
                      selected: selected == RegionalModule.vulnerabilities,
                      onTap: () => onSelect(RegionalModule.vulnerabilities),
                    ),
                    _NavItem(
                      icon: Icons.fact_check_outlined,
                      label: 'Regulatory Compliance',
                      selected: selected == RegionalModule.regulatoryCompliance,
                      onTap: () =>
                          onSelect(RegionalModule.regulatoryCompliance),
                    ),
                    _NavItem(
                      icon: Icons.inventory_2_outlined,
                      label: 'File Integrity',
                      selected: selected == RegionalModule.fileIntegrity,
                      onTap: () => onSelect(RegionalModule.fileIntegrity),
                    ),
                    const SizedBox(height: 20),
                    
                    // --- IT 332 CRUD MODULE INTEGRATION ---
                    const _SectionLabel('INCIDENT MANAGEMENT'),
                    const SizedBox(height: 6),
                    _NavItem(
                      icon: Icons.assignment_late_outlined,
                      label: 'Incident Tracker',
                      selected: selected == RegionalModule.incidentTracker,
                      onTap: () => onSelect(RegionalModule.incidentTracker),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(color: AppColors.sidebarBorder, height: 1),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              'LEADING INNOVATIONS,\nTRANSFORMING LIVES,\nBUILDING THE NATION',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoScrollbarBehavior extends ScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.teal.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: selected
                ? Border.all(color: AppColors.teal.withValues(alpha: 0.4))
                : null,
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? AppColors.teal : AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? AppColors.teal : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}