import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class RegulatoryComplianceContent extends StatelessWidget {
  const RegulatoryComplianceContent({super.key});

  @override
  Widget build(BuildContext context) {
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
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _complianceCard(
                  icon: Icons.fact_check_outlined,
                  title: 'CIS Benchmark',
                  percent: 0.82,
                  passed: 1450,
                  failed: 318,
                ),
                _complianceCard(
                  icon: Icons.shield_outlined,
                  title: 'PCI DSS',
                  percent: 0.95,
                  passed: 890,
                  failed: 46,
                ),
                _complianceCard(
                  icon: Icons.donut_small_outlined,
                  title: 'NIST 800-53',
                  percent: 0.76,
                  passed: 2100,
                  failed: 660,
                ),
              ];

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
          ),
        ],
      ),
    );
  }

  Widget _complianceCard({
    required IconData icon,
    required String title,
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
                        fontSize: 14)),
              ),
              Text('${(percent * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ],
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
