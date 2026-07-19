import 'package:flutter/material.dart';
import '../../models/compliance_record_model.dart';
import '../../services/compliance_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class RegulatoryComplianceContent extends StatelessWidget {
  const RegulatoryComplianceContent({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = ComplianceRepository();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Regulatory Compliance',
            subtitle:
                'Agent status against established frameworks (CIS, PCI DSS, NIST).',
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<ComplianceRecord>>(
            stream: repository.watchRecords(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return DashCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Failed to load compliance data: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.red)),
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
              final records = snapshot.data!;
              if (records.isEmpty) {
                return const DashCard(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No compliance records yet.',
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
                  final cards = records.map((r) {
                    IconData icon;
                    String description = '';
                    if (r.framework.contains('NIST')) {
                      icon = Icons.security_outlined;
                      description = 'National Institute of Standards and Technology. Framework for improving critical infrastructure cybersecurity.';
                    } else if (r.framework.contains('HIPAA')) {
                      icon = Icons.medical_services_outlined;
                      description = 'Health Insurance Portability and Accountability Act. Security standards for protecting sensitive data.';
                    } else if (r.framework.contains('PCI')) {
                      icon = Icons.credit_card_outlined;
                      description = 'Payment Card Industry Data Security Standard. Ensures secure processing of card information.';
                    } else if (r.framework.contains('ISO')) {
                      icon = Icons.verified_user_outlined;
                      description = 'International standard for managing information security (ISMS).';
                    } else {
                      icon = Icons.fact_check_outlined;
                      description = 'Standardized security benchmarks and best practices.';
                    }
                    
                    return _complianceCard(
                      icon: icon,
                      title: r.framework,
                      description: description,
                      percent: r.percent,
                      passed: r.passed,
                      failed: r.failed,
                    );
                  }).toList();

              if (constraints.maxWidth < 560) {
                // Stack one per row on phones.
                return Column(
                  children: [
                    for (final c in cards) ...[c, const SizedBox(height: 16)],
                  ],
                );
              }
              if (constraints.maxWidth < 900) {
                // Two columns on tablets/small landscape.
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final c in cards)
                      SizedBox(
                        width: (constraints.maxWidth - 16) / 2,
                        child: c,
                      ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    Expanded(child: cards[i]),
                    if (i != cards.length - 1) const SizedBox(width: 16),
                  ],
                ],
              );
            },
          );
        },
      ),
        ],
      ),
    );
  }


  Widget _complianceCard({
    required IconData icon,
    required String title,
    required String description,
    required double percent,
    required int passed,
    required int failed,
  }) {
    return DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: AppColors.teal),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
              Text('${percent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation(AppColors.teal),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PASSED',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  Text('$passed',
                      style: const TextStyle(
                          color: AppColors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('FAILED',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  Text('$failed',
                      style: const TextStyle(
                          color: AppColors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
