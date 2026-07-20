import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../theme/app_colors.dart';
import '../../services/report_generator.dart';
import '../../widgets/common.dart';
import '../../widgets/provincial_sidebar.dart';

class ProvincialReportsContent extends StatelessWidget {
  final String? spokeId;

  const ProvincialReportsContent({super.key, this.spokeId});

  String get _spokeName {
    const names = ProvincialSidebar.tenantNames;
    return names[spokeId ?? 'SPOKE-01'] ?? spokeId ?? 'Provincial Office';
  }

  @override
  Widget build(BuildContext context) {
    final generator = ReportGenerator(
      spokeId: spokeId ?? 'SPOKE-01',
      spokeName: _spokeName,
    );

    final reports = [
      _ReportDef(
        title: 'Weekly Security Summary',
        description:
            'High-level overview of all alerts and incident statuses over the past 7 days.',
        icon: Icons.security_outlined,
        generate: generator.generateWeeklySummary,
        filename: 'weekly_security_summary',
      ),
      _ReportDef(
        title: 'Failed Login Audit',
        description:
            'Log of all failed authentication attempts and suspicious auth events.',
        icon: Icons.badge_outlined,
        generate: generator.generateFailedLoginAudit,
        filename: 'failed_login_audit',
      ),
      _ReportDef(
        title: 'Endpoint Compliance Report',
        description:
            'All Wazuh agents with their status, OS, and compliance framework scores.',
        icon: Icons.computer_outlined,
        generate: generator.generateEndpointCompliance,
        filename: 'endpoint_compliance',
      ),
      _ReportDef(
        title: 'Resolved Incidents Report',
        description:
            'All security incidents marked as Resolved or Mitigated by the local IT team.',
        icon: Icons.check_circle_outline,
        generate: generator.generateResolvedIncidents,
        filename: 'resolved_incidents',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Provincial Reports',
            subtitle:
                'Generate and download security and compliance reports for this provincial office.',
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final colCount = constraints.maxWidth < 600
                  ? 1
                  : constraints.maxWidth > 1200
                      ? 3
                      : 2;
              final spacing = (colCount - 1) * 16.0;
              final cardWidth = (constraints.maxWidth - spacing) / colCount;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: reports.map((r) {
                  return SizedBox(
                    width: cardWidth,
                    child: _ReportCard(
                      title: r.title,
                      description: r.description,
                      icon: r.icon,
                      filename: '${r.filename}_${spokeId ?? 'spoke'}',
                      generate: r.generate,
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

class _ReportDef {
  final String title;
  final String description;
  final IconData icon;
  final Future<Uint8List> Function() generate;
  final String filename;

  const _ReportDef({
    required this.title,
    required this.description,
    required this.icon,
    required this.generate,
    required this.filename,
  });
}

class _ReportCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final String filename;
  final Future<Uint8List> Function() generate;

  const _ReportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.filename,
    required this.generate,
  });

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _loading = false;

  Future<void> _onDownload() async {
    setState(() => _loading = true);
    try {
      final bytes = await widget.generate();
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${widget.filename}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.3)),
                  ),
                  child: Icon(widget.icon, color: AppColors.teal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.description,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _onDownload,
                icon: _loading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.download_rounded, size: 16),
                label: Text(_loading ? 'Generating...' : 'Download PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor:
                      AppColors.teal.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
