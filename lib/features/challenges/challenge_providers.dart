import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase_providers.dart';
import 'challenge_service.dart';

final challengeServiceProvider = Provider<ChallengeService>((ref) {
  return ChallengeService(ref.watch(firestoreProvider));
});

/// Returns the current week's "Post Twice" challenge id.
/// Requires the user to be logged in (uid available).
final weeklyPostTwiceChallengeIdProvider = FutureProvider<String>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) {
    throw Exception('Not logged in');
  }

  return ref.watch(challengeServiceProvider).ensureWeeklyPostTwiceChallenge(uid: uid);
});

