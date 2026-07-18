import 'package:flutter/material.dart';
import '../../models/cve_finding_model.dart';
import '../../services/cve_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class VulnerabilitiesContent extends StatefulWidget {
  const VulnerabilitiesContent({super.key});

  @override
  State<VulnerabilitiesContent> createState() =>
      _VulnerabilitiesContentState();
}

class _VulnerabilitiesContentState extends State<VulnerabilitiesContent> {
  final _repository = CveRepository();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<List<CveFinding>>(
            stream: _repository.watchCves(),
            builder: (context, snapshot) {
              final cves = snapshot.data ?? const [];
              final criticalCount =
                  cves.where((c) => c.severity == 'CRITICAL').length;
              final highCount =
                  cves.where((c) => c.severity == 'HIGH').length;

              return PageHeader(
                title: 'Vulnerability Detector',
                subtitle:
                    'Discovered CVEs mapped from the OS and application layer.',
                trailing: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _statPill('$criticalCount', 'CRITICAL', AppColors.red),
                    _statPill('$highCount', 'HIGH', AppColors.orange),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () => setState(() {}),
                      tooltip: 'Refresh',
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<CveFinding>>(
            stream: _repository.watchCves(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return DashCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Failed to load CVEs: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.red)),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const DashCard(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              final cves = snapshot.data!;

              if (cves.isEmpty) {
                return const DashCard(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No CVE findings yet.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  // A 5-column table (CVE ID, severity badge, CVSS score,
                  // affected package, agent) has no room to breathe below
                  // this width — package strings like
                  // "spring-framework (5.3.16)" get clipped mid-word on a
                  // horizontal scroll. Below the breakpoint, switch to a
                  // tappable card per CVE instead, and let tapping any card
                  // open a large, easy-to-read detail view.
                  final narrow = constraints.maxWidth < 640;
                  return DashCard(
                    child: narrow
                        ? _cveCardList(context, cves)
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
                                for (final c in cves)
                                  [
                                    CellText(c.cveId,
                                        color: AppColors.teal,
                                        weight: FontWeight.w600),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: StatusBadge(
                                        label: c.severity,
                                        color: c.severity == 'CRITICAL'
                                            ? AppColors.red
                                            : AppColors.orange,
                                      ),
                                    ),
                                    CellText(c.cvssScore),
                                    CellText(c.affectedPackage,
                                        color: AppColors.textSecondary),
                                    CellText(c.agentName,
                                        color: AppColors.textSecondary),
                                  ],
                              ],
                            ),
                          ),
                  );
                },
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
  Widget _cveCardList(BuildContext context, List<CveFinding> cves) {
    return Column(
      children: [
        for (int i = 0; i < cves.length; i++) ...[
          _CveCard(cve: cves[i]),
          if (i != cves.length - 1) const SizedBox(height: 10),
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
  final CveFinding cve;

  const _CveCard({required this.cve});

  bool get _critical => cve.severity == 'CRITICAL';

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
                      cve.cveId,
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  StatusBadge(label: cve.severity, color: severityColor),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                cve.affectedPackage,
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
                  _metaChip(Icons.speed, 'CVSS ${cve.cvssScore}', severityColor),
                  _metaChip(
                      Icons.dns_outlined, cve.agentName, AppColors.textMuted),
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
              Text(
                cve.cveId,
                style: const TextStyle(
                  color: AppColors.teal,
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 12),
              StatusBadge(label: cve.severity, color: severityColor),
              const SizedBox(height: 24),
              _detailRow('CVSS SCORE', cve.cvssScore,
                  valueColor: severityColor, big: true),
              const SizedBox(height: 18),
              _detailRow('AFFECTED PACKAGE', cve.affectedPackage),
              const SizedBox(height: 18),
              _detailRow('AFFECTED AGENT', cve.agentName),
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
