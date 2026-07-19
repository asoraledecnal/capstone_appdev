import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/wazuh_agent_model.dart';
import '../../models/mitre_tactic_model.dart';
import '../../models/wazuh_event_model.dart';
import '../../services/wazuh_agent_repository.dart';
import '../../services/mitre_tactic_repository.dart';
import '../../services/wazuh_event_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class OverviewContent extends StatefulWidget {
  const OverviewContent({super.key});

  @override
  State<OverviewContent> createState() => _OverviewContentState();
}

class _OverviewContentState extends State<OverviewContent> {
  final _agentRepository = WazuhAgentRepository();
  final _mitreRepository = MitreTacticRepository();
  final _eventRepository = WazuhEventRepository();

  static const _previewLimit = 5;
  static const _severityFilters = ['All', 'Critical', 'High', 'Medium', 'Low'];
  String _selectedSeverity = 'All';
  String _selectedAgent = 'All';

  static List<T> _distinctBy<T, K>(List<T> items, K Function(T) key) {
    final seen = <K>{};
    final unique = <T>[];
    for (final item in items) {
      final value = key(item);
      if (seen.add(value)) {
        unique.add(item);
      }
    }
    return unique;
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
          const PageHeader(
            title: 'Security Events Dashboard',
            subtitle:
                'Aggregated telemetry from all Region 4A provincial agents.',
            trailing: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                StatusBadge(label: 'Wazuh Indexer: OK', color: AppColors.teal),
                StatusBadge(
                    label: 'Manager Cluster: OK', color: AppColors.teal),
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
      child: StreamBuilder<List<WazuhAgent>>(
        stream: _agentRepository.watchAgents(),
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
          final agents = snapshot.data!;
          final previewAgents = agents.length > _previewLimit
              ? agents.sublist(0, _previewLimit)
              : agents;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Agent Status',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  Text(
                    '${agents.length} Total',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (agents.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No agents yet. Add agents from your Wazuh pipeline.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                )
              else ...[
                for (final agent in previewAgents) _agentTile(agent),
                if (agents.length > _previewLimit) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => _showAllAgentsDialog(context, agents),
                      child: Text(
                        'View All (${agents.length})',
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

  void _showAllAgentsDialog(BuildContext context, List<WazuhAgent> allAgents) {
    showDialog(
      context: context,
      builder: (context) {
        String filter = 'All';
        return StatefulBuilder(
          builder: (context, setState) {
            final filteredAgents = allAgents.where((a) {
              if (filter == 'Active') return a.active;
              if (filter == 'Inactive') return !a.active;
              return true;
            }).toList();

            return Dialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: 400,
                constraints: const BoxConstraints(maxHeight: 600),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'All Agents',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textMuted),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _filterChip('All', filter == 'All', () => setState(() => filter = 'All')),
                        const SizedBox(width: 8),
                        _filterChip('Active', filter == 'Active', () => setState(() => filter = 'Active')),
                        const SizedBox(width: 8),
                        _filterChip('Inactive', filter == 'Inactive', () => setState(() => filter = 'Inactive')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: filteredAgents.isEmpty
                          ? const Center(
                              child: Text('No agents match the filter.',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            )
                          : ListView.builder(
                              itemCount: filteredAgents.length,
                              itemBuilder: (context, index) {
                                return _agentTile(filteredAgents[index]);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.teal.withValues(alpha: 0.15) : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.teal : AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.teal : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Event evolution chart — derived from the most recent wazuh_events
  // ---------------------------------------------------------------------
  Widget _eventEvolutionCard() {
    return DashCard(
      child: StreamBuilder<List<WazuhEvent>>(
        stream: _eventRepository.watchEvents(limit: 17),
        builder: (context, snapshot) {
          final docs = snapshot.data ?? const [];
          final events = docs.reversed.toList();
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
                  _LegendDot(color: AppColors.red, label: 'Level 12+ (Critical)'),
                  _LegendDot(color: AppColors.orange, label: 'Level 8-11 (High)'),
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
      child: StreamBuilder<List<MitreTactic>>(
        stream: _mitreRepository.watchTactics(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final tactics = snapshot.data!;
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
                    'No tactic data yet.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
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
      child: StreamBuilder<List<WazuhEvent>>(
        stream: _eventRepository.watchEvents(limit: 100),
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
          final events = snapshot.data!;
          final uniqueEvents = _distinctBy(events, (WazuhEvent e) => e.id);
          final filteredEvents = uniqueEvents.where((e) {
            final severityLabel = _severityLabel(e.level);
            if (_selectedSeverity != 'All' &&
                severityLabel != _selectedSeverity) {
              return false;
            }
            if (_selectedAgent != 'All' && e.agent != _selectedAgent) {
              return false;
            }
            return true;
          }).toList();
          final previewEvents = filteredEvents.take(_previewLimit).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  const Text(
                    'Latest Security Events',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // Severity Filter
                      _buildFilterDropdown(
                        value: _selectedSeverity,
                        items: _severityFilters,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedSeverity = val);
                          }
                        },
                      ),
                      // Agent Filter
                      Builder(
                        builder: (context) {
                          final agentItems = {
                            'All',
                            if (_selectedAgent != 'All') _selectedAgent,
                            ..._distinctBy(uniqueEvents, (e) => e.agent)
                                .map((e) => e.agent)
                                .where((a) => a.isNotEmpty)
                          }.toList();
                          return _buildFilterDropdown(
                            value: _selectedAgent,
                            items: agentItems,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedAgent = val);
                              }
                            },
                          );
                        }
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (filteredEvents.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No events match the selected filters.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 560;
                    if (narrow) {
                      return _eventCardList(context, previewEvents);
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
            StatusBadge(label: '${event.level}', color: _levelColor(event.level)),
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
  String _severityLabel(int level) {
    if (level >= 12) return 'Critical';
    if (level >= 8) return 'High';
    if (level >= 4) return 'Medium';
    return 'Low';
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    double width = 150,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          underline: const SizedBox.shrink(),
          borderRadius: BorderRadius.circular(10),
          icon:
              const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          dropdownColor: AppColors.card,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
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


