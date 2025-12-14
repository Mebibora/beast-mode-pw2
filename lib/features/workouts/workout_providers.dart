import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/firebase_providers.dart';
import 'workout_service.dart';

final workoutServiceProvider = Provider<WorkoutService>((ref) {
  return WorkoutService(ref.watch(firestoreProvider));
});
