import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class EndpointSecurityContent extends StatelessWidget {
  const EndpointSecurityContent({super.key});

  static const _agents = [
    ['batangas-hub', '000', '10.0.0.1', 'Ubuntu 22.04.3 LTS', 'Wazuh v4.8.0', true],
    ['cavite-po-agent', '001', '10.0.1.5', 'Windows Server 2022', 'Wazuh v4.8.0', true],
    ['laguna-po-agent', '002', '10.0.2.10', 'Ubuntu 20.04 LTS', 'Wazuh v4.7.2', true],
    ['rizal-po-agent', '003', '10.0.3.15', 'Windows 10 Pro', 'Wazuh v4.8.0', false],
    ['quezon-po-agent', '004', '10.0.4.22', 'CentOS Linux 8', 'Wazuh v4.8.0', true],
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
            subtitle: 'Manage and monitor all registered agents across Region 4A.',
          ),
          const SizedBox(height: 20),
          DashCard(
            child: HScrollBox(
              minWidth: 680,
              child: SimpleTable(
                headers: const ['AGENT NAME', 'ID', 'IP ADDRESS', 'OS/VERSION', 'VERSION', 'STATUS'],
                flex: const [3, 1, 2, 3, 2, 2],
                rows: [
                  for (final a in _agents)
                    [
                      CellText(a[0] as String, weight: FontWeight.w600),
                      CellText(a[1] as String, color: AppColors.textSecondary),
                      CellText(a[2] as String, color: AppColors.teal),
                      CellText(a[3] as String, color: AppColors.textSecondary),
                      CellText(a[4] as String, color: AppColors.textSecondary),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: StatusBadge(
                          label: (a[5] as bool) ? 'ACTIVE' : 'INACTIVE',
                          color: (a[5] as bool) ? AppColors.teal : AppColors.red,
                        ),
                      ),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
