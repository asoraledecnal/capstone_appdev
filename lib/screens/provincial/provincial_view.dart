import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class ProvincialView extends StatefulWidget {
  const ProvincialView({super.key});

  @override
  State<ProvincialView> createState() => _ProvincialViewState();
}

class _ProvincialViewState extends State<ProvincialView> {
  final List<String> _tenants = const [
    'Laguna Provincial Office',
    'Cavite Provincial Office',
    'Rizal Provincial Office',
    'Quezon Provincial Office',
  ];
  late String _selectedTenant = _tenants.first;

  static const _events = [
    [
      '14:32:15',
      'LAGUNA-WS-012',
      'Login Attempt',
      'HIGH',
      'Multiple failed SSH login attempts (15 attempts in 2 minutes)',
      '192.168.10.45',
      'Block IP'
    ],
    [
      '14:28:03',
      'LAGUNA-SRV-03',
      'File Transfer',
      'MEDIUM',
      'Large file transfer to external IP (2.4GB to unknown destination)',
      '10.45.2.88',
      'Review Transfer'
    ],
    [
      '14:15:22',
      'LAGUNA-WS-007',
      'Suspicious Traffic',
      'LOW',
      'Unusual outbound traffic pattern detected on port 8080',
      '10.45.1.22',
      'Investigate'
    ],
    [
      '13:50:11',
      'LAGUNA-WS-019',
      'Unauthorized Access',
      'MEDIUM',
      'Attempted access to restricted directory /admin/config',
      '10.45.3.15',
      'Review Permissions'
    ],
    [
      '13:22:40',
      'LAGUNA-SRV-01',
      'File Download',
      'LOW',
      'Executable file downloaded from external source',
      '10.45.2.10',
      'Scan File'
    ],
  ];

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tenant dropdown trigger. Built on PopupMenuButton instead of a
          // hand-rolled Overlay/LayerLink so the menu's position is
          // computed by Flutter itself and always renders directly
          // attached under the button, regardless of screen width.
          ConstrainedBox(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
                  const SizedBox(height: 4),
                  const Text('Last sync: 2 minutes ago',
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
          LayoutBuilder(
            builder: (context, constraints) {
              final stats = [
                _statCard('ACTIVE ENDPOINTS', '24', Icons.check_circle_outline,
                    AppColors.teal),
                _statCard('TOTAL ENDPOINTS', '28', Icons.dns_outlined,
                    AppColors.textSecondary),
                _statCard('CRITICAL ALERTS', '0', Icons.shield_outlined,
                    AppColors.red),
                _statCard('HIGH PRIORITY', '1', Icons.warning_amber_outlined,
                    AppColors.orange),
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
                      if (i != stats.length - 1) const SizedBox(width: 16),
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
                  for (final s in stats) SizedBox(width: itemWidth, child: s),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          DashCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _TitleWithIcon(),
                    Text('Last updated: 2 minutes ago',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                    _RefreshLabel(),
                  ],
                ),
                const SizedBox(height: 8),
                // Wider minWidth + a heavier SEVERITY flex share gives every
                // column, especially the badge, enough breathing room on a
                // horizontal scroll so nothing wraps onto a second line or
                // gets clipped mid-word.
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
                    // ENDPOINT/EVENT TYPE/DESCRIPTION stay left-aligned since
                    // their text length varies a lot; the shorter,
                    // fixed-shape columns (TIME, badge, source IP, button)
                    // look neater centered in the extra column width.
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
                      for (final e in _events)
                        [
                          CellText(e[0], color: AppColors.textSecondary),
                          CellText(e[1], weight: FontWeight.w600),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_eventIcon(e[2]),
                                  size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Flexible(
                                  child: CellText(e[2],
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                          StatusBadge(
                              label: e[3],
                              color: AppColors.severityColor(e[3])),
                          CellText(e[4], color: AppColors.textSecondary),
                          CellText(e[5], color: AppColors.teal),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.teal),
                              foregroundColor: AppColors.teal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {},
                            child: Text(e[6],
                                style: const TextStyle(fontSize: 11)),
                          ),
                        ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Showing 5 recent security events. Critical events require immediate action.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
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
        Text('Refresh',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
