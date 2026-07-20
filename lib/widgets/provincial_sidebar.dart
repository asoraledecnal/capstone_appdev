import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ProvincialModule {
  localDashboard,
  endpointHealth,
  accessIdentities,
  incidentTickets,
  reports,
}

class ProvincialSidebar extends StatelessWidget {
  final ProvincialModule selected;
  final ValueChanged<ProvincialModule> onSelect;
  final String currentSpoke;
  final ValueChanged<String>? onSpokeChanged;
  final VoidCallback? onSwitchMode;

  const ProvincialSidebar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.currentSpoke,
    this.onSpokeChanged,
    this.onSwitchMode,
  });

  /// Public spoke-name map — shared by the reports generator and other screens.
  static const Map<String, String> tenantNames = {
    'SPOKE-01': 'Cavite Provincial Office',
    'SPOKE-02': 'Laguna Provincial Office',
    'SPOKE-03': 'Batangas Regional Hub',
    'SPOKE-04': 'Rizal Provincial Office',
    'SPOKE-05': 'Quezon Provincial Office',
  };
  // Keep a private alias so existing internal references compile without change.
  static const Map<String, String> _tenantNames = tenantNames;

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
                      'PROVINCIAL HUB',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (onSpokeChanged != null)
                      PopupMenuButton<String>(
                        color: AppColors.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppColors.cardBorder),
                        ),
                        offset: const Offset(0, 44),
                        onSelected: onSpokeChanged,
                        itemBuilder: (context) => [
                          for (final entry in _tenantNames.entries)
                            PopupMenuItem(
                              value: entry.key,
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  color: entry.key == currentSpoke
                                      ? AppColors.teal
                                      : AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.business,
                                  color: AppColors.teal, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _tenantNames[currentSpoke] ?? currentSpoke,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down,
                                  color: AppColors.textSecondary, size: 16),
                            ],
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          const Icon(Icons.business,
                              color: AppColors.teal, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _tenantNames[currentSpoke] ?? currentSpoke,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    _NavItem(
                      icon: Icons.dashboard_outlined,
                      label: 'Local Dashboard',
                      selected: selected == ProvincialModule.localDashboard,
                      onTap: () => onSelect(ProvincialModule.localDashboard),
                    ),
                    _NavItem(
                      icon: Icons.computer_outlined,
                      label: 'Endpoint Health',
                      selected: selected == ProvincialModule.endpointHealth,
                      onTap: () => onSelect(ProvincialModule.endpointHealth),
                    ),
                    _NavItem(
                      icon: Icons.badge_outlined,
                      label: 'Access & Identities',
                      selected: selected == ProvincialModule.accessIdentities,
                      onTap: () => onSelect(ProvincialModule.accessIdentities),
                    ),
                    _NavItem(
                      icon: Icons.confirmation_number_outlined,
                      label: 'Incident Tickets',
                      selected: selected == ProvincialModule.incidentTickets,
                      onTap: () => onSelect(ProvincialModule.incidentTickets),
                    ),
                    _NavItem(
                      icon: Icons.insert_chart_outlined,
                      label: 'Provincial Reports',
                      selected: selected == ProvincialModule.reports,
                      onTap: () => onSelect(ProvincialModule.reports),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.sidebarBorder),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: AppColors.teal, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Provincial Sync',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      Text('Online',
                          style: TextStyle(
                              color: AppColors.teal, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onSwitchMode != null) ...[
            const Divider(height: 1, color: AppColors.sidebarBorder),
            Padding(
              padding: const EdgeInsets.all(14),
              child: _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Switch to Regional',
                selected: false,
                onTap: onSwitchMode!,
              ),
            ),
          ],
        ],
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

class _NoScrollbarBehavior extends ScrollBehavior {
  const _NoScrollbarBehavior();
  @override
  Widget buildScrollbar(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}
