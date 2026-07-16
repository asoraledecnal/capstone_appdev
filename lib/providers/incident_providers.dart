import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/incident_model.dart';
import '../services/incident_repository.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return IncidentRepository();
});

final incidentStreamProvider = StreamProvider<List<IncidentLog>>((ref) {
  final repository = ref.watch(incidentRepositoryProvider);
  return repository.watchIncidents();
});
