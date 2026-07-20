import 'package:flutter/material.dart';
import '../../models/wazuh_event_model.dart';
import '../../services/wazuh_event_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class AccessIdentitiesContent extends StatelessWidget {
  final String? spokeId;

  const AccessIdentitiesContent({super.key, this.spokeId});

  @override
  Widget build(BuildContext context) {
    final repository = WazuhEventRepository();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Access & Identities',
            subtitle: 'Monitor login attempts, brute force attacks, and authentication events for this office.',
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<WazuhEvent>>(
            stream: repository.watchEvents(spokeId: spokeId, limit: 100),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return DashCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Failed to load events: ${snapshot.error}',
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

              // Filter for authentication-related events
              final authEvents = snapshot.data!.where((e) => 
                e.type == 'Login Attempt' || 
                e.type == 'Brute Force' ||
                e.type == 'Unauthorized Access' ||
                e.type == 'Windows Logon' ||
                e.type == 'Privilege Escalation'
              ).toList();

              if (authEvents.isEmpty) {
                return const DashCard(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No authentication events found for this office.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                );
              }

              return DashCard(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingTextStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                    columns: const [
                      DataColumn(label: Text('Timestamp')),
                      DataColumn(label: Text('Username')),
                      DataColumn(label: Text('Source IP')),
                      DataColumn(label: Text('Endpoint')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Raw Log')),
                    ],
                    rows: authEvents.map((event) {
                      String username = 'unknown';
                      String ip = 'unknown';
                      String status = 'Failed';

                      final desc = event.description.toLowerCase();
                      if (desc.contains('successful') || desc.contains('success') || desc.contains('accepted')) {
                        status = 'Success';
                      }

                      // Improved username extraction for various OS log formats
                      final userRegexes = [
                        RegExp(r"user '?([a-zA-Z0-9_\-\.]+)'?", caseSensitive: false),
                        RegExp(r"User name:\s*([a-zA-Z0-9_\-\.]+)", caseSensitive: false),
                        RegExp(r"Account Name:\s*([a-zA-Z0-9_\-\.]+)", caseSensitive: false),
                        RegExp(r"for (?:invalid user )?([a-zA-Z0-9_\-\.]+) from", caseSensitive: false),
                      ];

                      for (final regex in userRegexes) {
                        final match = regex.firstMatch(event.description);
                        if (match != null && match.groupCount >= 1) {
                          final extracted = match.group(1);
                          if (extracted != null && extracted.isNotEmpty && extracted.toLowerCase() != 'unknown') {
                            username = extracted;
                            break;
                          }
                        }
                      }
                      
                      if (username == 'unknown' && desc.contains('root')) {
                        username = 'root';
                      }

                      // Try to match IP
                      final ipMatch = RegExp(r"([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})").firstMatch(event.description);
                      if (ipMatch != null) {
                        ip = ipMatch.group(1) ?? 'unknown';
                      }

                      return DataRow(
                        onSelectChanged: (_) => _showEventDetails(context, event, username, ip, status),
                        cells: [
                        DataCell(Text(
                          _formatDate(event.timestamp),
                          style: const TextStyle(color: AppColors.textPrimary),
                        )),
                        DataCell(Text(
                          username,
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                        )),
                        DataCell(Text(
                          ip,
                          style: const TextStyle(color: AppColors.textPrimary),
                        )),
                        DataCell(Text(
                          event.endpoint.isEmpty ? event.agent : event.endpoint,
                          style: const TextStyle(color: AppColors.textPrimary),
                        )),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'Success' 
                                  ? AppColors.teal.withValues(alpha: 0.1)
                                  : AppColors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: status == 'Success'
                                    ? AppColors.teal.withValues(alpha: 0.3)
                                    : AppColors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: status == 'Success' ? AppColors.teal : AppColors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 300,
                            child: Text(
                              event.description,
                              style: const TextStyle(color: AppColors.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  void _showEventDetails(BuildContext context, WazuhEvent event, String username, String ip, String status) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Event Details',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.textSecondary, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _detailRow('Endpoint', event.endpoint.isEmpty ? event.agent : event.endpoint),
                _detailRow('Time', _formatDate(event.timestamp)),
                _detailRow('Username', username),
                _detailRow('Status', status, 
                    color: status == 'Success' ? AppColors.teal : AppColors.red),
                _detailRow('Source IP', ip),
                _detailRow('Severity', event.severity.isNotEmpty ? event.severity : 'Medium',
                    color: AppColors.severityColor(event.severity.isNotEmpty ? event.severity : 'Medium')),
                _detailRow('Rule Level', 'Level ${event.level}'),
                const SizedBox(height: 16),
                const Text('Full Description:',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    event.description,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  color: color ?? AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
