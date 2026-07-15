import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class VulnerabilitiesContent extends StatelessWidget {
  const VulnerabilitiesContent({super.key});

  static const _cves = [
    ['CVE-2023-38408', 'CRITICAL', '9.8', 'openssh-server (9.3p1)', 'rizal-po-agent'],
    ['CVE-2023-4863', 'CRITICAL', '9', 'libwebp (1.0.3)', 'batangas-hub'],
    ['CVE-2022-22965', 'HIGH', '8.8', 'spring-framework (5.3.16)', 'cavite-po-agent'],
    ['CVE-2021-3156', 'HIGH', '7.5', 'sudo (1.8.31)', 'laguna-po-agent'],
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Vulnerability Detector',
            subtitle: 'Discovered CVEs mapped from the OS and application layer.',
            trailing: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _statPill('12', 'CRITICAL', AppColors.red),
                _statPill('34', 'HIGH', AppColors.orange),
              ],
            ),
          ),
          const SizedBox(height: 20),
          DashCard(
            child: HScrollBox(
              minWidth: 640,
              child: SimpleTable(
                headers: const ['CVE ID', 'SEVERITY', 'CVSS SCORE', 'AFFECTED PACKAGE', 'AGENT'],
                flex: const [2, 2, 2, 3, 2],
                rows: [
                  for (final c in _cves)
                    [
                      CellText(c[0], color: AppColors.teal, weight: FontWeight.w600),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: StatusBadge(
                          label: c[1],
                          color: c[1] == 'CRITICAL' ? AppColors.red : AppColors.orange,
                        ),
                      ),
                      CellText(c[2]),
                      CellText(c[3], color: AppColors.textSecondary),
                      CellText(c[4], color: AppColors.textSecondary),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
