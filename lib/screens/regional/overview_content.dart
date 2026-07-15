import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class OverviewContent extends StatelessWidget {
  const OverviewContent({super.key});

  static const _agents = [
    {'name': 'cavite-po-agent', 'ip': '10.0.1.5', 'active': true},
    {'name': 'laguna-po-agent', 'ip': '10.0.2.10', 'active': true},
    {'name': 'quezon-po-agent', 'ip': '10.0.4.22', 'active': true},
    {'name': 'rizal-po-agent', 'ip': '10.0.3.15', 'active': false},
  ];

  static const _tactics = [
    {'name': 'Initial Access', 'value': 0.55, 'color': AppColors.orange},
    {'name': 'Execution', 'value': 0.18, 'color': AppColors.teal},
    {'name': 'Persistence', 'value': 0.45, 'color': AppColors.orange},
    {'name': 'Privilege Esc.', 'value': 0.12, 'color': AppColors.red},
    {'name': 'Defense\nEvasion', 'value': 0.68, 'color': AppColors.red},
    {'name': 'Credential\nAccess', 'value': 0.4, 'color': AppColors.orange},
    {'name': 'Discovery', 'value': 0.6, 'color': AppColors.teal},
  ];

  static const _events = [
    [
      '10:42:01',
      'laguna-agent-01',
      '5710',
      '12',
      'sshd: Attempt to login using a non-existent user',
      AppColors.red
    ],
    [
      '10:41:55',
      'cavite-fw-01',
      '4101',
      '8',
      'Firewall dropped connection from malicious IP',
      AppColors.orange
    ],
    [
      '10:40:12',
      'rizal-svr-02',
      '1002',
      '4',
      'Unknown problem somewhere in the system',
      AppColors.teal
    ],
    [
      '10:39:05',
      'batangas-hub',
      '31151',
      '10',
      'Mutiple web server 400 error codes from same IP',
      AppColors.orange
    ],
  ];

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
                    _eventStreamCard(),
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 4, child: _mitreCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 7, child: _eventStreamCard()),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _agentStatusCard() {
    return DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Agent Status',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              StatusBadge(
                  label: 'Total: 4',
                  color: AppColors.textSecondary,
                  outlined: false),
            ],
          ),
          const SizedBox(height: 14),
          for (final agent in _agents) _agentTile(agent),
        ],
      ),
    );
  }

  Widget _agentTile(Map<String, Object> agent) {
    final active = agent['active'] as bool;
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
                Text(agent['name'] as String,
                    style: TextStyle(
                      color: active ? AppColors.textPrimary : AppColors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    )),
                Text(agent['ip'] as String,
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

  Widget _eventEvolutionCard() {
    return DashCard(
      child: Column(
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
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 20,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (v) =>
                      const FlLine(color: AppColors.cardBorder, strokeWidth: 1),
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
                    spots: const [
                      FlSpot(0, 18),
                      FlSpot(1, 15),
                      FlSpot(2, 11),
                      FlSpot(3, 12),
                      FlSpot(4, 6),
                      FlSpot(5, 8),
                      FlSpot(6, 16),
                      FlSpot(7, 13),
                      FlSpot(8, 8),
                      FlSpot(9, 10),
                      FlSpot(10, 11),
                      FlSpot(11, 12),
                      FlSpot(12, 15),
                      FlSpot(13, 18),
                      FlSpot(14, 14),
                      FlSpot(15, 17),
                      FlSpot(16, 9),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mitreCard() {
    return DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MITRE ATT&CK Tactics',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 16),
          for (final t in _tactics) _tacticBar(t),
        ],
      ),
    );
  }

  Widget _tacticBar(Map<String, Object> t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              t['name'] as String,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11.5),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: t['value'] as double,
                minHeight: 8,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation(t['color'] as Color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventStreamCard() {
    return DashCard(
      child: Column(
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
          const SizedBox(height: 8),
          HScrollBox(
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
              rows: [
                for (final e in _events)
                  [
                    CellText(e[0] as String, color: AppColors.textSecondary),
                    CellText(e[1] as String, color: AppColors.teal),
                    CellText(e[2] as String, color: AppColors.teal),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 26,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: e[5] as Color,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(e[3] as String,
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                      ),
                    ),
                    CellText(e[4] as String, color: AppColors.textSecondary),
                  ],
              ],
            ),
          ),
        ],
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
