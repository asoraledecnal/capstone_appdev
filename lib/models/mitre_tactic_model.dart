import 'package:cloud_firestore/cloud_firestore.dart';

/// A single MITRE ATT&CK tactic's observed activity score (0.0-1.0),
/// derived by the heuristic analytics engine from Wazuh alert volume/
/// severity per tactic — not from any ML/neural-net scoring.
///
/// [severity] drives the bar color via the same `AppColors.severityColor`
/// used for incident severity elsewhere in the app, so a tactic's color
/// is a deliberate analyst judgment call (not automatically derived from
/// [score] — a tactic can have a high score but still be rated 'Low' if
/// it's expected/benign activity, matching how the original mockup data
/// assigned colors independently of the numeric bar length).
class MitreTactic {
  final String id; // Firestore document ID, e.g. 'initial-access'
  final String tacticName; // Display name, e.g. 'Initial Access'
  final double score; // 0.0 - 1.0, drives the bar length
  final String severity; // Low | Medium | High | Critical, drives bar color

  const MitreTactic({
    required this.id,
    required this.tacticName,
    required this.score,
    required this.severity,
  });

  factory MitreTactic.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    final rawScore = data['score'];
    final score = (rawScore is num) ? rawScore.toDouble() : 0.0;
    return MitreTactic(
      id: doc.id,
      tacticName: data['tactic_name'] as String? ?? '',
      score: score.clamp(0.0, 1.0),
      severity: data['severity'] as String? ?? 'Low',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'tactic_name': tacticName,
        'score': score,
        'severity': severity,
      };
}
