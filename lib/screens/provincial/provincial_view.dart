import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

/// Provincial View — Firestore-wired.
///
/// Reads the same `spokes` and `incidents` collections defined in
/// assets/firestore_schema_and_data.json. The tenant dropdown lists every
/// spoke EXCEPT SPOKE-03 (Batangas), since Batangas is the Hub, not a
/// province-level tenant. Everything below the dropdown is scoped to the
/// currently selected spoke_id.
///
/// NOTE ON DESIGN DEVIATION FROM THE OLD HARDCODED MOCK:
/// The old mock's event table had ENDPOINT / DESCRIPTION / SOURCE / ACTION
/// columns and "24/28 endpoints" stat cards. None of those fields exist on
/// `incidents` or `spokes` in the real schema, so this rewrite is built
/// around what's actually there: incident_id, timestamp, alert_type,
/// severity, ticket_status. Stat cards now show gateway status + incident
/// counts instead of invented endpoint numbers.
class ProvincialView extends StatefulWidget {
  const ProvincialView({super.key});

  @override
  State<ProvincialView> createState() => _ProvincialViewState();
}

class _ProvincialViewState extends State<ProvincialView> {
  final _firestore = FirebaseFirestore.instance;

  static const String _hubSpokeId = 'SPOKE-03'; // Batangas — not a tenant
  String? _selectedSpokeId; // becomes non-null once the spokes stream loads
  bool _seeding = false;

  // ---- Canonical demo data (mirrors assets/firestore_schema_and_data.json)
  // Doc IDs are deterministic (spoke_id / incident_id), so seeding is
  // idempotent by construction — but we still clear stale docs first in
  // case a prior seed left orphaned documents with different IDs.
  static const List<Map<String, dynamic>> _demoSpokes = [
    {
      'spoke_id': 'SPOKE-01',
      'office_name': 'DICT Cavite Provincial Office',
      'location': 'Tagaytay City',
      'public_ip_mask': '112.198.XX.XX',
      'pfsense_version': '2.7.2-RELEASE',
      'status': 'Online',
      'contact_role': 'DICT Region IV-A Security Analyst',
    },
    {
      'spoke_id': 'SPOKE-02',
      'office_name': 'DICT Laguna Provincial Office',
      'location': 'Calamba City',
      'public_ip_mask': '120.28.XX.XX',
      'pfsense_version': '2.7.2-RELEASE',
      'status': 'Online',
      'contact_role': 'DICT Region IV-A Security Analyst',
    },
    {
      'spoke_id': 'SPOKE-03',
      'office_name': 'DICT Batangas Provincial Office',
      'location': 'Batangas City',
      'public_ip_mask': '122.3.XX.XX',
      'pfsense_version': '2.7.0-RELEASE',
      'status': 'Online',
      'contact_role': 'DICT Region IV-A NOC Operator',
    },
    {
      'spoke_id': 'SPOKE-04',
      'office_name': 'DICT Rizal Provincial Office',
      'location': 'Antipolo City',
      'public_ip_mask': '110.54.XX.XX',
      'pfsense_version': '2.7.2-RELEASE',
      'status': 'Online',
      'contact_role': 'DICT Region IV-A NOC Operator',
    },
    {
      'spoke_id': 'SPOKE-05',
      'office_name': 'DICT Quezon Provincial Office',
      'location': 'Lucena City',
      'public_ip_mask': '115.147.XX.XX',
      'pfsense_version': '2.6.0-RELEASE',
      'status': 'Offline',
      'contact_role': 'DICT Region IV-A Incident Responder',
    },
  ];

