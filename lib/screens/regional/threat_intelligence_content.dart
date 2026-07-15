import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class ThreatIntelligenceContent extends StatelessWidget {
  const ThreatIntelligenceContent({super.key});

  static const _iocs = [
    [
      '185.220.101.44',
      'IP Address',
      'Mirai Botnet',
      'rizal-po-agent',
      '10:45:11'
    ],
    [
      '4b494...8c7f9',
      'File Hash (SHA256)',
      'Ransomware.WannaCry',
      'cavite-po-agent',
      '09:22:01'
    ],
    [
      'malicious-domain.xyz',
      'DNS Query',
      'Phishing',
      'laguna-po-agent',
      '08:15:30'
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
            title: 'Threat Intelligence',
            subtitle:
                'Identified Indicators of Compromise (IoCs) matched against live traffic.',
          ),
          const SizedBox(height: 20),
          DashCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.track_changes_outlined,
                        size: 16, color: AppColors.teal),
                    SizedBox(width: 8),
                    Text('Active IoC Detections',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 8),
                HScrollBox(
                  minWidth: 680,
                  child: SimpleTable(
                    headers: const [
                      'MATCHED INDICATOR',
                      'TYPE',
                      'THREAT ACTOR / CAMPAIGN',
                      'AFFECTED AGENT',
                      'LAST SEEN'
                    ],
                    flex: const [3, 2, 3, 3, 2],
                    rows: [
                      for (final i in _iocs)
                        [
                          CellText(i[0], color: AppColors.red),
                          CellText(i[1], color: AppColors.textSecondary),
                          CellText(i[2], weight: FontWeight.w600),
                          CellText(i[3], color: AppColors.textSecondary),
                          CellText(i[4], color: AppColors.textSecondary),
                        ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
