import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class EndpointSecurityContent extends StatelessWidget {
  const EndpointSecurityContent({super.key});

  static const _agents = [
    [
      'batangas-hub',
      '000',
      '10.0.0.1',
      'Ubuntu 22.04.3 LTS',
      'Wazuh v4.8.0',
      true
    ],
    [
      'cavite-po-agent',
      '001',
      '10.0.1.5',
      'Windows Server 2022',
      'Wazuh v4.8.0',
      true
    ],
    [
      'laguna-po-agent',
      '002',
      '10.0.2.10',
      'Ubuntu 20.04 LTS',
      'Wazuh v4.7.2',
      true
    ],
    [
      'rizal-po-agent',
      '003',
      '10.0.3.15',
      'Windows 10 Pro',
      'Wazuh v4.8.0',
      false
    ],
    [
      'quezon-po-agent',
      '004',
      '10.0.4.22',
      'CentOS Linux 8',
      'Wazuh v4.8.0',
      true
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Endpoint Security',
            subtitle:
                'Manage and monitor all registered agents across Region 4A.',
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              // A 6-column table (name, id, ip, os, version, status) needs
              // real width to stay readable — below this breakpoint a
              // horizontal-scroll table only ever shows a partial slice of
              // columns on a phone. Cards show every field for an agent at
              // once, just by scrolling down like the rest of the page.
              final narrow = constraints.maxWidth < 720;
              if (narrow) {
                return _agentCardList();
              }
              return DashCard(
                child: HScrollBox(
                  minWidth: 680,
                  child: SimpleTable(
                    headers: const [
                      'AGENT NAME',
                      'ID',
                      'IP ADDRESS',
                      'OS/VERSION',
                      'VERSION',
                      'STATUS'
                    ],
                    flex: const [3, 1, 2, 3, 2, 2],
                    rows: [
                      for (final a in _agents)
                        [
                          CellText(a[0] as String, weight: FontWeight.w600),
                          CellText(a[1] as String,
                              color: AppColors.textSecondary),
                          CellText(a[2] as String, color: AppColors.teal),
                          CellText(a[3] as String,
                              color: AppColors.textSecondary),
                          CellText(a[4] as String,
                              color: AppColors.textSecondary),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: StatusBadge(
                              label: (a[5] as bool) ? 'ACTIVE' : 'INACTIVE',
                              color: (a[5] as bool)
                                  ? AppColors.teal
                                  : AppColors.red,
                            ),
                          ),
                        ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Mobile-width replacement for the agent table: one card per agent with
  /// every field (ID, IP, OS/version, agent version, status) laid out and
  /// fully visible, no sideways scrolling required.
  Widget _agentCardList() {
    return Column(
      children: [
        for (final a in _agents) _agentCard(a),
      ],
    );
  }

  Widget _agentCard(List<Object> a) {
    final active = a[5] as bool;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? AppColors.cardBorder
              : AppColors.red.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.dns_outlined,
                  size: 16, color: active ? AppColors.teal : AppColors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  a[0] as String,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: active ? 'ACTIVE' : 'INACTIVE',
                color: active ? AppColors.teal : AppColors.red,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _fieldRow('ID', a[1] as String),
          _fieldRow('IP ADDRESS', a[2] as String, valueColor: AppColors.teal),
          _fieldRow('OS / VERSION', a[3] as String),
          _fieldRow('AGENT VERSION', a[4] as String),
        ],
      ),
    );
  }

  Widget _fieldRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
