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

  IconData _typeIcon(String type) {
    switch (type) {
      case 'IP Address':
        return Icons.public;
      case 'DNS Query':
        return Icons.dns_outlined;
      default:
        return Icons.fingerprint;
    }
  }

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
          LayoutBuilder(
            builder: (context, constraints) {
              // A 5-column table needs real width to stay readable. Below
              // this breakpoint a horizontal-scroll table only ever shows a
              // partial, mid-scroll slice of columns on a phone. Cards avoid
              // sideways scrolling entirely: every IoC's full info is
              // visible by just scrolling down like the rest of the page.
              final narrow = constraints.maxWidth < 760;
              return DashCard(
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
                    if (narrow)
                      _iocCardList()
                    else
                      HScrollBox(
                        minWidth: 980,
                        child: SimpleTable(
                          headers: const [
                            'MATCHED INDICATOR',
                            'TYPE',
                            'THREAT ACTOR / CAMPAIGN',
                            'AFFECTED AGENT',
                            'LAST SEEN'
                          ],
                          flex: const [3, 2, 3, 3, 2],
                          align: const [
                            Alignment.centerLeft,
                            Alignment.center,
                            Alignment.centerLeft,
                            Alignment.center,
                            Alignment.center,
                          ],
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
              );
            },
          ),
        ],
      ),
    );
  }

  /// Mobile-width replacement for the IoC table: one card per indicator so
  /// nothing needs a sideways scroll to be seen in full.
  Widget _iocCardList() {
    return Column(
      children: [
        for (final i in _iocs)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_typeIcon(i[1]), size: 15, color: AppColors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        i[0],
                        style: const TextStyle(
                          color: AppColors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(label: i[1], color: AppColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  i[2],
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _metaChip(Icons.dns_outlined, i[3], AppColors.teal),
                    _metaChip(Icons.access_time, i[4], AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _metaChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11.5)),
      ],
    );
  }
}
