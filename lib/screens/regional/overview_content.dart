import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/wazuh_agent_model.dart';
import '../../models/mitre_tactic_model.dart';
import '../../models/wazuh_event_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class OverviewContent extends StatefulWidget {
  const OverviewContent({super.key});

  @override
  State<OverviewContent> createState() => _OverviewContentState();
}

class _OverviewContentState extends State<OverviewContent> {
  final _agentsRef = FirebaseFirestore.instance.collection('wazuh_agents');
  final _tacticsRef = FirebaseFirestore.instance.collection('mitre_tactics');
  final _eventsRef = FirebaseFirestore.instance.collection('wazuh_events');
  bool _seeding = false;

  // Event Stream filters. These operate client-side on whatever the
  // wazuh_events stream returns — no separate query/index needed, and no
  // change to the data source itself.
  String _selectedAgent = 'All Agents';
  String _selectedSeverity = 'All Levels';

  static const _severityOptions = [
    'All Levels',
    'Critical (12+)',
    'High (8-11)',
    'Low (<8)',
  ];

  bool _matchesSeverity(int level) {
    switch (_selectedSeverity) {
      case 'Critical (12+)':
        return level >= 12;
      case 'High (8-11)':
        return level >= 8 && level <= 11;
      case 'Low (<8)':
        return level < 8;
      default:
        return true;
    }
  }

  void _resetEventFilters() {
    setState(() {
      _selectedAgent = 'All Agents';
      _selectedSeverity = 'All Levels';
    });
  }

