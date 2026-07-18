import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/wazuh_agent_model.dart';
import '../../models/wazuh_event_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

/// Maps the tenant dropdown labels to their spoke_id, matching the
/// SPOKE-01..05 records in the `spokes` collection (see
/// assets/firestore_schema_and_data.json). Batangas is the hub, not a
/// tenant here, so it's intentionally not in this list.
const Map<String, String> _tenantSpokeIds = {
  'Cavite Provincial Office': 'SPOKE-01',
  'Laguna Provincial Office': 'SPOKE-02',
  'Rizal Provincial Office': 'SPOKE-04',
  'Quezon Provincial Office': 'SPOKE-05',
};

class ProvincialView extends StatefulWidget {
  const ProvincialView({super.key});

  @override
  State<ProvincialView> createState() => _ProvincialViewState();
}

class _ProvincialViewState extends State<ProvincialView> {
  final List<String> _tenants = _tenantSpokeIds.keys.toList();
  late String _selectedTenant = _tenants.first;
  bool _seeding = false;

  String get _selectedSpokeId => _tenantSpokeIds[_selectedTenant]!;

  IconData _eventIcon(String type) {
    switch (type) {
      case 'Login Attempt':
        return Icons.lock_outline;
      case 'File Transfer':
        return Icons.insert_drive_file_outlined;
      case 'Suspicious Traffic':
        return Icons.show_chart;
      case 'Unauthorized Access':
        return Icons.block;
      case 'File Download':
        return Icons.insert_drive_file_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _formatTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final agentsRef = FirebaseFirestore.instance.collection('wazuh_agents');
    final eventsRef = FirebaseFirestore.instance.collection('wazuh_events');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tenant dropdown trigger. Built on PopupMenuButton instead of a
          // hand-rolled Overlay/LayerLink so the menu's position is
          // computed by Flutter itself and always renders directly
          // attached under the button, regardless of screen width.
          Row(
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 40),
                  child: PopupMenuButton<String>(
                    color: AppColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                    offset: const Offset(0, 46),
                    onSelected: (t) => setState(() => _selectedTenant = t),
                    itemBuilder: (context) => [
                      for (final t in _tenants)
                        PopupMenuItem(
                          value: t,
                          child: Text(
                            t,
                            style: TextStyle(
                              color: t == _selectedTenant
                                  ? AppColors.teal
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: AppColors.teal),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Tenant: $_selectedTenant',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
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
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Local Agent Dashboard',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Tenant isolation mode: Viewing local telemetry only.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              );
              final hubBlock = Column(
                crossAxisAlignment: constraints.maxWidth < 560
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  const Text('HUB CONNECTION',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          letterSpacing: 0.6)),
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Live sync active — this view streams directly '
                            'from Firestore in real time, no manual sync '
                            'needed.',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.teal),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sync, size: 15, color: AppColors.teal),
                          SizedBox(width: 6),
                          Text('Sync with Batangas Hub',
                              style: TextStyle(
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Status: Live (real-time)',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              );

              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titleBlock, const SizedBox(height: 16), hubBlock],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(child: titleBlock),
                  hubBlock,
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Stat cards — computed live from Firestore, filtered to the
          // selected tenant's spoke_id.
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: agentsRef
                .where('spoke_id', isEqualTo: _selectedSpokeId)
                .snapshots(),
            builder: (context, agentSnap) {
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: eventsRef
                    .where('spoke_id', isEqualTo: _selectedSpokeId)
                    .snapshots(),
                builder: (context, eventSnap) {
                  final agents = (agentSnap.data?.docs ?? const [])
                      .map(WazuhAgent.fromFirestore)
                      .toList();
                  final events = (eventSnap.data?.docs ?? const [])
                      .map(WazuhEvent.fromFirestore)
                      .toList();

                  final totalEndpoints = agents.length;
                  final activeEndpoints =
                      agents.where((a) => a.active).length;
                  final criticalAlerts =
                      events.where((e) => e.severity == 'High').length;
                  final highPriority =
                      events.where((e) => e.severity == 'Medium').length;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final stats = [
                        _statCard('ACTIVE ENDPOINTS', '$activeEndpoints',
                            Icons.check_circle_outline, AppColors.teal),
                        _statCard('TOTAL ENDPOINTS', '$totalEndpoints',
                            Icons.dns_outlined, AppColors.textSecondary),
                        _statCard('CRITICAL ALERTS', '$criticalAlerts',
                            Icons.shield_outlined, AppColors.red),
                        _statCard('HIGH PRIORITY', '$highPriority',
                            Icons.warning_amber_outlined, AppColors.orange),
                      ];
                      // 4-across on wide, 2x2 grid on tablets/phone-landscape,
                      // 1-per-row on narrow phone-portrait widths.
                      final columns = constraints.maxWidth < 420
                          ? 1
                          : constraints.maxWidth < 900
                              ? 2
                              : 4;
                      if (columns == 4) {
                        return Row(
                          children: [
                            for (int i = 0; i < stats.length; i++) ...[
                              Expanded(child: stats[i]),
                              if (i != stats.length - 1)
                                const SizedBox(width: 16),
                            ],
                          ],
                        );
                      }
                      final itemWidth = columns == 1
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 16) / 2;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (final s in stats)
                            SizedBox(width: itemWidth, child: s),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),

          // Event table — filtered to the selected tenant's spoke_id, live.
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: eventsRef
                .where('spoke_id', isEqualTo: _selectedSpokeId)
                .orderBy('timestamp', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                // A composite index is required for where + orderBy on
                // different fields — Firestore's error message includes a
                // direct console link to create it with one click.
                return DashCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Failed to load events: ${snapshot.error}\n\n'
                      'If this mentions a missing index, open the link in '
                      'the error to create it in Firebase Console.',
                      style: const TextStyle(color: AppColors.red),
                    ),
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
              final events =
                  snapshot.data!.docs.map(WazuhEvent.fromFirestore).toList();

              return DashCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        const _TitleWithIcon(),
                        const _RefreshLabel(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (events.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No events yet for $_selectedTenant. Use '
                            '"Seed Demo Data".',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      // Wider minWidth + a heavier SEVERITY flex share gives
                      // every column, especially the badge, enough breathing
                      // room on a horizontal scroll so nothing wraps onto a
                      // second line or gets clipped mid-word.
                      HScrollBox(
                        minWidth: 1180,
                        child: SimpleTable(
                          headers: const [
                            'TIME',
                            'ENDPOINT',
                            'EVENT TYPE',
                            'SEVERITY',
                            'DESCRIPTION',
                            'SOURCE',
                            'ACTION'
                          ],
                          flex: const [1, 2, 2, 2, 4, 2, 2],
                          align: const [
                            Alignment.center,
                            Alignment.centerLeft,
                            Alignment.centerLeft,
                            Alignment.center,
                            Alignment.centerLeft,
                            Alignment.center,
                            Alignment.center,
                          ],
                          rows: [
                            for (final e in events)
                              [
                                CellText(_formatTime(e.timestamp),
                                    color: AppColors.textSecondary),
                                CellText(e.endpoint, weight: FontWeight.w600),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_eventIcon(e.description),
                                        size: 14,
                                        color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Flexible(
                                        child: CellText(e.description,
                                            color: AppColors.textSecondary)),
                                  ],
                                ),
                                StatusBadge(
                                    label: e.severity,
                                    color: AppColors.severityColor(
                                        e.severity)),
                                CellText(e.description,
                                    color: AppColors.textSecondary),
                                CellText(e.sourceIp, color: AppColors.teal),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: AppColors.teal),
                                    foregroundColor: AppColors.teal,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${e.action} — noted for '
                                          '${e.endpoint} (not yet wired to '
                                          'the Sophos/pfSense mitigation '
                                          'API).',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(e.action,
                                      style: const TextStyle(fontSize: 11)),
                                ),
                              ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Showing ${events.length} recent security events for '
                        '$_selectedTenant.',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                        textAlign: TextAlign.center,
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

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return DashCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10.5,
                      letterSpacing: 0.4)),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 26)),
            ],
          ),
          Icon(icon, color: color, size: 22),
        ],
      ),
    );
  }

  /// TEMPORARY: seeds ~7 endpoint agents and 5 events per province across
  /// all 4 tenants in one go (so switching the dropdown always has data to
  /// show, without needing to reseed per tenant). Clears old provincial
  /// demo data first so repeated clicks don't duplicate. Remove or gate
  /// behind a debug flag before any production-style deployment.
  Future<void> _seedDemoData() async {
    setState(() => _seeding = true);
    try {
      final agentsRef = FirebaseFirestore.instance.collection('wazuh_agents');
      final eventsRef = FirebaseFirestore.instance.collection('wazuh_events');

      // Clear only previously-seeded *provincial* agents/events (those
      // with a spoke_id matching one of our 4 tenants) so this doesn't
      // touch the office-level agents seeded from the Overview screen.
      final tenantSpokeIds = _tenantSpokeIds.values.toList();
      final existingAgents = await agentsRef
          .where('spoke_id', whereIn: tenantSpokeIds)
          .where('agent_id', isEqualTo: '') // only our workstation-style seed docs
          .get();
      final existingEvents =
          await eventsRef.where('spoke_id', whereIn: tenantSpokeIds).get();

      final clearBatch = FirebaseFirestore.instance.batch();
      for (final doc in existingAgents.docs) {
        clearBatch.delete(doc.reference);
      }
      for (final doc in existingEvents.docs) {
        clearBatch.delete(doc.reference);
      }
      await clearBatch.commit();

      final batch = FirebaseFirestore.instance.batch();
      final rand = _SeededRandom();
      final now = DateTime.now();

      const eventTemplates = [
        {
          'type': 'Login Attempt',
          'severity': 'High',
          'description':
              'Multiple failed SSH login attempts (15 attempts in 2 minutes)',
          'action': 'Block IP',
        },
        {
          'type': 'File Transfer',
          'severity': 'Medium',
          'description':
              'Large file transfer to external IP (2.4GB to unknown destination)',
          'action': 'Review Transfer',
        },
        {
          'type': 'Suspicious Traffic',
          'severity': 'Low',
          'description': 'Unusual outbound traffic pattern detected on port 8080',
          'action': 'Investigate',
        },
        {
          'type': 'Unauthorized Access',
          'severity': 'Medium',
          'description': 'Attempted access to restricted directory /admin/config',
          'action': 'Review Permissions',
        },
        {
          'type': 'File Download',
          'severity': 'Low',
          'description': 'Executable file downloaded from external source',
          'action': 'Scan File',
        },
      ];

      for (final entry in _tenantSpokeIds.entries) {
        final tenantName = entry.key;
        final spokeId = entry.value;
        final prefix = tenantName.split(' ').first.toUpperCase();

        // 7 endpoints per province, mostly active — total 28 across all 4
        // tenants, matching the original mockup's "24 active / 28 total".
        for (int i = 0; i < 7; i++) {
          final isServer = i % 3 == 0;
          final hostname =
              '$prefix-${isServer ? 'SRV' : 'WS'}-${(i + 1).toString().padLeft(2, '0')}';
          batch.set(agentsRef.doc(), {
            'name': hostname,
            'ip': '10.45.${i + 1}.${10 + i}',
            'active': rand.nextDouble() > 0.15,
            'spoke_id': spokeId,
            'agent_id': '',
            'os': '',
            'version': '',
          });
        }

        // 5 events per province, spread over the last couple hours.
        final endpoints = [
          '$prefix-WS-012',
          '$prefix-SRV-03',
          '$prefix-WS-007',
          '$prefix-WS-019',
          '$prefix-SRV-01',
        ];
        for (int i = 0; i < eventTemplates.length; i++) {
          final t = eventTemplates[i];
          batch.set(eventsRef.doc(), {
            'timestamp': Timestamp.fromDate(
                now.subtract(Duration(minutes: 4 + i * 13))),
            'agent': '${prefix.toLowerCase()}-po-agent',
            'rule_id': '${5000 + rand.nextInt(5000)}',
            'level': 0,
            'description': t['description'],
            'spoke_id': spokeId,
            'endpoint': endpoints[i],
            'severity': t['severity'],
            'source_ip': '192.168.${10 + i}.${40 + i}',
            'action': t['action'],
          });
        }
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Seeded demo endpoints and events for all provinces.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seeding failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }
}

/// Minimal deterministic-free pseudo-random helper so the seeder doesn't
/// need to import dart:math separately at the top for a couple of calls.
class _SeededRandom {
  int _seed = DateTime.now().microsecondsSinceEpoch;

  double nextDouble() {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return (_seed % 10000) / 10000.0;
  }

  int nextInt(int max) {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed % max;
  }
}

class _TitleWithIcon extends StatelessWidget {
  const _TitleWithIcon();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.show_chart, size: 16, color: AppColors.teal),
        SizedBox(width: 8),
        Text('Real-Time Security Events',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ],
    );
  }
}

class _RefreshLabel extends StatelessWidget {
  const _RefreshLabel();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.refresh, size: 15, color: AppColors.textSecondary),
        SizedBox(width: 4),
        Text('Live',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}