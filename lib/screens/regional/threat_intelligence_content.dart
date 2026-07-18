import 'package:flutter/material.dart';
import '../../models/ioc_finding_model.dart';
import '../../services/threat_intel_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class ThreatIntelligenceContent extends StatefulWidget {
  const ThreatIntelligenceContent({super.key});

  @override
  State<ThreatIntelligenceContent> createState() =>
      _ThreatIntelligenceContentState();
}

class _ThreatIntelligenceContentState
    extends State<ThreatIntelligenceContent> {
  final _repository = ThreatIntelRepository();

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

  String _formatTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Threat Intelligence',
            subtitle:
                'Identified Indicators of Compromise (IoCs) matched against live traffic.',
            trailing: IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => setState(() {}),
              tooltip: 'Refresh',
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<IocFinding>>(
            stream: _repository.watchIocs(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return DashCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Failed to load IoCs: ${snapshot.error}',
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
              final iocs = snapshot.data!;

              return LayoutBuilder(
                builder: (context, constraints) {
                  // A 5-column table needs real width to stay readable.
                  // Below this breakpoint a horizontal-scroll table only
                  // ever shows a partial, mid-scroll slice of columns on a
                  // phone. Cards avoid sideways scrolling entirely: every
                  // IoC's full info is visible by just scrolling down like
                  // the rest of the page.
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
                        if (iocs.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No IoC matches yet.',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                              ),
                            ),
                          )
                        else if (narrow)
                          _iocCardList(iocs)
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
                                for (final i in iocs)
                                  [
                                    CellText(i.indicator, color: AppColors.red),
                                    CellText(i.type,
                                        color: AppColors.textSecondary),
                                    CellText(i.threatActor,
                                        weight: FontWeight.w600),
                                    CellText(i.agentName,
                                        color: AppColors.textSecondary),
                                    CellText(_formatTime(i.lastSeen),
                                        color: AppColors.textSecondary),
                                  ],
                              ],
                            ),
                          ),
                      ],
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

  /// Mobile-width replacement for the IoC table: one card per indicator so
  /// nothing needs a sideways scroll to be seen in full.
  Widget _iocCardList(List<IocFinding> iocs) {
    return Column(
      children: [
        for (final i in iocs)
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
                    Icon(_typeIcon(i.type), size: 15, color: AppColors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        i.indicator,
                        style: const TextStyle(
                          color: AppColors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(label: i.type, color: AppColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  i.threatActor,
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
                    _metaChip(Icons.dns_outlined, i.agentName, AppColors.teal),
                    _metaChip(Icons.access_time, _formatTime(i.lastSeen),
                        AppColors.textMuted),
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
