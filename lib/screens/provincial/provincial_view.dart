import 'package:flutter/material.dart';
import '../../models/wazuh_agent_model.dart';
import '../../models/wazuh_event_model.dart';
import '../../services/wazuh_agent_repository.dart';
import '../../services/wazuh_event_repository.dart';
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
  final _agentRepository = WazuhAgentRepository();
  final _eventRepository = WazuhEventRepository();

  final List<String> _tenants = _tenantSpokeIds.keys.toList();
  late String _selectedTenant = _tenants.first;

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // Tenant selector, restyled as a small auto-width pill — same
              // visual language as the "Sync with Batangas Hub" chip below
              // (rounded, teal outline, no filled card background) instead
              // of a full-width gray bordered box. A full-width card reads
              // as its own separate section no matter where it's placed;
              // an auto-width pill sitting right above the title reads as
              // one small tag that belongs to the header.
              final tenantDropdown = PopupMenuButton<String>(
                color: AppColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
                offset: const Offset(0, 38),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.teal),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.teal),
                      const SizedBox(width: 5),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.5),
                        child: Text(
                          _selectedTenant,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                              color: AppColors.teal,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 14,
                        color: AppColors.teal,
                      ),
                    ],
                  ),
                ),
              );

              // Tenant pill sits directly above the title on its own —
              // no refresh button anymore. Agent/event data already comes
              // from live Firestore StreamBuilders (watchAgents/
              // watchEvents), so a manual "refresh" control had no real
              // effect; it was just calling setState(() {}) with nothing
              // to actually re-fetch.
              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Local Agent Dashboard',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                      'Tenant isolation mode: Viewing local telemetry only.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 10),
                  tenantDropdown,
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
                        SnackBar(
                          content: Text(
                            '$_selectedTenant is synced live with the '
                            'Batangas Hub via Firestore — no manual sync '
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
                  Expanded(child: titleBlock),
                  hubBlock,
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Stat cards — computed live from Firestore, filtered to the
          // selected tenant's spoke_id.
          StreamBuilder<List<WazuhAgent>>(
            stream: _agentRepository.watchAgents(spokeId: _selectedSpokeId),
            builder: (context, agentSnap) {
              return StreamBuilder<List<WazuhEvent>>(
                stream: _eventRepository.watchEvents(
                    spokeId: _selectedSpokeId,
                    limit: 1000), // Get enough events to count stats
                builder: (context, eventSnap) {
                  final agents = agentSnap.data ?? const [];
                  final events = eventSnap.data ?? const [];

                  final totalEndpoints = agents.length;
                  final activeEndpoints = agents.where((a) => a.active).length;
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
          StreamBuilder<List<WazuhEvent>>(
            stream: _eventRepository.watchEvents(
                limit: 20, spokeId: _selectedSpokeId),
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
                      'the console to build it.',
                      style: const TextStyle(color: AppColors.red),
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const DashCard(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final events = snapshot.data!;

              return DashCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _TitleWithIcon(),
                        _RefreshLabel(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (events.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No events found for this tenant yet.',
                          style: TextStyle(color: AppColors.textSecondary),
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
                                    color: AppColors.severityColor(e.severity)),
                                CellText(e.description,
                                    color: AppColors.textSecondary),
                                CellText(e.sourceIp, color: AppColors.teal),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side:
                                        const BorderSide(color: AppColors.teal),
                                    foregroundColor: AppColors.teal,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                          onRowTap: [
                            for (final e in events)
                              () => _showEventDetails(context, e),
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

  void _showEventDetails(BuildContext context, WazuhEvent event) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Event Details',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.textSecondary, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _detailRow('Endpoint', event.endpoint),
                _detailRow('Time', _formatTime(event.timestamp)),
                _detailRow('Severity', event.severity,
                    color: AppColors.severityColor(event.severity)),
                _detailRow('Source IP', event.sourceIp),
                _detailRow('Action Taken', event.action),
                const SizedBox(height: 16),
                const Text('Full Description:',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    event.description,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  color: color ?? AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
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