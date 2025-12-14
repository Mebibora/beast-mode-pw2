import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/firebase_providers.dart';
import 'feed_service.dart';
import '../../models/activity.dart';

final feedServiceProvider = Provider<FeedService>((ref) {
  return FeedService(ref.watch(firestoreProvider));
});

final publicFeedProvider = StreamProvider<List<Activity>>((ref) {
  return ref.watch(feedServiceProvider).publicFeedStream();
});
