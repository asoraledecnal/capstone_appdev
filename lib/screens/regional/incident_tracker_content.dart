import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../models/incident_model.dart';

class IncidentTrackerContent extends StatefulWidget {
  const IncidentTrackerContent({super.key});

  @override
  State<IncidentTrackerContent> createState() => _IncidentTrackerContentState();
}

class _IncidentTrackerContentState extends State<IncidentTrackerContent> {
  // Database Reference
  final CollectionReference _incidents = FirebaseFirestore.instance.collection('incidents');

  // Controllers para sa Form
  final TextEditingController _spokeCtrl = TextEditingController();
  final TextEditingController _alertTypeCtrl = TextEditingController();
  final TextEditingController _ruleCtrl = TextEditingController();
  String _severity = 'HIGH';
  String _status = 'OPEN';

  // Modal Dialog para sa Create at Update (IT 332 Requirement)
  Future<void> _showIncidentForm([IncidentLog? incident]) async {
    if (incident != null) {
      _spokeCtrl.text = incident.spokeId;
      _alertTypeCtrl.text = incident.alertType;
      _ruleCtrl.text = incident.heuristicRule;
      _severity = incident.severity;
      _status = incident.ticketStatus;
    } else {
      _spokeCtrl.clear();
      _alertTypeCtrl.clear();
      _ruleCtrl.clear();
      _severity = 'HIGH';
      _status = 'OPEN';
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          incident == null ? 'Log New Threat (Manual)' : 'Update Ticket Status',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _spokeCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Spoke ID (e.g., SPK-LAG-01)'),
              ),
              TextField(
                controller: _alertTypeCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Alert Type (e.g., Port Scan)'),
              ),
              TextField(
                controller: _ruleCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Heuristic Rule Triggered'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _severity,
                dropdownColor: AppColors.panelDark,
                style: const TextStyle(color: AppColors.textPrimary),
                items: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => _severity = val!),
                decoration: const InputDecoration(labelText: 'Severity'),
              ),
              DropdownButtonFormField<String>(
                value: _status,
                dropdownColor: AppColors.panelDark,
                style: const TextStyle(color: AppColors.textPrimary),
                items: ['OPEN', 'IN PROGRESS', 'RESOLVED']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => _status = val!),
                decoration: const InputDecoration(labelText: 'Ticket Status'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: () async {
              final data = {
                'spoke_id': _spokeCtrl.text,
                'alert_type': _alertTypeCtrl.text,
                'heuristic_rule': _ruleCtrl.text,
                'severity': _severity,
                'ticket_status': _status,
                'timestamp': incident == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(incident.timestamp),
              };

              if (incident == null) {
                // CREATE Operation
                await _incidents.add(data);
              } else {
                // UPDATE Operation
                await _incidents.doc(incident.id).update(data);
              }
              if (mounted) Navigator.pop(context);
            },
            child: Text(incident == null ? 'Create Log' : 'Update Log', style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // DELETE Operation
  Future<void> _deleteIncident(String id) async {
    await _incidents.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Incident Tracker (CRUD)',
            subtitle: 'Manual heuristic threat logging and ticket management across all Spokes.',
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
              onPressed: () => _showIncidentForm(),
              icon: const Icon(Icons.add, color: Colors.black, size: 18),
              label: const Text('Log Incident', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
          DashCard(
            child: StreamBuilder<QuerySnapshot>(
              stream: _incidents.orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.teal));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No heuristic alerts logged yet.', style: TextStyle(color: AppColors.textMuted)),
                    ),
                  );
                }

                // Map Firestore Documents to IncidentLog Model
                final logs = snapshot.data!.docs.map((doc) => IncidentLog.fromFirestore(doc)).toList();

                // READ Operation rendered in SimpleTable
                return HScrollBox(
                  minWidth: 800,
                  child: SimpleTable(
                    headers: const ['TIMESTAMP', 'SPOKE ID', 'ALERT TYPE', 'SEVERITY', 'STATUS', 'ACTIONS'],
                    flex: const [2, 2, 3, 2, 2, 2],
                    rows: logs.map((log) {
                      return [
                        CellText(log.timestamp.toString().split('.')[0], color: AppColors.textSecondary, size: 11),
                        CellText(log.spokeId, weight: FontWeight.w600),
                        CellText(log.alertType, color: AppColors.textSecondary),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: StatusBadge(
                            label: log.severity,
                            color: AppColors.severityColor(log.severity),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: StatusBadge(
                            label: log.ticketStatus,
                            color: log.ticketStatus == 'RESOLVED' ? AppColors.green : AppColors.teal,
                            outlined: false,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.blue),
                              onPressed: () => _showIncidentForm(log), // Call Update
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.red),
                              onPressed: () => _deleteIncident(log.id), // Call Delete
                            ),
                          ],
                        ),
                      ];
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}