import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class ProvincialReportsContent extends StatelessWidget {
  final String? spokeId;

  const ProvincialReportsContent({super.key, this.spokeId});

  @override
  Widget build(BuildContext context) {
    final reports = [
      {
        'title': 'Weekly Security Summary',
        'desc': 'A high-level overview of all alerts and endpoint statuses over the past 7 days.',
        'icon': Icons.security,
      },
      {
        'title': 'Failed Login Audit',
        'desc': 'Detailed log of all failed authentication attempts and brute force blocks.',
        'icon': Icons.badge,
      },
      {
        'title': 'Endpoint Compliance Report',
        'desc': 'List of all Wazuh agents missing critical updates or security patches.',
        'icon': Icons.computer,
      },
      {
        'title': 'Resolved Incidents Report',
        'desc': 'Summary of all security incidents marked as Resolved by the local IT team.',
        'icon': Icons.check_circle_outline,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Provincial Reports',
            subtitle: 'Generate and download security and compliance reports for this provincial office.',
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: reports.map((report) {
                  final colCount = constraints.maxWidth < 600 ? 1 : constraints.maxWidth > 1200 ? 3 : 2;
                  final spacing = (colCount - 1) * 16.0;
                  final cardWidth = (constraints.maxWidth - spacing) / colCount;
                  return SizedBox(
                    width: cardWidth,
                    child: _ReportCard(
                      title: report['title'] as String,
                      description: report['desc'] as String,
                      icon: report['icon'] as IconData,
                      onDownload: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Generating ${report['title']} for $spokeId... (Demo)'),
                            backgroundColor: AppColors.teal,
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onDownload;

  const _ReportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return DashCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.teal, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              description,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Download PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.teal,
                  side: const BorderSide(color: AppColors.teal),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
