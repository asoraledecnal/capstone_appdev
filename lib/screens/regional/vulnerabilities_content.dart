import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class VulnerabilitiesContent extends StatelessWidget {
  const VulnerabilitiesContent({super.key});

  static const _cves = [
    [
      'CVE-2023-38408',
      'CRITICAL',
      '9.8',
      'openssh-server (9.3p1)',
      'rizal-po-agent'
    ],
    ['CVE-2023-4863', 'CRITICAL', '9', 'libwebp (1.0.3)', 'batangas-hub'],
    [
      'CVE-2022-22965',
      'HIGH',
      '8.8',
      'spring-framework (5.3.16)',
      'cavite-po-agent'
    ],
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
            subtitle:
                'Discovered CVEs mapped from the OS and application layer.',
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
          LayoutBuilder(
            builder: (context, constraints) {
              // A 5-column table (CVE ID, severity badge, CVSS score,
              // affected package, agent) has no room to breathe below this
              // width — package strings like "spring-framework (5.3.16)"
              // get clipped mid-word on a horizontal scroll. Below the
              // breakpoint, switch to a tappable card per CVE instead, and
              // let tapping any card open a large, easy-to-read detail view.
              final narrow = constraints.maxWidth < 640;
              return DashCard(
                child: narrow
                    ? _cveCardList(context)
                    : HScrollBox(
                        minWidth: 640,
                        child: SimpleTable(
                          headers: const [
                            'CVE ID',
                            'SEVERITY',
                            'CVSS SCORE',
                            'AFFECTED PACKAGE',
                            'AGENT'
                          ],
                          flex: const [2, 2, 2, 3, 2],
                          rows: [
                            for (final c in _cves)
                              [
                                CellText(c[0],
                                    color: AppColors.teal,
                                    weight: FontWeight.w600),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: StatusBadge(
                                    label: c[1],
                                    color: c[1] == 'CRITICAL'
                                        ? AppColors.red
                                        : AppColors.orange,
                                  ),
                                ),
                                CellText(c[2]),
                                CellText(c[3], color: AppColors.textSecondary),
                                CellText(c[4], color: AppColors.textSecondary),
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

  /// Mobile-width replacement for the 5-column table: one tappable card
  /// per CVE carrying the same fields, laid out top-to-bottom so nothing
  /// needs a sideways scroll or gets clipped mid-word.
  Widget _cveCardList(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < _cves.length; i++) ...[
          _CveCard(cve: _cves[i]),
          if (i != _cves.length - 1) const SizedBox(height: 10),
        ],
      ],
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
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CveCard extends StatelessWidget {
  final List<String> cve;

  const _CveCard({required this.cve});

  bool get _critical => cve[1] == 'CRITICAL';

  @override
  Widget build(BuildContext context) {
    final severityColor = _critical ? AppColors.red : AppColors.orange;
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showDetail(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cve[0],
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  StatusBadge(label: cve[1], color: severityColor),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                cve[3],
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _metaChip(Icons.speed, 'CVSS ${cve[2]}', severityColor),
                  _metaChip(Icons.dns_outlined, cve[4], AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 6),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Tap for details',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      size: 14, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
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

  void _showDetail(BuildContext context) {
    final severityColor = _critical ? AppColors.red : AppColors.orange;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Large, easy-to-read CVE ID as the headline.
              Text(
                cve[0],
                style: const TextStyle(
                  color: AppColors.teal,
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 12),
              StatusBadge(label: cve[1], color: severityColor),
              const SizedBox(height: 24),
              _detailRow('CVSS SCORE', cve[2],
                  valueColor: severityColor, big: true),
              const SizedBox(height: 18),
              _detailRow('AFFECTED PACKAGE', cve[3]),
              const SizedBox(height: 18),
              _detailRow('AFFECTED AGENT', cve[4]),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value,
      {Color valueColor = AppColors.textPrimary, bool big = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w600,
            fontSize: big ? 22 : 17,
          ),
        ),
      ],
    );
  }
}
