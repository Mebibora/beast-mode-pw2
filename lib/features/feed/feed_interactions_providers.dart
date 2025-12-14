import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/firebase_providers.dart';
import 'feed_interactions_service.dart';

final feedInteractionsServiceProvider = Provider<FeedInteractionsService>((ref) {
  return FeedInteractionsService(ref.watch(firestoreProvider));
});

final likedByMeProvider = StreamProvider.family<bool, ({String activityId, String uid})>((ref, args) {
  return ref
      .watch(feedInteractionsServiceProvider)
      .likedByMeStream(activityId: args.activityId, uid: args.uid);
});
