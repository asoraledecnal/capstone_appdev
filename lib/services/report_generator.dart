import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/incident_model.dart';
import '../models/wazuh_agent_model.dart';
import '../models/compliance_record_model.dart';
import 'wazuh_agent_repository.dart';
import 'compliance_repository.dart';

/// Generates professional PDF reports for a given provincial spoke.
/// All data is fetched directly from Firestore — no backend required.
class ReportGenerator {
  final String spokeId;
  final String spokeName;

  ReportGenerator({required this.spokeId, required this.spokeName});

  static const _teal = PdfColor.fromInt(0xFF00BFA5);
  static const _dark = PdfColor.fromInt(0xFF0B0F14);
  static const _panel = PdfColor.fromInt(0xFF141A22);
  static const _textMuted = PdfColor.fromInt(0xFF64748B);
  static const _red = PdfColor.fromInt(0xFFEF4444);
  static const _orange = PdfColor.fromInt(0xFFF97316);
  static const _green = PdfColor.fromInt(0xFF22C55E);

  /// Weekly Security Summary — all incidents for the past 7 days.
  Future<Uint8List> generateWeeklySummary() async {
    final since = DateTime.now().subtract(const Duration(days: 7));
    final incidents = await FirebaseFirestore.instance
        .collection('incidents')
        .where('spoke_id', isEqualTo: spokeId)
        .orderBy('timestamp', descending: true)
        .get()
        .then((snap) => snap.docs
            .map((d) => IncidentLog.fromFirestore(d))
            .where((i) => i.timestamp.isAfter(since))
            .toList());

    final critical = incidents.where((i) => i.severity.toLowerCase() == 'critical').length;
    final high = incidents.where((i) => i.severity.toLowerCase() == 'high').length;
    final open = incidents.where((i) => i.ticketStatus.toLowerCase() == 'open').length;
    final resolved = incidents.where((i) => i.ticketStatus.toLowerCase() == 'resolved').length;

    final pdf = pw.Document();
    final logo = await _loadLogo();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: _theme(),
      header: (ctx) => _header(logo, 'Weekly Security Summary',
          'Past 7 days  •  ${_fmt(since)} – ${_fmt(DateTime.now())}'),
      footer: (ctx) => _footer(ctx),
      build: (ctx) => [
        _sectionTitle('Overview Statistics'),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          _statBox('Total Incidents', '${incidents.length}', _teal),
          pw.SizedBox(width: 12),
          _statBox('Critical', '$critical', _red),
          pw.SizedBox(width: 12),
          _statBox('High', '$high', _orange),
          pw.SizedBox(width: 12),
          _statBox('Open', '$open', _red),
          pw.SizedBox(width: 12),
          _statBox('Resolved', '$resolved', _green),
        ]),
        pw.SizedBox(height: 20),
        _sectionTitle('Incident Log'),
        pw.SizedBox(height: 8),
        if (incidents.isEmpty)
          _emptyNote('No incidents recorded in the past 7 days.')
        else
          _incidentTable(incidents.take(50).toList()),
      ],
    ));

    return pdf.save();
  }

  /// Failed Login Audit — access identity events filtered by auth type.
  Future<Uint8List> generateFailedLoginAudit() async {
    final snap = await FirebaseFirestore.instance
        .collection('wazuh_events')
        .where('spoke_id', isEqualTo: spokeId)
        .orderBy('timestamp', descending: true)
        .limit(200)
        .get();

    final events = snap.docs
        .map((d) {
          final data = d.data();
          return data;
        })
        .where((d) =>
            (d['type'] as String? ?? '').toLowerCase().contains('login') ||
            (d['type'] as String? ?? '').toLowerCase().contains('auth') ||
            (d['type'] as String? ?? '').toLowerCase().contains('fail'))
        .toList();

    final pdf = pw.Document();
    final logo = await _loadLogo();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: _theme(),
      header: (ctx) => _header(logo, 'Failed Login Audit',
          'Generated ${_fmt(DateTime.now())}  •  Last 200 auth events'),
      footer: (ctx) => _footer(ctx),
      build: (ctx) => [
        _sectionTitle('Authentication Event Summary'),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          _statBox('Auth Events Found', '${events.length}', _teal),
        ]),
        pw.SizedBox(height: 20),
        _sectionTitle('Authentication Events'),
        pw.SizedBox(height: 8),
        if (events.isEmpty)
          _emptyNote('No authentication events found for this office.')
        else
          _authTable(events.take(50).toList()),
      ],
    ));

    return pdf.save();
  }

  /// Endpoint Compliance Report — Wazuh agent list with status.
  Future<Uint8List> generateEndpointCompliance() async {
    final agents = await WazuhAgentRepository()
        .watchAgents(spokeId: spokeId)
        .first;

    final compliance = await ComplianceRepository()
        .watchRecords(spokeId: spokeId)
        .first;

    final active = agents.where((a) => a.active).length;
    final disconnected = agents.where((a) => !a.active).length;

    final pdf = pw.Document();
    final logo = await _loadLogo();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: _theme(),
      header: (ctx) => _header(logo, 'Endpoint Compliance Report',
          'Generated ${_fmt(DateTime.now())}'),
      footer: (ctx) => _footer(ctx),
      build: (ctx) => [
        _sectionTitle('Endpoint Overview'),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          _statBox('Total Agents', '${agents.length}', _teal),
          pw.SizedBox(width: 12),
          _statBox('Active', '$active', _green),
          pw.SizedBox(width: 12),
          _statBox('Disconnected', '$disconnected', _red),
        ]),
        pw.SizedBox(height: 20),
        _sectionTitle('Compliance Frameworks'),
        pw.SizedBox(height: 8),
        if (compliance.isEmpty)
          _emptyNote('No compliance records found.')
        else
          _complianceTable(compliance),
        pw.SizedBox(height: 20),
        _sectionTitle('Agent List'),
        pw.SizedBox(height: 8),
        if (agents.isEmpty)
          _emptyNote('No agents registered for this office.')
        else
          _agentTable(agents),
      ],
    ));

    return pdf.save();
  }

  /// Resolved Incidents Report — all resolved/mitigated incidents.
  Future<Uint8List> generateResolvedIncidents() async {
    final snap = await FirebaseFirestore.instance
        .collection('incidents')
        .where('spoke_id', isEqualTo: spokeId)
        .orderBy('timestamp', descending: true)
        .get();

    final resolved = snap.docs
        .map((d) => IncidentLog.fromFirestore(d))
        .where((i) =>
            i.ticketStatus.toLowerCase() == 'resolved' ||
            i.ticketStatus.toLowerCase() == 'mitigated')
        .toList();

    final pdf = pw.Document();
    final logo = await _loadLogo();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: _theme(),
      header: (ctx) => _header(logo, 'Resolved Incidents Report',
          'Generated ${_fmt(DateTime.now())}'),
      footer: (ctx) => _footer(ctx),
      build: (ctx) => [
        _sectionTitle('Resolution Summary'),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          _statBox('Resolved/Mitigated', '${resolved.length}', _green),
          pw.SizedBox(width: 12),
          _statBox('Mitigated', '${resolved.where((i) => i.ticketStatus.toLowerCase() == 'mitigated').length}', _teal),
          pw.SizedBox(width: 12),
          _statBox('Resolved', '${resolved.where((i) => i.ticketStatus.toLowerCase() == 'resolved').length}', _green),
        ]),
        pw.SizedBox(height: 20),
        _sectionTitle('Incident Details'),
        pw.SizedBox(height: 8),
        if (resolved.isEmpty)
          _emptyNote('No resolved incidents found for this office.')
        else
          _incidentTable(resolved.take(50).toList()),
      ],
    ));

    return pdf.save();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<pw.ImageProvider?> _loadLogo() async {
    try {
      final bytes = await rootBundle.load('assets/images/dict_logo_icon.png');
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  pw.ThemeData _theme() {
    return pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );
  }

  pw.Widget _header(pw.ImageProvider? logo, String title, String subtitle) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _teal, width: 2)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null) ...[
            pw.Image(logo, width: 36, height: 36),
            pw.SizedBox(width: 12),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('DICT-4A SIEM — $spokeName',
                    style: pw.TextStyle(
                        fontSize: 10,
                        color: _teal,
                        fontWeight: pw.FontWeight.bold)),
                pw.Text(title,
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text(subtitle,
                    style: const pw.TextStyle(fontSize: 9, color: _textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _textMuted, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('DICT-4A Wazuh SIEM — Confidential',
              style: const pw.TextStyle(fontSize: 8, color: _textMuted)),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: _textMuted)),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Text(text,
        style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: _teal));
  }

  pw.Widget _statBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _panel,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: color, width: 1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: color)),
            pw.Text(label,
                style: const pw.TextStyle(fontSize: 9, color: _textMuted)),
          ],
        ),
      ),
    );
  }

  pw.Widget _emptyNote(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _panel,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Text(text,
          style: const pw.TextStyle(color: _textMuted, fontSize: 11)),
    );
  }

  pw.Widget _incidentTable(List<IncidentLog> incidents) {
    final headers = ['ID', 'Date', 'Alert Type', 'Severity', 'Status', 'Rule'];
    final rows = incidents.map((i) => [
          i.id.length > 20 ? i.id.substring(0, 20) : i.id,
          _fmt(i.timestamp),
          i.alertType,
          i.severity,
          i.ticketStatus,
          i.heuristicRule,
        ]).toList();
    return _table(headers, rows);
  }

  pw.Widget _authTable(List<Map<String, dynamic>> events) {
    final headers = ['Date', 'Type', 'Agent', 'Source IP', 'Level'];
    final rows = events.map((e) {
      final rawTs = e['timestamp'];
      String dateStr = '';
      if (rawTs is Timestamp) dateStr = _fmt(rawTs.toDate());
      return [
        dateStr,
        e['type'] as String? ?? '',
        e['agent'] as String? ?? '',
        e['source_ip'] as String? ?? '',
        '${e['level'] ?? ''}',
      ];
    }).toList();
    return _table(headers, rows);
  }

  pw.Widget _agentTable(List<WazuhAgent> agents) {
    final headers = ['Name', 'OS', 'Version', 'Status', 'IP'];
    final rows = agents.map((a) => [
          a.name,
          a.os,
          a.version,
          a.active ? 'Active' : 'Disconnected',
          a.ip,
        ]).toList();
    return _table(headers, rows);
  }

  pw.Widget _complianceTable(List<ComplianceRecord> records) {
    final headers = ['Framework', 'Score (%)', 'Passed', 'Failed'];
    final rows = records.map((r) => [
          r.framework,
          r.percent.toStringAsFixed(1),
          '${r.passed}',
          '${r.failed}',
        ]).toList();
    return _table(headers, rows);
  }

  pw.Widget _table(List<String> headers, List<List<String>> rows) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(color: _textMuted, width: 0.5),
      headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, color: _dark, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: _teal),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      oddRowDecoration: const pw.BoxDecoration(color: _panel),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        for (int i = 1; i < headers.length; i++) i: const pw.FlexColumnWidth(1.5),
      },
    );
  }

  String _fmt(DateTime dt) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${p(dt.month)}-${p(dt.day)} ${p(dt.hour)}:${p(dt.minute)}';
  }
}
