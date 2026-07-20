

import 'package:flutter/material.dart';

import '../../models/incident_model.dart';
import '../../services/incident_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

/// The 5 CALABARZON provincial-office spokes seeded in
/// assets/firestore_schema_and_data.json (spokes collection).
const _spokeIds = ['SPOKE-01', 'SPOKE-02', 'SPOKE-03', 'SPOKE-04', 'SPOKE-05'];

const _previewLimit = 5;

class IncidentTrackerContent extends StatefulWidget {
  final String? spokeId;
  const IncidentTrackerContent({super.key, this.spokeId});

  @override
  State<IncidentTrackerContent> createState() => _IncidentTrackerContentState();
}

class _IncidentTrackerContentState extends State<IncidentTrackerContent> {
  final _repository = IncidentRepository();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppColors.teal,
      backgroundColor: AppColors.card,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Incident Tracker',
              subtitle:
                  'Heuristic behavioral-analytics log — metadata only, RA 10173 compliant.',
              trailing: ElevatedButton.icon(
                onPressed: () => _showIncidentForm(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Incident'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          const SizedBox(height: 20),
          DashCard(
            child: StreamBuilder<List<IncidentLog>>(
              stream: _repository.watchIncidents(spokeId: widget.spokeId),
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
                final logs = snapshot.data!;
                if (logs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No incident logs yet. '
                        'Use "New Incident" to add one manually.',
                        style: TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final previewLogs = logs.take(_previewLimit).toList();
                final hasMore = logs.length > _previewLimit;

                // An 8-column table (ID, spoke, alert type, severity, rule,
                // status, timestamp, actions) has no room to breathe below
                // this width — a horizontal scroll only ever shows a
                // partial slice of columns on a phone, which is what was
                // happening in practice. Below the breakpoint, switch to a
                // stacked card per incident instead: same fields, just laid
                // out vertically so nothing needs sideways scrolling to be
                // read in full.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 760;
                        return narrow
                            ? _incidentCardList(context, previewLogs)
                            : _incidentTable(previewLogs);
                      },
                    ),
                    if (hasMore)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showAllIncidentsSheet(context, logs),
                            icon: const Icon(Icons.unfold_more,
                                size: 16, color: AppColors.teal),
                            label: const Text('View All Incidents',
                                style: TextStyle(color: AppColors.teal)),
                            style: OutlinedButton.styleFrom(
                              side:
                                  const BorderSide(color: AppColors.cardBorder),
                              foregroundColor: AppColors.teal,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ));
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
              CellText(_formatSpoke(log.spokeId), color: AppColors.textSecondary),
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
        onRowTap: [
          for (final log in logs) () => _showIncidentForm(context, existing: log),
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
                    _metaChip(Icons.dns_outlined, _formatSpoke(log.spokeId), AppColors.teal),
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
    switch (status.toLowerCase()) {
      case 'open':
        return AppColors.red;
      case 'investigating':
        return AppColors.orange;
      case 'mitigated':
        return AppColors.blue;
      case 'resolved':
        return AppColors.green;
      default:
        return AppColors.textMuted;
    }
  }

  String _formatTimestamp(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _formatSpoke(String spokeId) {
    const map = {
      'SPOKE-01': 'Cavite',
      'SPOKE-02': 'Laguna',
      'SPOKE-03': 'Batangas',
      'SPOKE-04': 'Rizal',
      'SPOKE-05': 'Quezon',
    };
    return map[spokeId] ?? spokeId;
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
      await _repository.deleteIncident(log.id);
    }
  }

  void _showAllIncidentsSheet(BuildContext context, List<IncidentLog> logs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                                AppColors.teal.withAlpha((0.12 * 255).round()),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.list,
                              size: 18, color: AppColors.teal),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('All Incidents',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return _incidentCardListItem(context, log);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _incidentCardListItem(BuildContext context, IncidentLog log) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showIncidentForm(context, existing: log),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        log.id,
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    StatusBadge(
                      label: log.severity.toUpperCase(),
                      color: AppColors.severityColor(log.severity),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  log.alertType,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  log.heuristicRule,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    _metaChip(Icons.dns_outlined, _formatSpoke(log.spokeId), AppColors.teal),
                    _metaChip(Icons.access_time,
                        _formatTimestamp(log.timestamp), AppColors.textMuted),
                    _metaChip(Icons.flag_outlined, log.ticketStatus,
                        AppColors.orange),
                  ],
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Text('Tap to edit',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
            // Use Firestore's auto-generated doc ID to guarantee uniqueness.
            // The previous random 3-digit suffix caused collision risk.
            await _repository.createIncident(log.toFirestore());
          } else {
            await _repository.updateIncident(existing.id, log.toFirestore());
          }
        },
      ),
    );
  }

  // _generateIncidentId() removed — Firestore auto-IDs are used instead
  // to prevent the birthday-paradox collision risk from a 3-digit suffix.
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

  List<String> _ensureIncludes(List<String> options, String value) {
    if (value.isNotEmpty && !options.contains(value)) {
      return [...options, value];
    }
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    // Reactive to the keyboard: MediaQuery rebuilds this widget whenever
    // viewInsets.bottom changes (keyboard opening/closing), so this
    // recalculates the moment the keyboard shows instead of using a fixed
    // percentage of the FULL screen height.
    final mq = MediaQuery.of(context);
    final keyboardHeight = mq.viewInsets.bottom;
    final availableHeight =
        mq.size.height - keyboardHeight - mq.padding.top - mq.padding.bottom;
    // Reserve room for the dialog's title, action buttons, dialog padding,
    // and its own inset margins — roughly 180px — then give the rest to
    // the scrollable field list, with a sane floor/ceiling.
    final maxDialogContentHeight =
        (availableHeight - 180).clamp(120.0, double.infinity);

    return AlertDialog(
      backgroundColor: AppColors.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Text(
        isEdit ? 'Edit Incident — ${widget.existing!.id}' : 'New Incident',
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxDialogContentHeight),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dropdown('Spoke', _spokeId, _ensureIncludes(_spokeIds, _spokeId),
                      (v) => setState(() => _spokeId = v!)),
                  const SizedBox(height: 14),
                  _dropdown('Alert Type', _alertType, _ensureIncludes(IncidentLog.alertTypes, _alertType),
                      (v) => setState(() => _alertType = v!)),
                  const SizedBox(height: 14),
                  _dropdown('Severity', _severity, _ensureIncludes(IncidentLog.severities, _severity),
                      (v) => setState(() => _severity = v!)),
                  const SizedBox(height: 14),
                  _dropdown(
                      'Ticket Status',
                      _ticketStatus,
                      _ensureIncludes(IncidentLog.ticketStatuses, _ticketStatus),
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