  /// Maps a Wazuh rule level to the same red/orange/teal scale used
  /// elsewhere: 12+ critical, 8-11 high, below that informational.
  static Color _levelColor(int level) {
    if (level >= 12) return AppColors.red;
    if (level >= 8) return AppColors.orange;
    return AppColors.teal;
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
            title: 'Security Events Dashboard',
            subtitle:
                'Aggregated telemetry from all Region 4A provincial agents.',
            trailing: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                const StatusBadge(
                    label: 'Wazuh Indexer: OK', color: AppColors.teal),
                const StatusBadge(
                    label: 'Manager Cluster: OK', color: AppColors.teal),
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
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 800;
              if (stacked) {
                return Column(
                  children: [
                    _agentStatusCard(),
                    const SizedBox(height: 16),
                    _eventEvolutionCard(),
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 4, child: _agentStatusCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 7, child: _eventEvolutionCard()),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 800;
              if (stacked) {
                return Column(
                  children: [
                    _mitreCard(),
                    const SizedBox(height: 16),
                    _eventStreamCard(context),
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 4, child: _mitreCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 7, child: _eventStreamCard(context)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Agent status
  // ---------------------------------------------------------------------
  Widget _agentStatusCard() {
    return DashCard(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _agentsRef.orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Failed to load agents: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.red)),
            );
          }
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final agents =
              snapshot.data!.docs.map(WazuhAgent.fromFirestore).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Agent Status',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  StatusBadge(
                      label: 'Total: ${agents.length}',
                      color: AppColors.textSecondary,
                      outlined: false),
                ],
              ),
              const SizedBox(height: 14),
              if (agents.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No agents yet. Use "Seed Demo Data".',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                )
              else
                for (final agent in agents) _agentTile(agent),
            ],
          );
        },
      ),
    );
  }

  Widget _agentTile(WazuhAgent agent) {
    final active = agent.active;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active
              ? AppColors.cardBorder
              : AppColors.red.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.circle,
              size: 8, color: active ? AppColors.teal : AppColors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agent.name,
                    style: TextStyle(
                      color: active ? AppColors.textPrimary : AppColors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    )),
                Text(agent.ip,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Text(
            active ? 'ACTIVE' : 'INACTIVE',
            style: TextStyle(
              color: active ? AppColors.teal : AppColors.red,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Event evolution chart — derived from the most recent wazuh_events
  // ---------------------------------------------------------------------
  Widget _eventEvolutionCard() {
    return DashCard(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _eventsRef
            .orderBy('timestamp', descending: true)
            .limit(17)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? const [];
          final events =
              docs.map(WazuhEvent.fromFirestore).toList().reversed.toList();
          final spots = <FlSpot>[
            for (int i = 0; i < events.length; i++)
              FlSpot(i.toDouble(), events[i].level.toDouble()),
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text('Event Evolution (Severity Levels)',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  _LegendDot(
                      color: AppColors.red, label: 'Level 12+ (Critical)'),
                  _LegendDot(
                      color: AppColors.orange, label: 'Level 8-11 (High)'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: spots.isEmpty
                    ? const Center(
                        child: Text(
                          'No event data yet.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: 20,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 5,
                            getDrawingHorizontalLine: (v) => const FlLine(
                                color: AppColors.cardBorder, strokeWidth: 1),
                          ),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 5,
                                reservedSize: 28,
                                getTitlesWidget: (v, meta) => Text(
                                  v.toInt().toString(),
                                  style: const TextStyle(
                                      color: AppColors.textMuted, fontSize: 10),
                                ),
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: false,
                              color: AppColors.red,
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.red.withValues(alpha: 0.35),
                                    AppColors.red.withValues(alpha: 0.02),
                                  ],
                                ),
                              ),
                              spots: spots,
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------
  // MITRE ATT&CK tactics
  // ---------------------------------------------------------------------
  Widget _mitreCard() {
    return DashCard(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _tacticsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final tactics =
              snapshot.data!.docs.map(MitreTactic.fromFirestore).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MITRE ATT&CK Tactics',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(height: 16),
              if (tactics.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No tactic data yet. Use "Seed Demo Data".',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                )
              else
                for (final t in tactics) _tacticBar(t),
            ],
          );
        },
      ),
    );
  }

  Widget _tacticBar(MitreTactic t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              t.tacticName,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11.5),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: t.score,
                minHeight: 8,
                backgroundColor: AppColors.background,
                valueColor:
                    AlwaysStoppedAnimation(AppColors.severityColor(t.severity)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Real-time event stream
  // ---------------------------------------------------------------------
  Widget _eventStreamCard(BuildContext context) {
    return DashCard(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _eventsRef
            .orderBy('timestamp', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Failed to load events: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.red)),
            );
          }
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final allEvents =
              snapshot.data!.docs.map(WazuhEvent.fromFirestore).toList();

          final agentOptions = <String>{
            'All Agents',
            ...allEvents.map((e) => e.agent),
          }.toList()
            ..sort((a, b) => a == 'All Agents'
                ? -1
                : (b == 'All Agents' ? 1 : a.compareTo(b)));
          // Selected agent may no longer exist in the live stream (e.g.
          // decommissioned agent) — fall back instead of crashing the
          // dropdown on an invalid value.
          final agentValue = agentOptions.contains(_selectedAgent)
              ? _selectedAgent
              : 'All Agents';

          final events = allEvents.where((e) {
            final agentMatch =
                agentValue == 'All Agents' || e.agent == agentValue;
            return agentMatch && _matchesSeverity(e.level);
          }).toList();

          final filtersActive =
              agentValue != 'All Agents' || _selectedSeverity != 'All Levels';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  _EventStreamTitle(),
                  _RefreshRow(),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _filterDropdown(
                    icon: Icons.dns_outlined,
                    value: agentValue,
                    options: agentOptions,
                    onChanged: (v) => setState(() => _selectedAgent = v!),
                  ),
                  _filterDropdown(
                    icon: Icons.filter_alt_outlined,
                    value: _selectedSeverity,
                    options: _severityOptions,
                    onChanged: (v) => setState(() => _selectedSeverity = v!),
                  ),
                  if (filtersActive)
                    TextButton.icon(
                      onPressed: _resetEventFilters,
                      icon: const Icon(Icons.close,
                          size: 15, color: AppColors.textSecondary),
                      label: const Text('Clear Filters',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (allEvents.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No events yet. Use "Seed Demo Data".',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                )
              else if (events.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No events match the selected filters.',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 560;
                    if (narrow) {
                      return _eventCardList(context, events);
                    }
                    return HScrollBox(
                      minWidth: 620,
                      child: SimpleTable(
                        headers: const [
                          'TIMESTAMP',
                          'AGENT',
                          'RULE ID',
                          'LEVEL',
                          'DESCRIPTION'
                        ],
                        flex: const [2, 3, 2, 1, 5],
                        align: const [
                          Alignment.centerLeft,
                          Alignment.centerLeft,
                          Alignment.centerLeft,
                          Alignment.center,
                          Alignment.centerLeft,
                        ],
                        rows: [
                          for (final e in events)
                            [
                              _tappableCell(
                                context,
                                e,
                                CellText(_formatTime(e.timestamp),
                                    color: AppColors.textSecondary),
                              ),
                              _tappableCell(
                                context,
                                e,
                                CellText(e.agent, color: AppColors.teal),
                              ),
                              _tappableCell(
                                context,
                                e,
                                CellText(e.ruleId, color: AppColors.teal),
                              ),
                              _tappableCell(
                                context,
                                e,
                                StatusBadge(
                                  label: '${e.level}',
                                  color: _levelColor(e.level),
                                ),
                              ),
                              _tappableCell(
                                context,
                                e,
                                CellText(e.description,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                        ],
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterDropdown({
    required IconData icon,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              dropdownColor: AppColors.card,
              icon: const Icon(Icons.keyboard_arrow_down,
                  size: 16, color: AppColors.textMuted),
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500),
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tappableCell(BuildContext context, WazuhEvent event, Widget child) {
    return InkWell(
      onTap: () => _showEventDetails(context, event),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: child,
      ),
    );
  }

  /// Mobile-width replacement for the event table: one card per event so
  /// the full description is always readable without truncation or
  /// side-scrolling. Tapping a card opens the same detail dialog used by
  /// the wide table.
  Widget _eventCardList(BuildContext context, List<WazuhEvent> events) {
    return Column(
      children: [
        for (final e in events)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _showEventDetails(context, e),
              child: Container(
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
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                e.ruleId,
                                style: const TextStyle(
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                e.agent,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(
                            label: '${e.level}', color: _levelColor(e.level)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.description,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(e.timestamp),
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11.5),
                        ),
                        const Spacer(),
                        const Text(
                          'Tap for details',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right,
                            size: 14, color: AppColors.textMuted),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Full-detail popup for a single event, used from both the wide table
  /// (tap a row) and the narrow card list (tap a card).
  void _showEventDetails(BuildContext context, WazuhEvent event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Row(
          children: [
            const Icon(Icons.terminal, size: 18, color: AppColors.teal),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Event Details',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
            StatusBadge(
                label: '${event.level}', color: _levelColor(event.level)),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('TIMESTAMP', _formatTime(event.timestamp)),
              _detailRow('AGENT', event.agent),
              _detailRow('RULE ID', event.ruleId),
              _detailRow('LEVEL', '${event.level}'),
              const SizedBox(height: 8),
              const Text('DESCRIPTION',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10.5,
                      letterSpacing: 0.4)),
              const SizedBox(height: 6),
              Text(
                event.description,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                    letterSpacing: 0.4)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // TEMPORARY seeder — writes demo agents, tactics, and events. Remove or
  // gate behind a debug flag before any production-style deployment; the
  // real data path is Wazuh -> Python heuristic engine -> these same
  // collections, written server-side via the Admin SDK.
  // ---------------------------------------------------------------------
  Future<void> _seedDemoData() async {
    setState(() => _seeding = true);
    try {
      final batch = FirebaseFirestore.instance.batch();

      const agentSeed = [
        {
          'name': 'cavite-po-agent',
          'ip': '10.0.1.5',
          'active': true,
          'spoke_id': 'SPOKE-01'
        },
        {
          'name': 'laguna-po-agent',
          'ip': '10.0.2.10',
          'active': true,
          'spoke_id': 'SPOKE-02'
        },
        {
          'name': 'batangas-po-agent',
          'ip': '10.0.3.8',
          'active': true,
          'spoke_id': 'SPOKE-03'
        },
        {
          'name': 'rizal-po-agent',
          'ip': '10.0.3.15',
          'active': false,
          'spoke_id': 'SPOKE-04'
        },
        {
          'name': 'quezon-po-agent',
          'ip': '10.0.4.22',
          'active': true,
          'spoke_id': 'SPOKE-05'
        },
      ];
      for (final a in agentSeed) {
        batch.set(_agentsRef.doc(), a);
      }

      const tacticSeed = [
        {'tactic_name': 'Initial Access', 'score': 0.55, 'severity': 'High'},
        {'tactic_name': 'Execution', 'score': 0.18, 'severity': 'Low'},
        {'tactic_name': 'Persistence', 'score': 0.45, 'severity': 'High'},
        {
          'tactic_name': 'Privilege Esc.',
          'score': 0.12,
          'severity': 'Critical'
        },
        {
          'tactic_name': 'Defense\nEvasion',
          'score': 0.68,
          'severity': 'Critical'
        },
        {'tactic_name': 'Credential\nAccess', 'score': 0.4, 'severity': 'High'},
        {'tactic_name': 'Discovery', 'score': 0.6, 'severity': 'Low'},
      ];
      for (final t in tacticSeed) {
        batch.set(_tacticsRef.doc(), t);
      }

      final rand = Random();
      final descriptions = [
        'sshd: Attempt to login using a non-existent user',
        'Firewall dropped connection from malicious IP',
        'Unknown problem somewhere in the system',
        'Multiple web server 400 error codes from same IP',
        'Integrity checksum changed for monitored file',
        'PAM: User login failed',
      ];
      final agentNames = agentSeed.map((a) => a['name'] as String).toList();
      final now = DateTime.now();
      for (int i = 0; i < 20; i++) {
        final ref = _eventsRef.doc();
        final ts = now.subtract(Duration(minutes: i * 7));
        batch.set(ref, {
          'timestamp': Timestamp.fromDate(ts),
          'agent': agentNames[rand.nextInt(agentNames.length)],
          'rule_id': '${1000 + rand.nextInt(30000)}',
          'level': rand.nextInt(17),
          'description': descriptions[rand.nextInt(descriptions.length)],
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Seeded demo agents, tactics, and events.')),
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

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }
}

class _EventStreamTitle extends StatelessWidget {
  const _EventStreamTitle();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.terminal, size: 16, color: AppColors.teal),
        SizedBox(width: 8),
        Text('Real-Time Event Stream',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ],
    );
  }
}

class _RefreshRow extends StatelessWidget {
  const _RefreshRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.refresh, size: 16, color: AppColors.textSecondary),
        SizedBox(width: 4),
        Text('Refresh',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