  static const List<Map<String, dynamic>> _demoIncidents = [
    {'incident_id': 'INC-20260715-001', 'timestamp': '2026-07-15T01:10:00Z', 'spoke_id': 'SPOKE-01', 'alert_type': 'High Latency', 'severity': 'Medium', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-002', 'timestamp': '2026-07-15T01:15:00Z', 'spoke_id': 'SPOKE-02', 'alert_type': 'IPsec Tunnel Down', 'severity': 'High', 'ticket_status': 'Mitigated'},
    {'incident_id': 'INC-20260715-003', 'timestamp': '2026-07-15T01:22:00Z', 'spoke_id': 'SPOKE-03', 'alert_type': 'Port Scan Detected', 'severity': 'Medium', 'ticket_status': 'Investigating'},
    {'incident_id': 'INC-20260715-004', 'timestamp': '2026-07-15T01:30:00Z', 'spoke_id': 'SPOKE-04', 'alert_type': 'Brute Force Attempt', 'severity': 'High', 'ticket_status': 'Open'},
    {'incident_id': 'INC-20260715-005', 'timestamp': '2026-07-15T01:45:00Z', 'spoke_id': 'SPOKE-05', 'alert_type': 'DDoS Heuristic Threat', 'severity': 'Critical', 'ticket_status': 'Mitigated'},
    {'incident_id': 'INC-20260715-006', 'timestamp': '2026-07-15T02:00:00Z', 'spoke_id': 'SPOKE-01', 'alert_type': 'IPsec Tunnel Down', 'severity': 'High', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-007', 'timestamp': '2026-07-15T02:05:00Z', 'spoke_id': 'SPOKE-03', 'alert_type': 'High Latency', 'severity': 'Low', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-008', 'timestamp': '2026-07-15T02:12:00Z', 'spoke_id': 'SPOKE-02', 'alert_type': 'Port Scan Detected', 'severity': 'Medium', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-009', 'timestamp': '2026-07-15T02:18:00Z', 'spoke_id': 'SPOKE-04', 'alert_type': 'Brute Force Attempt', 'severity': 'High', 'ticket_status': 'Investigating'},
    {'incident_id': 'INC-20260715-010', 'timestamp': '2026-07-15T02:30:00Z', 'spoke_id': 'SPOKE-05', 'alert_type': 'Gateway Connectivity Alert', 'severity': 'Low', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-011', 'timestamp': '2026-07-15T02:45:00Z', 'spoke_id': 'SPOKE-01', 'alert_type': 'DDoS Heuristic Threat', 'severity': 'Critical', 'ticket_status': 'Investigating'},
    {'incident_id': 'INC-20260715-012', 'timestamp': '2026-07-15T03:00:00Z', 'spoke_id': 'SPOKE-02', 'alert_type': 'High Latency', 'severity': 'Low', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-013', 'timestamp': '2026-07-15T03:15:00Z', 'spoke_id': 'SPOKE-03', 'alert_type': 'IPsec Tunnel Down', 'severity': 'High', 'ticket_status': 'Mitigated'},
    {'incident_id': 'INC-20260715-014', 'timestamp': '2026-07-15T03:22:00Z', 'spoke_id': 'SPOKE-04', 'alert_type': 'Port Scan Detected', 'severity': 'Medium', 'ticket_status': 'Open'},
    {'incident_id': 'INC-20260715-015', 'timestamp': '2026-07-15T03:30:00Z', 'spoke_id': 'SPOKE-05', 'alert_type': 'Brute Force Attempt', 'severity': 'High', 'ticket_status': 'Mitigated'},
    {'incident_id': 'INC-20260715-016', 'timestamp': '2026-07-15T03:40:00Z', 'spoke_id': 'SPOKE-01', 'alert_type': 'Gateway Connectivity Alert', 'severity': 'Low', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-017', 'timestamp': '2026-07-15T03:55:00Z', 'spoke_id': 'SPOKE-02', 'alert_type': 'DDoS Heuristic Threat', 'severity': 'Critical', 'ticket_status': 'Open'},
    {'incident_id': 'INC-20260715-018', 'timestamp': '2026-07-15T04:10:00Z', 'spoke_id': 'SPOKE-03', 'alert_type': 'High Latency', 'severity': 'Low', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-019', 'timestamp': '2026-07-15T04:25:00Z', 'spoke_id': 'SPOKE-04', 'alert_type': 'IPsec Tunnel Down', 'severity': 'High', 'ticket_status': 'Mitigated'},
    {'incident_id': 'INC-20260715-020', 'timestamp': '2026-07-15T04:35:00Z', 'spoke_id': 'SPOKE-05', 'alert_type': 'Port Scan Detected', 'severity': 'Medium', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-021', 'timestamp': '2026-07-15T04:50:00Z', 'spoke_id': 'SPOKE-01', 'alert_type': 'Brute Force Attempt', 'severity': 'High', 'ticket_status': 'Investigating'},
    {'incident_id': 'INC-20260715-022', 'timestamp': '2026-07-15T05:00:00Z', 'spoke_id': 'SPOKE-02', 'alert_type': 'Gateway Connectivity Alert', 'severity': 'Low', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-023', 'timestamp': '2026-07-15T05:15:00Z', 'spoke_id': 'SPOKE-03', 'alert_type': 'DDoS Heuristic Threat', 'severity': 'Critical', 'ticket_status': 'Mitigated'},
    {'incident_id': 'INC-20260715-024', 'timestamp': '2026-07-15T05:30:00Z', 'spoke_id': 'SPOKE-04', 'alert_type': 'High Latency', 'severity': 'Medium', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-025', 'timestamp': '2026-07-15T05:45:00Z', 'spoke_id': 'SPOKE-05', 'alert_type': 'IPsec Tunnel Down', 'severity': 'High', 'ticket_status': 'Open'},
    {'incident_id': 'INC-20260715-026', 'timestamp': '2026-07-15T06:00:00Z', 'spoke_id': 'SPOKE-01', 'alert_type': 'Port Scan Detected', 'severity': 'Medium', 'ticket_status': 'Mitigated'},
    {'incident_id': 'INC-20260715-027', 'timestamp': '2026-07-15T06:15:00Z', 'spoke_id': 'SPOKE-02', 'alert_type': 'Brute Force Attempt', 'severity': 'High', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-028', 'timestamp': '2026-07-15T06:22:00Z', 'spoke_id': 'SPOKE-03', 'alert_type': 'Gateway Connectivity Alert', 'severity': 'Low', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-029', 'timestamp': '2026-07-15T06:30:00Z', 'spoke_id': 'SPOKE-04', 'alert_type': 'DDoS Heuristic Threat', 'severity': 'Critical', 'ticket_status': 'Mitigated'},
    {'incident_id': 'INC-20260715-030', 'timestamp': '2026-07-15T06:45:00Z', 'spoke_id': 'SPOKE-05', 'alert_type': 'High Latency', 'severity': 'Low', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-031', 'timestamp': '2026-07-15T07:00:00Z', 'spoke_id': 'SPOKE-01', 'alert_type': 'IPsec Tunnel Down', 'severity': 'High', 'ticket_status': 'Investigating'},
    {'incident_id': 'INC-20260715-032', 'timestamp': '2026-07-15T07:15:00Z', 'spoke_id': 'SPOKE-02', 'alert_type': 'Port Scan Detected', 'severity': 'Medium', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-033', 'timestamp': '2026-07-15T07:30:00Z', 'spoke_id': 'SPOKE-03', 'alert_type': 'Brute Force Attempt', 'severity': 'High', 'ticket_status': 'Mitigated'},
    {'incident_id': 'INC-20260715-034', 'timestamp': '2026-07-15T07:45:00Z', 'spoke_id': 'SPOKE-04', 'alert_type': 'Gateway Connectivity Alert', 'severity': 'Low', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-035', 'timestamp': '2026-07-15T08:00:00Z', 'spoke_id': 'SPOKE-05', 'alert_type': 'DDoS Heuristic Threat', 'severity': 'Critical', 'ticket_status': 'Open'},
    // Fixed: source JSON had this doc's incident_id malformed as
    // "INC-20260715-08:15:00Z" instead of following the INC-YYYYMMDD-XXX
    // format used by every other doc. Corrected to -036 here.
    {'incident_id': 'INC-20260715-036', 'timestamp': '2026-07-15T08:15:00Z', 'spoke_id': 'SPOKE-01', 'alert_type': 'High Latency', 'severity': 'Low', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-037', 'timestamp': '2026-07-15T08:30:00Z', 'spoke_id': 'SPOKE-02', 'alert_type': 'IPsec Tunnel Down', 'severity': 'High', 'ticket_status': 'Mitigated'},
    {'incident_id': 'INC-20260715-038', 'timestamp': '2026-07-15T08:45:00Z', 'spoke_id': 'SPOKE-03', 'alert_type': 'Port Scan Detected', 'severity': 'Medium', 'ticket_status': 'Investigating'},
    {'incident_id': 'INC-20260715-039', 'timestamp': '2026-07-15T09:00:00Z', 'spoke_id': 'SPOKE-04', 'alert_type': 'Brute Force Attempt', 'severity': 'High', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-040', 'timestamp': '2026-07-15T09:15:00Z', 'spoke_id': 'SPOKE-05', 'alert_type': 'Gateway Connectivity Alert', 'severity': 'Low', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-041', 'timestamp': '2026-07-15T09:30:00Z', 'spoke_id': 'SPOKE-01', 'alert_type': 'DDoS Heuristic Threat', 'severity': 'Critical', 'ticket_status': 'Mitigated'},
    {'incident_id': 'INC-20260715-042', 'timestamp': '2026-07-15T09:45:00Z', 'spoke_id': 'SPOKE-02', 'alert_type': 'High Latency', 'severity': 'Medium', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-043', 'timestamp': '2026-07-15T10:00:00Z', 'spoke_id': 'SPOKE-03', 'alert_type': 'IPsec Tunnel Down', 'severity': 'High', 'ticket_status': 'Open'},
    {'incident_id': 'INC-20260715-044', 'timestamp': '2026-07-15T10:15:00Z', 'spoke_id': 'SPOKE-04', 'alert_type': 'Port Scan Detected', 'severity': 'Medium', 'ticket_status': 'Mitigated'},
    {'incident_id': 'INC-20260715-045', 'timestamp': '2026-07-15T10:30:00Z', 'spoke_id': 'SPOKE-05', 'alert_type': 'Brute Force Attempt', 'severity': 'High', 'ticket_status': 'Investigating'},
    {'incident_id': 'INC-20260715-046', 'timestamp': '2026-07-15T10:45:00Z', 'spoke_id': 'SPOKE-01', 'alert_type': 'Gateway Connectivity Alert', 'severity': 'Low', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-047', 'timestamp': '2026-07-15T11:00:00Z', 'spoke_id': 'SPOKE-02', 'alert_type': 'DDoS Heuristic Threat', 'severity': 'Critical', 'ticket_status': 'Mitigated'},
    {'incident_id': 'INC-20260715-048', 'timestamp': '2026-07-15T11:15:00Z', 'spoke_id': 'SPOKE-03', 'alert_type': 'High Latency', 'severity': 'Low', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-049', 'timestamp': '2026-07-15T11:30:00Z', 'spoke_id': 'SPOKE-04', 'alert_type': 'IPsec Tunnel Down', 'severity': 'High', 'ticket_status': 'Resolved'},
    {'incident_id': 'INC-20260715-050', 'timestamp': '2026-07-15T11:45:00Z', 'spoke_id': 'SPOKE-05', 'alert_type': 'Port Scan Detected', 'severity': 'Medium', 'ticket_status': 'Mitigated'},
  ];

  // ---- Seeding -------------------------------------------------------

  Future<void> _seedDemoData(BuildContext context) async {
    setState(() => _seeding = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Clear existing docs first so stale/renamed demo docs don't linger,
      // then rewrite the canonical set. Doc IDs are spoke_id / incident_id,
      // so this is idempotent — running it twice yields the same state.
      final spokesSnap = await _firestore.collection('spokes').get();
      final incidentsSnap = await _firestore.collection('incidents').get();

      final clearBatch = _firestore.batch();
      for (final d in spokesSnap.docs) {
        clearBatch.delete(d.reference);
      }
      for (final d in incidentsSnap.docs) {
        clearBatch.delete(d.reference);
      }
      await clearBatch.commit();

      final seedBatch = _firestore.batch();
      for (final s in _demoSpokes) {
        seedBatch.set(
          _firestore.collection('spokes').doc(s['spoke_id'] as String),
          s,
        );
      }
      for (final i in _demoIncidents) {
        seedBatch.set(
          _firestore.collection('incidents').doc(i['incident_id'] as String),
          i,
        );
      }
      await seedBatch.commit();

      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Demo data seeded.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Seeding failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  // ---- Incident status action -----------------------------------------

  static const List<String> _statusOrder = [
    'Open',
    'Investigating',
    'Mitigated',
    'Resolved',
  ];

  String? _nextStatus(String current) {
    final i = _statusOrder.indexOf(current);
    if (i == -1 || i == _statusOrder.length - 1) return null;
    return _statusOrder[i + 1];
  }

  String _actionLabel(String current) {
    switch (current) {
      case 'Open':
        return 'Investigate';
      case 'Investigating':
        return 'Mitigate';
      case 'Mitigated':
        return 'Resolve';
      default:
        return 'Resolved';
    }
  }

  Future<void> _advanceStatus(
      BuildContext context, String incidentId, String current) async {
    final next = _nextStatus(current);
    if (next == null) return;
    try {
      await _firestore
          .collection('incidents')
          .doc(incidentId)
          .update({'ticket_status': next});
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  // ---- Formatting helpers ----------------------------------------------

  String _timeOnly(String isoTimestamp) {
    try {
      final t = isoTimestamp.split('T')[1];
      return t.replaceAll('Z', '');
    } catch (_) {
      return isoTimestamp;
    }
  }

  String _relativeTime(String isoTimestamp) {
    try {
      final ts = DateTime.parse(isoTimestamp).toUtc();
      final diff = DateTime.now().toUtc().difference(ts);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'moments ago';
    } catch (_) {
      return '—';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Open':
        return AppColors.red;
      case 'Investigating':
        return AppColors.orange;
      case 'Mitigated':
        return AppColors.teal;
      case 'Resolved':
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _alertIcon(String alertType) {
    switch (alertType) {
      case 'High Latency':
        return Icons.speed_outlined;
      case 'IPsec Tunnel Down':
        return Icons.link_off;
      case 'Port Scan Detected':
        return Icons.radar;
      case 'Brute Force Attempt':
        return Icons.lock_outline;
      case 'DDoS Heuristic Threat':
        return Icons.warning_amber_outlined;
      case 'Gateway Connectivity Alert':
        return Icons.router_outlined;
      default:
        return Icons.info_outline;
    }
  }

  // ---- Build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('spokes').orderBy('spoke_id').snapshots(),
      builder: (context, spokeSnap) {
        if (spokeSnap.hasError) {
          return _ErrorState(message: 'Failed to load spokes: ${spokeSnap.error}');
        }
        if (!spokeSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tenantDocs = spokeSnap.data!.docs
            .where((d) => d.id != _hubSpokeId)
            .toList();

        if (tenantDocs.isEmpty) {
          return _EmptyState(onSeed: () => _seedDemoData(context), seeding: _seeding);
        }

        _selectedSpokeId ??= tenantDocs.first.id;
        final selectedDoc = tenantDocs.firstWhere(
          (d) => d.id == _selectedSpokeId,
          orElse: () => tenantDocs.first,
        );
        final selected = selectedDoc.data();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width - 160),
                      child: PopupMenuButton<String>(
                        color: AppColors.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppColors.cardBorder),
                        ),
                        offset: const Offset(0, 46),
                        onSelected: (id) => setState(() => _selectedSpokeId = id),
                        itemBuilder: (context) => [
                          for (final d in tenantDocs)
                            PopupMenuItem(
                              value: d.id,
                              child: Text(
                                d.data()['office_name'] as String? ?? d.id,
                                style: TextStyle(
                                  color: d.id == _selectedSpokeId
                                      ? AppColors.teal
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
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
                                  'Tenant: ${selected['office_name'] ?? _selectedSpokeId}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.keyboard_arrow_down,
                                  size: 18, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _seeding ? null : () => _seedDemoData(context),
                    icon: _seeding
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.data_array, size: 16),
                    label: const Text('Seed Demo Data',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.cardBorder),
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final titleBlock = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Local Agent Dashboard',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                          'Tenant isolation mode: Viewing local telemetry for '
                          '${selected['location'] ?? selectedDoc.id}.',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  );
                  final isOnline = (selected['status'] as String?) == 'Online';
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isOnline ? AppColors.teal : AppColors.red),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isOnline ? Icons.sync : Icons.sync_disabled,
                                size: 15,
                                color: isOnline ? AppColors.teal : AppColors.red),
                            const SizedBox(width: 6),
                            Text(
                              isOnline
                                  ? 'Sync with Batangas Hub'
                                  : 'Tunnel Offline',
                              style: TextStyle(
                                  color:
                                      isOnline ? AppColors.teal : AppColors.red,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selected['status'] as String? ?? 'Unknown',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  );

                  if (constraints.maxWidth < 560) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleBlock,
                        const SizedBox(height: 16),
                        hubBlock,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: titleBlock),
                      hubBlock,
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestore
                    .collection('incidents')
                    .where('spoke_id', isEqualTo: _selectedSpokeId)
                    .snapshots(),
                builder: (context, incSnap) {
                  if (incSnap.hasError) {
                    return _ErrorState(
                        message: 'Failed to load incidents: ${incSnap.error}');
                  }
                  if (!incSnap.hasData) {
                    return const Center(
                        child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(),
                    ));
                  }

                  final docs = incSnap.data!.docs.toList()
                    ..sort((a, b) => (b.data()['timestamp'] as String? ?? '')
                        .compareTo(a.data()['timestamp'] as String? ?? ''));

                  final total = docs.length;
                  final critical = docs
                      .where((d) => d.data()['severity'] == 'Critical')
                      .length;
                  final high =
                      docs.where((d) => d.data()['severity'] == 'High').length;
                  final open = docs
                      .where((d) => d.data()['ticket_status'] == 'Open')
                      .length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final stats = [
                            _statCard(
                                'GATEWAY STATUS',
                                selected['status'] as String? ?? 'Unknown',
                                Icons.dns_outlined,
                                isOnline ? AppColors.teal : AppColors.red),
                            _statCard('TOTAL INCIDENTS', '$total',
                                Icons.list_alt_outlined, AppColors.textSecondary),
                            _statCard('CRITICAL ALERTS', '$critical',
                                Icons.shield_outlined, AppColors.red),
                            _statCard('HIGH PRIORITY', '$high',
                                Icons.warning_amber_outlined, AppColors.orange),
                          ];
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
                                  if (i != stats.length - 1)
                                    const SizedBox(width: 16),
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
                              for (final s in stats)
                                SizedBox(width: itemWidth, child: s),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      DashCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                const _TitleWithIcon(),
                                Text(
                                  docs.isNotEmpty
                                      ? 'Last event: ${_relativeTime(docs.first.data()['timestamp'] as String)}'
                                      : 'No events yet',
                                  style: const TextStyle(
                                      color: AppColors.textMuted, fontSize: 11),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.circle,
                                        size: 8, color: AppColors.teal),
                                    const SizedBox(width: 6),
                                    const Text('Live',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (docs.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    'No incidents recorded for this office yet.',
                                    style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12),
                                  ),
                                ),
                              )
                            else
                              HScrollBox(
                                minWidth: 900,
                                child: SimpleTable(
                                  headers: const [
                                    'TIME',
                                    'INCIDENT ID',
                                    'ALERT TYPE',
                                    'SEVERITY',
                                    'STATUS',
                                    'ACTION',
                                  ],
                                  flex: const [1, 2, 3, 2, 2, 2],
                                  align: const [
                                    Alignment.center,
                                    Alignment.centerLeft,
                                    Alignment.centerLeft,
                                    Alignment.center,
                                    Alignment.center,
                                    Alignment.center,
                                  ],
                                  rows: [
                                    for (final d in docs.take(20))
                                      _incidentRow(context, d),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                docs.length > 20
                                    ? 'Showing 20 of ${docs.length} events. Critical events require immediate action.'
                                    : 'Showing ${docs.length} event${docs.length == 1 ? '' : 's'}. Critical events require immediate action.',
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 11),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _incidentRow(
      BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();
    final severity = data['severity'] as String? ?? '';
    final status = data['ticket_status'] as String? ?? '';
    final alertType = data['alert_type'] as String? ?? '';
    final nextStatus = _nextStatus(status);

    return [
      CellText(_timeOnly(data['timestamp'] as String? ?? ''),
          color: AppColors.textSecondary),
      CellText(d.id, weight: FontWeight.w600, color: AppColors.teal),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_alertIcon(alertType), size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Flexible(child: CellText(alertType, color: AppColors.textSecondary)),
        ],
      ),
      StatusBadge(
          label: severity.toUpperCase(),
          color: AppColors.severityColor(severity.toUpperCase())),
      StatusBadge(label: status, color: _statusColor(status)),
      nextStatus == null
          ? const Text('—',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11))
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _statusColor(status)),
                foregroundColor: _statusColor(status),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => _advanceStatus(context, d.id, status),
              child: Text(_actionLabel(status),
                  style: const TextStyle(fontSize: 11)),
            ),
    ];
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
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: value.length > 3 ? 18 : 26)),
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

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, style: const TextStyle(color: AppColors.red)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onSeed;
  final bool seeding;
  const _EmptyState({required this.onSeed, required this.seeding});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No spoke data found.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: seeding ? null : onSeed,
              child: Text(seeding ? 'Seeding…' : 'Seed Demo Data'),
            ),
          ],
        ),
      ),
    );
  }
}