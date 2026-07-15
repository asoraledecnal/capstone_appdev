import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class FileIntegrityContent extends StatelessWidget {
  const FileIntegrityContent({super.key});

  static const _events = [
    ['11:22:04', 'rizal-po-agent', r'C:\Windows\System32\drivers\etc\hosts', 'MODIFIED'],
    ['11:15:30', 'cavite-po-agent', '/etc/passwd', 'MODIFIED'],
    ['10:50:12', 'laguna-po-agent', '/var/www/html/backdoor.php', 'ADDED'],
    ['09:40:00', 'batangas-hub', '/etc/nginx/nginx.conf', 'MODIFIED'],
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'File Integrity Monitoring',
            subtitle: 'Real-time alerts for modified, created, or deleted files across all agents.',
          ),
          const SizedBox(height: 20),
          DashCard(
            child: HScrollBox(
              minWidth: 640,
              child: SimpleTable(
                headers: const ['TIMESTAMP', 'AGENT', 'FILE PATH', 'ACTION', 'DETAILS'],
                flex: const [2, 2, 4, 2, 1],
                rows: [
                  for (final e in _events)
                    [
                      CellText(e[0], color: AppColors.textSecondary),
                      CellText(e[1], weight: FontWeight.w600),
                      CellText(e[2], color: AppColors.textSecondary),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: StatusBadge(
                          label: e[3],
                          color: e[3] == 'ADDED' ? AppColors.red : AppColors.orange,
                        ),
                      ),
                      const Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
