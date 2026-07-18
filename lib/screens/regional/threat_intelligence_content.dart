import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/ioc_finding_model.dart';
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
  final _iocsRef = FirebaseFirestore.instance.collection('ioc_findings');
  bool _seeding = false;

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
            trailing: OutlinedButton.icon(
              onPressed: _seeding ? null : _seedDemoData,
              icon: _seeding
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.dataset_outlined, size: 16),
              label: Text(_seeding ? 'Seeding...' : 'Seed Demo Data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.cardBorder),
              ),
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _iocsRef.orderBy('last_seen', descending: true).snapshots(),
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
              final iocs =
                  snapshot.data!.docs.map(IocFinding.fromFirestore).toList();

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
                                'No IoC matches yet. Use "Seed Demo Data".',
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

  /// TEMPORARY: seeds 3 demo IoC matches via WriteBatch. Real matches
  /// would come from the heuristic engine cross-referencing Wazuh alert
  /// metadata against a threat feed — remove or gate behind a debug flag
  /// before any production-style deployment.
  Future<void> _seedDemoData() async {
    setState(() => _seeding = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final now = DateTime.now();
      final seed = [
        {
          'indicator': '185.220.101.44',
          'type': 'IP Address',
          'threat_actor': 'Mirai Botnet',
          'agent_name': 'rizal-po-agent',
          'last_seen': Timestamp.fromDate(now.subtract(const Duration(minutes: 5))),
        },
        {
          'indicator': '4b494...8c7f9',
          'type': 'File Hash (SHA256)',
          'threat_actor': 'Ransomware.WannaCry',
          'agent_name': 'cavite-po-agent',
          'last_seen': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
        },
        {
          'indicator': 'malicious-domain.xyz',
          'type': 'DNS Query',
          'threat_actor': 'Phishing',
          'agent_name': 'laguna-po-agent',
          'last_seen': Timestamp.fromDate(now.subtract(const Duration(hours: 3))),
        },
      ];
      for (final i in seed) {
        batch.set(_iocsRef.doc(), i);
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seeded 3 demo IoC matches.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Seeding failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }
}
