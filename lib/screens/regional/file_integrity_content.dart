import 'package:flutter/material.dart';
import '../../models/file_integrity_event_model.dart';
import '../../services/file_integrity_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class FileIntegrityContent extends StatefulWidget {
  final String? spokeId;
  const FileIntegrityContent({super.key, this.spokeId});

  @override
  State<FileIntegrityContent> createState() => _FileIntegrityContentState();
}

class _FileIntegrityContentState extends State<FileIntegrityContent> {
  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final repository = FileIntegrityRepository();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'File Integrity Monitoring',
            subtitle:
                'Real-time alerts for modified, created, or deleted files across all agents.',
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              // TIMESTAMP and AGENT were disappearing entirely below this
              // width (not just truncating) because a 5-column table with
              // a long FILE PATH column has nowhere left to put them on a
              // horizontal scroll. Below the breakpoint, switch to a
              // tappable card per event: every field stays visible, and
              // the previously-inert info icon now actually opens the full
              // record (timestamp, agent, full untruncated path, action).
              final narrow = constraints.maxWidth < 640;
              return DashCard(
                child: StreamBuilder<List<FileIntegrityEvent>>(
                  stream: repository.watchEvents(spokeId: widget.spokeId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('Failed to load events: ${snapshot.error}',
                            style: const TextStyle(color: AppColors.red)),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final events = snapshot.data!;
                    if (events.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No file integrity events yet.',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    return narrow
                        ? _eventCardList(context, events)
                        : HScrollBox(
                            minWidth: 640,
                            child: SimpleTable(
                          headers: const [
                            'TIMESTAMP',
                            'AGENT',
                            'FILE PATH',
                            'ACTION',
                            'DETAILS'
                          ],
                          flex: const [2, 2, 4, 2, 1],
                          rows: [
                            for (final e in events)
                              [
                                CellText(_formatDateTime(e.timestamp), color: AppColors.textSecondary),
                                CellText(e.agentName, weight: FontWeight.w600),
                                CellText(e.filePath, color: AppColors.textSecondary),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: StatusBadge(
                                    label: e.action,
                                    color: e.action == 'ADDED'
                                        ? AppColors.red
                                        : AppColors.orange,
                                  ),
                                ),
                                _DetailButton(event: e),
                              ],
                          ],
                        ),
                      );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Mobile-width replacement for the table: one tappable card per file
  /// event carrying all the same fields, laid out top-to-bottom so the
  /// timestamp and agent never get squeezed off-screen.
  Widget _eventCardList(BuildContext context, List<FileIntegrityEvent> events) {
    return Column(
      children: [
        for (int i = 0; i < events.length; i++) ...[
          _FileEventCard(event: events[i]),
          if (i != events.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _FileEventCard extends StatelessWidget {
  final FileIntegrityEvent event;

  const _FileEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final action = event.action;
    final actionColor = action == 'ADDED' ? AppColors.red : AppColors.orange;
    
    String formatDateTime(DateTime dt) {
      String two(int n) => n.toString().padLeft(2, '0');
      return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
          '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
    }

    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => showFileEventDetail(context, event),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.filePath,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(label: action, color: actionColor),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _metaChip(Icons.dns_outlined, event.agentName, AppColors.teal),
                  _metaChip(Icons.access_time, formatDateTime(event.timestamp), AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 6),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Tap for full details',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      size: 14, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
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
}

/// The DETAILS column on the wide table: previously a static, non-tappable
/// icon. Now opens the same detail sheet the mobile cards use, so it
/// actually does something on desktop/tablet too.
class _DetailButton extends StatelessWidget {
  final FileIntegrityEvent event;

  const _DetailButton({required this.event});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        tooltip: 'View details',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: const Icon(Icons.info_outline,
            size: 16, color: AppColors.textMuted),
        onPressed: () => showFileEventDetail(context, event),
      ),
    );
  }
}

/// Shared detail sheet used by both the mobile card ("Tap for full
/// details") and the desktop table's DETAILS icon.
void showFileEventDetail(BuildContext context, FileIntegrityEvent event) {
  final action = event.action;
  final actionColor = action == 'ADDED' ? AppColors.red : AppColors.orange;
  
  String formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            StatusBadge(label: action, color: actionColor),
            const SizedBox(height: 16),
            _detailRow('FILE PATH', event.filePath, big: true),
            const SizedBox(height: 18),
            _detailRow('AGENT', event.agentName),
            const SizedBox(height: 18),
            _detailRow('TIMESTAMP', formatDateTime(event.timestamp)),
            const SizedBox(height: 28),
            SizedBox(
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
          ],
        ),
      );
    },
  );
}

Widget _detailRow(String label, String value, {bool big = false}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        value,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: big ? 17 : 16,
        ),
      ),
    ],
  );
}
