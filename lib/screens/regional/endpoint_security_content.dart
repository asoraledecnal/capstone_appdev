import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/wazuh_agent_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

/// Full agent inventory. Reads from the same `wazuh_agents` collection as
/// the Overview dashboard's "Agent Status" panel — same records, just
/// showing every field instead of a quick status summary. Use Overview's
/// "Seed Demo Data" button to populate this collection if it's empty.
class EndpointSecurityContent extends StatelessWidget {
  const EndpointSecurityContent({super.key});

  @override
  Widget build(BuildContext context) {
    final agentsRef = FirebaseFirestore.instance.collection('wazuh_agents');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Endpoint Security',
            subtitle:
                'Manage and monitor all registered agents across Region 4A.',
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: agentsRef.orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return DashCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Failed to load agents: ${snapshot.error}',
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
              final agents =
                  snapshot.data!.docs.map(WazuhAgent.fromFirestore).toList();

              if (agents.isEmpty) {
                return const DashCard(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No agents yet. Go to Overview and use '
                        '"Seed Demo Data", or add agents from your Wazuh '
                        'pipeline.',
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
                  // A 6-column table (name, id, ip, os, version, status)
                  // needs real width to stay readable — below this
                  // breakpoint a horizontal-scroll table only ever shows a
                  // partial slice of columns on a phone. Cards show every
                  // field for an agent at once, just by scrolling down
                  // like the rest of the page.
                  final narrow = constraints.maxWidth < 720;
                  if (narrow) {
                    return _agentCardList(agents);
                  }
                  return DashCard(
                    child: HScrollBox(
                      minWidth: 680,
                      child: SimpleTable(
                        headers: const [
                          'AGENT NAME',
                          'ID',
                          'IP ADDRESS',
                          'OS/VERSION',
                          'VERSION',
                          'STATUS'
                        ],
                        flex: const [3, 1, 2, 3, 2, 2],
                        rows: [
                          for (final a in agents)
                            [
                              CellText(a.name, weight: FontWeight.w600),
                              CellText(a.agentId,
                                  color: AppColors.textSecondary),
                              CellText(a.ip, color: AppColors.teal),
                              CellText(a.os, color: AppColors.textSecondary),
                              CellText(a.version,
                                  color: AppColors.textSecondary),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: StatusBadge(
                                  label: a.active ? 'ACTIVE' : 'INACTIVE',
                                  color: a.active
                                      ? AppColors.teal
                                      : AppColors.red,
                                ),
                              ),
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

  /// Mobile-width replacement for the agent table: one card per agent with
  /// every field (ID, IP, OS/version, agent version, status) laid out and
  /// fully visible, no sideways scrolling required.
  Widget _agentCardList(List<WazuhAgent> agents) {
    return Column(
      children: [
        for (final a in agents) _agentCard(a),
      ],
    );
  }

  Widget _agentCard(WazuhAgent a) {
    final active = a.active;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? AppColors.cardBorder
              : AppColors.red.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.dns_outlined,
                  size: 16, color: active ? AppColors.teal : AppColors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  a.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: active ? 'ACTIVE' : 'INACTIVE',
                color: active ? AppColors.teal : AppColors.red,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _fieldRow('ID', a.agentId),
          _fieldRow('IP ADDRESS', a.ip, valueColor: AppColors.teal),
          _fieldRow('OS / VERSION', a.os),
          _fieldRow('AGENT VERSION', a.version),
        ],
      ),
    );
  }

  Widget _fieldRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
