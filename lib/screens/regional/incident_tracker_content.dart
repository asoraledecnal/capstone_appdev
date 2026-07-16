import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/incident_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

/// The 5 CALABARZON provincial-office spokes seeded in
/// assets/firestore_schema_and_data.json (spokes collection).
const _spokeIds = ['SPOKE-01', 'SPOKE-02', 'SPOKE-03', 'SPOKE-04', 'SPOKE-05'];

const _heuristicRules = [
  'SSH Brute Force Threshold Exceeded (5 attempts/60s)',
  'Sequential SYN Port Scan Signature',
  'IPsec Tunnel Flap Threshold Breached',
  'DDoS Heuristic - Traffic Volume Spike',
  'Gateway Latency Deviation from Rolling Baseline',
  'Multiple Failed Auth Attempts - Same Source',
];

class IncidentTrackerContent extends StatefulWidget {
  const IncidentTrackerContent({super.key});

  @override
  State<IncidentTrackerContent> createState() => _IncidentTrackerContentState();
}

class _IncidentTrackerContentState extends State<IncidentTrackerContent> {
  final _incidents = FirebaseFirestore.instance.collection('incidents');
  bool _seeding = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Incident Tracker',
            subtitle:
                'Heuristic behavioral-analytics log — metadata only, RA 10173 compliant.',
            trailing: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: _seeding ? null : _seedDummyData,
                  icon: _seeding
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.dataset_outlined, size: 16),
                  label: Text(_seeding ? 'Seeding...' : 'Seed 50 Records'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showIncidentForm(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Incident'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          DashCard(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _incidents
                  .orderBy('timestamp', descending: true)
                  .limit(200)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Failed to load incidents: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.red),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No incident logs yet. Use "Seed 50 Records" for demo data, '
                        'or "New Incident" to add one manually.',
                        style: TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final logs = docs.map(IncidentLog.fromFirestore).toList();

                // An 8-column table (ID, spoke, alert type, severity, rule,
                // status, timestamp, actions) has no room to breathe below
                // this width — a horizontal scroll only ever shows a
                // partial slice of columns on a phone, which is what was
                // happening in practice. Below the breakpoint, switch to a
                // stacked card per incident instead: same fields, just laid
                // out vertically so nothing needs sideways scrolling to be
                // read in full.
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 760;
                    return narrow
                        ? _incidentCardList(context, logs)
                        : _incidentTable(logs);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _incidentTable(List<IncidentLog> logs) {
    return HScrollBox(
      minWidth: 900,
      child: SimpleTable(
        headers: const [
          'INCIDENT ID',
          'SPOKE',
          'ALERT TYPE',
          'SEVERITY',
          'HEURISTIC RULE',
          'STATUS',
          'DETECTED',
          '',
        ],
        flex: const [2, 1, 2, 1, 3, 2, 2, 1],
        rows: [
          for (final log in logs)
            [
              CellText(log.id, color: AppColors.teal, weight: FontWeight.w600),
              CellText(log.spokeId, color: AppColors.textSecondary),
              CellText(log.alertType),
              Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  label: log.severity.toUpperCase(),
                  color: AppColors.severityColor(log.severity),
                ),
              ),
              CellText(log.heuristicRule,
                  color: AppColors.textSecondary, size: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  label: log.ticketStatus.toUpperCase(),
                  color: _statusColor(log.ticketStatus),
                  outlined: false,
                ),
              ),
              CellText(_formatTimestamp(log.timestamp),
                  color: AppColors.textSecondary, size: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit_outlined,
                        size: 16, color: AppColors.textSecondary),
                    onPressed: () => _showIncidentForm(context, existing: log),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: AppColors.red),
                    onPressed: () => _confirmDelete(context, log),
                  ),
                ],
              ),
            ],
        ],
      ),
    );
  }

  /// Mobile-width replacement for the 8-column table: one card per
  /// incident carrying the exact same fields (ID, spoke, alert type,
  /// severity, heuristic rule, status, detected time, edit/delete), just
  /// arranged top-to-bottom instead of squeezed side-to-side.
  Widget _incidentCardList(BuildContext context, List<IncidentLog> logs) {
    return Column(
      children: [
        for (final log in logs)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: incident ID + severity/status badges + actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        log.id,
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.edit_outlined,
                          size: 16, color: AppColors.textSecondary),
                      onPressed: () =>
                          _showIncidentForm(context, existing: log),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'Delete',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.delete_outline,
                          size: 16, color: AppColors.red),
                      onPressed: () => _confirmDelete(context, log),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Row 2: alert type (main content, wraps freely)
                Text(
                  log.alertType,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                // Row 3: heuristic rule that triggered it
                Text(
                  log.heuristicRule,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                // Row 4: severity + status badges, side by side
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusBadge(
                      label: log.severity.toUpperCase(),
                      color: AppColors.severityColor(log.severity),
                    ),
                    StatusBadge(
                      label: log.ticketStatus.toUpperCase(),
                      color: _statusColor(log.ticketStatus),
                      outlined: false,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.cardBorder),
                const SizedBox(height: 10),
                // Row 5: spoke + detected timestamp as small meta chips
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _metaChip(Icons.dns_outlined, log.spokeId, AppColors.teal),
                    _metaChip(Icons.access_time,
                        _formatTimestamp(log.timestamp), AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _metaChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11.5)),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Open':
        return AppColors.red;
      case 'Investigating':
        return AppColors.orange;
      case 'Mitigated':
        return AppColors.blue;
      case 'Resolved':
        return AppColors.green;
      default:
        return AppColors.textMuted;
    }
  }

  String _formatTimestamp(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<void> _confirmDelete(BuildContext context, IncidentLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete incident?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'This will permanently remove ${log.id} from the log.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _incidents.doc(log.id).delete();
    }
  }

  Future<void> _showIncidentForm(
    BuildContext context, {
    IncidentLog? existing,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => _IncidentFormDialog(
        existing: existing,
        onSubmit: (log) async {
          if (existing == null) {
            final id = _generateIncidentId();
            await _incidents.doc(id).set(log.toFirestore());
          } else {
            await _incidents.doc(existing.id).update(log.toFirestore());
          }
        },
      ),
    );
  }

  /// Generates an INC-YYYYMMDD-XXX id, matching the format documented in
  /// assets/firestore_schema_and_data.json.
  String _generateIncidentId() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final datePart = '${now.year}${two(now.month)}${two(now.day)}';
    final suffix = (Random().nextInt(900) + 100); // 100-999
    return 'INC-$datePart-$suffix';
  }

  /// TEMPORARY: injects 50 dummy heuristic incident records via a single
  /// WriteBatch. Intended for populating demo data during development /
  /// grading walkthroughs — remove or gate behind a debug flag before any
  /// production-style deployment.
  Future<void> _seedDummyData() async {
    setState(() => _seeding = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final rand = Random();
      final now = DateTime.now();

      for (int i = 0; i < 50; i++) {
        final ts = now.subtract(Duration(minutes: rand.nextInt(60 * 24 * 7)));
        String two(int n) => n.toString().padLeft(2, '0');
        final datePart = '${ts.year}${two(ts.month)}${two(ts.day)}';
        final id = 'INC-$datePart-${(i + 1).toString().padLeft(3, '0')}';

        final log = IncidentLog(
          id: id,
          spokeId: _spokeIds[rand.nextInt(_spokeIds.length)],
          timestamp: ts,
          alertType: IncidentLog
              .alertTypes[rand.nextInt(IncidentLog.alertTypes.length)],
          severity: IncidentLog
              .severities[rand.nextInt(IncidentLog.severities.length)],
          heuristicRule: _heuristicRules[rand.nextInt(_heuristicRules.length)],
          ticketStatus: IncidentLog
              .ticketStatuses[rand.nextInt(IncidentLog.ticketStatuses.length)],
        );

        batch.set(_incidents.doc(id), log.toFirestore());
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seeded 50 dummy incident records.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seeding failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }
}

/// Create/update form shown in a dialog. Handles both flows: when
/// [existing] is null this creates a new incident; otherwise it edits it.
class _IncidentFormDialog extends StatefulWidget {
  final IncidentLog? existing;
  final Future<void> Function(IncidentLog log) onSubmit;

  const _IncidentFormDialog({required this.existing, required this.onSubmit});

  @override
  State<_IncidentFormDialog> createState() => _IncidentFormDialogState();
}

class _IncidentFormDialogState extends State<_IncidentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _spokeId;
  late String _alertType;
  late String _severity;
  late String _ticketStatus;
  late final TextEditingController _ruleController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _spokeId = e?.spokeId ?? _spokeIds.first;
    _alertType = e?.alertType ?? IncidentLog.alertTypes.first;
    _severity = e?.severity ?? IncidentLog.severities.first;
    _ticketStatus = e?.ticketStatus ?? IncidentLog.ticketStatuses.first;
    _ruleController = TextEditingController(text: e?.heuristicRule ?? '');
  }

  @override
  void dispose() {
    _ruleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(
        isEdit ? 'Edit Incident — ${widget.existing!.id}' : 'New Incident',
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dropdown('Spoke', _spokeId, _spokeIds,
                  (v) => setState(() => _spokeId = v!)),
              const SizedBox(height: 14),
              _dropdown('Alert Type', _alertType, IncidentLog.alertTypes,
                  (v) => setState(() => _alertType = v!)),
              const SizedBox(height: 14),
              _dropdown('Severity', _severity, IncidentLog.severities,
                  (v) => setState(() => _severity = v!)),
              const SizedBox(height: 14),
              _dropdown(
                  'Ticket Status',
                  _ticketStatus,
                  IncidentLog.ticketStatuses,
                  (v) => setState(() => _ticketStatus = v!)),
              const SizedBox(height: 14),
              TextFormField(
                controller: _ruleController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Heuristic Rule',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.teal),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.black,
          ),
          child: Text(_saving ? 'Saving...' : (isEdit ? 'Save' : 'Create')),
        ),
      ],
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: AppColors.card,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.teal),
        ),
      ),
      items: [
        for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
      ],
      onChanged: onChanged,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final log = IncidentLog(
      id: widget.existing?.id ?? '',
      spokeId: _spokeId,
      timestamp: widget.existing?.timestamp ?? DateTime.now(),
      alertType: _alertType,
      severity: _severity,
      heuristicRule: _ruleController.text.trim(),
      ticketStatus: _ticketStatus,
    );
    try {
      await widget.onSubmit(log);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }
}
