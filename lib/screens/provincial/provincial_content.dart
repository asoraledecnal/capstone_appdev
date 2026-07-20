import 'package:flutter/material.dart';
import '../../models/wazuh_agent_model.dart';
import '../../models/wazuh_event_model.dart';
import '../../services/wazuh_agent_repository.dart';
import '../../services/wazuh_event_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

import '../../widgets/provincial_sidebar.dart';

class ProvincialContent extends StatefulWidget {
  final ProvincialModule module;
  final String? spokeId;

  const ProvincialContent({
    super.key,
    this.module = ProvincialModule.localDashboard,
    this.spokeId,
  });

  @override
  State<ProvincialContent> createState() => _ProvincialContentState();
}

class _ProvincialContentState extends State<ProvincialContent> {
  final _agentRepository = WazuhAgentRepository();
  final _eventRepository = WazuhEventRepository();

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

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  @override
  Widget build(BuildContext context) {
    // ProvincialModule cases other than localDashboard are routed by
    // HomeShell directly to their own dedicated screens — this widget
    // only ever receives localDashboard.
    return _buildLocalDashboard(context);
  }

  Widget _buildLocalDashboard(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  Text(
                      'Tenant isolation mode: Viewing local telemetry only.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  SizedBox(height: 10),
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
                            '${widget.spokeId} is synced live with the '
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
                  const Expanded(child: titleBlock),
                  hubBlock,
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Stat cards — computed live from Firestore, filtered to the
          // selected tenant's spoke_id.
          StreamBuilder<List<WazuhAgent>>(
            stream: _agentRepository.watchAgents(spokeId: widget.spokeId),
            builder: (context, agentSnap) {
              return StreamBuilder<List<WazuhEvent>>(
                stream: _eventRepository.watchEvents(
                    spokeId: widget.spokeId,
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
                            Icons.check_circle_outline, AppColors.teal, onTap: () {
                          _showAgentsDialog(context, agents.where((a) => a.active).toList(), 'Active Endpoints');
                        }),
                        _statCard('TOTAL ENDPOINTS', '$totalEndpoints',
                            Icons.dns_outlined, AppColors.textSecondary, onTap: () {
                          _showAgentsDialog(context, agents, 'Total Endpoints');
                        }),
                        _statCard('CRITICAL ALERTS', '$criticalAlerts',
                            Icons.shield_outlined, AppColors.red, onTap: () {
                          _showAllEventsDialog(context, events.where((e) => e.severity == 'High').toList(), title: 'Critical Alerts');
                        }),
                        _statCard('HIGH PRIORITY', '$highPriority',
                            Icons.warning_amber_outlined, AppColors.orange, onTap: () {
                          _showAllEventsDialog(context, events.where((e) => e.severity == 'Medium').toList(), title: 'High Priority Alerts');
                        }),
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
                limit: 20, spokeId: widget.spokeId),
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
              final previewEvents = events.take(5).toList();

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
                            for (final e in previewEvents)
                              [
                                CellText(_formatDateTime(e.timestamp),
                                    color: AppColors.textSecondary),
                                CellText(e.endpoint, weight: FontWeight.w600),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_eventIcon(e.type),
                                        size: 14,
                                        color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Flexible(
                                        child: CellText(
                                            e.type.isEmpty
                                                ? 'Unknown Event'
                                                : e.type,
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
                            for (final e in previewEvents)
                              () => _showEventDetails(context, e),
                          ],
                        ),
                      ),
                    if (events.length > 5) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => _showAllEventsDialog(context, events),
                          child: Text(
                            'View All History (${events.length})',
                            style: const TextStyle(
                              color: AppColors.teal,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAllEventsDialog(BuildContext context, List<WazuhEvent> allEvents, {String title = 'Event History'}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: Text(title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 1000,
            height: 600,
            child: SingleChildScrollView(
              child: HScrollBox(
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
                    for (final e in allEvents)
                      [
                        CellText(_formatDateTime(e.timestamp),
                            color: AppColors.textSecondary),
                        CellText(e.endpoint, weight: FontWeight.w600),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_eventIcon(e.type),
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Flexible(
                                child: CellText(
                                    e.type.isEmpty ? 'Unknown Event' : e.type,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                        StatusBadge(
                            label: e.severity,
                            color: AppColors.severityColor(e.severity)),
                        CellText(e.description, color: AppColors.textSecondary),
                        CellText(e.sourceIp, color: AppColors.teal),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.teal),
                            foregroundColor: AppColors.teal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${e.action} — noted for '
                                  '${e.endpoint} (not yet wired to '
                                  'the Sophos/pfSense mitigation API).',
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
                    for (final e in allEvents)
                      () => _showEventDetails(context, e),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    final content = DashCard(
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

    if (onTap == null) return content;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: content,
      ),
    );
  }

  void _showAgentsDialog(BuildContext context, List<WazuhAgent> agents, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: Text(title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500,
            height: 400,
            child: agents.isEmpty
                ? const Center(child: Text('No agents found.', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    itemCount: agents.length,
                    itemBuilder: (context, i) {
                      final a = agents[i];
                      return ListTile(
                        leading: Icon(Icons.circle, size: 12, color: a.active ? AppColors.teal : AppColors.red),
                        title: Text(a.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                        subtitle: Text(a.ip, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        trailing: Text(a.active ? 'ACTIVE' : 'INACTIVE', style: TextStyle(color: a.active ? AppColors.teal : AppColors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        );
      },
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
                _detailRow('Time', _formatDateTime(event.timestamp)),
                _detailRow('Severity', event.severity,
                    color: AppColors.severityColor(event.severity)),
                _detailRow('Rule Level', 'Level ${event.level}'),
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
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dashboard is streaming live in real-time! No manual refresh needed.'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(4),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.autorenew, size: 15, color: AppColors.teal),
            SizedBox(width: 4),
            Text('Live',
                style: TextStyle(color: AppColors.teal, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}