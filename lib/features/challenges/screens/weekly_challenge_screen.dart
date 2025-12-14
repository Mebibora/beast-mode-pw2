import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase_providers.dart';
import '../challenge_providers.dart';

class WeeklyChallengeScreen extends ConsumerWidget {
  const WeeklyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUidProvider);
    final challengeIdAsync = ref.watch(weeklyPostTwiceChallengeIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Challenge')),
      body: uid == null
          ? const Center(child: Text('Please log in.'))
          : challengeIdAsync.when(
              data: (challengeId) {
                final memberStream = ref.watch(challengeServiceProvider)
                    .memberStream(challengeId: challengeId, uid: uid);

                return StreamBuilder(
                  stream: memberStream,
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() as Map<String, dynamic>?;
                    final joined = snapshot.data?.exists == true;
                    final progress = ((data?['progress'] ?? 0) as num).toInt();
                    final target = 2;
                    final done = progress >= target;

                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Post Twice This Week',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text(done
                                  ? 'Completed! Keep the momentum going 💪'
                                  : 'Make 2 posts this week to build consistency.'),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(value: (progress / target).clamp(0, 1)),
                              const SizedBox(height: 8),
                              Text('$progress / $target posts'),
                              const SizedBox(height: 12),
                              if (!joined)
                                ElevatedButton(
                                  onPressed: () => ref.read(challengeServiceProvider)
                                      .joinChallenge(challengeId: challengeId, uid: uid),
                                  child: const Text('Join Challenge'),
                                )
                              else
                                ElevatedButton(
                                  onPressed: null,
                                  child: Text(done ? 'Completed' : 'Joined'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Challenge error: $e')),
            ),
    );
  }
}
