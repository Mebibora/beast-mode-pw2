import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase_providers.dart';
import '../../../models/activity.dart';
import '../../../models/comment.dart';

import '../../auth/auth_controller.dart';
import '../../workouts/screens/log_workout_screen.dart';
import '../../challenges/screens/weekly_challenge_screen.dart';


import '../feed_providers.dart';
import '../feed_interactions_providers.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(publicFeedProvider);
    final uid = ref.watch(currentUidProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beast Mode - Feed'),
        actions: [
          IconButton(
            tooltip: 'Weekly Challenge',
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WeeklyChallengeScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Log Workout',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LogWorkoutScreen()),
            ),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: feed.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No activity yet—log your first workout!'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final item = items[i];
              return _ActivityCard(
                item: item,
                isMe: uid != null && item.uid == uid,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final msg = e.toString();
          final building = msg.contains('currently building');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                building
                    ? 'Feed index is building in Firebase. Try again in a moment.'
                    : 'Feed error: $e',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActivityCard extends ConsumerWidget {
  final Activity item;
  final bool isMe;

  const _ActivityCard({required this.item, required this.isMe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUidProvider);

    final subtitle = switch (item.type) {
      'workout' => 'Logged a workout',
      'journal' => 'Posted a journal update',
      'challenge_join' => 'Joined a challenge',
      'challenge_progress' => 'Challenge progress',
      'text' => 'Posted an update',
      _ => 'Activity',
    };

    // Like state (live)
    final likedAsync = (uid == null)
        ? const AsyncValue<bool>.data(false)
        : ref.watch(likedByMeProvider((activityId: item.id, uid: uid)));

    final likedByMe = likedAsync.value ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    isMe ? 'You' : item.uid, // later: replace with displayName
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text('• $subtitle'),
              ],
            ),

            // Body text (optional)
            if (item.text != null && item.text!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(item.text!),
            ],

            const SizedBox(height: 10),

            // Actions row
            Row(
              children: [
                IconButton(
                  tooltip: likedByMe ? 'Unlike' : 'Like',
                  icon: Icon(likedByMe ? Icons.favorite : Icons.favorite_border),
                  onPressed: uid == null
                      ? null
                      : () async {
                          final svc = ref.read(feedInteractionsServiceProvider);
                          try {
                            if (likedByMe) {
                              await svc.unlike(activityId: item.id, uid: uid);
                            } else {
                              await svc.like(activityId: item.id, uid: uid);
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Like failed: $e')),
                            );
                          }
                        },
                ),
                Text('${item.likeCount}'),

                const SizedBox(width: 12),

                IconButton(
                  tooltip: 'Comments',
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => _CommentsSheet(activityId: item.id),
                    );
                  },
                ),
                Text('${item.commentCount}'),

                const Spacer(),

                Text(
                  _formatTimestamp(item.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsSheet extends ConsumerStatefulWidget {
  final String activityId;
  const _CommentsSheet({required this.activityId});

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    final text = _controller.text;
    if (text.trim().isEmpty) return;

    setState(() => _sending = true);
    try {
      await ref.read(feedInteractionsServiceProvider).addComment(
            activityId: widget.activityId,
            uid: uid,
            text: text,
          );
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Comment failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUidProvider);
    final svc = ref.watch(feedInteractionsServiceProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Comments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            SizedBox(
              height: 320,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: svc.commentsStream(widget.activityId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Comments error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  final comments = docs.map((d) => Comment.fromDoc(d)).toList();

                  if (comments.isEmpty) {
                    return const Center(child: Text('No comments yet.'));
                  }

                  // We used orderBy(createdAt desc), so newest is first.
                  return ListView.separated(
                    itemCount: comments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = comments[i];
                      final canDelete = uid != null && c.uid == uid;

                      return ListTile(
                        title: Text(c.text),
                        subtitle: Text(
                          '${c.uid} • ${_formatTimestamp(c.createdAt)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: canDelete
                            ? IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  try {
                                    await svc.deleteComment(
                                      activityId: widget.activityId,
                                      commentId: c.id,
                                    );
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Delete failed: $e')),
                                      );
                                    }
                                  }
                                },
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment…',
                      border: OutlineInputBorder(),
                    ),
                    enabled: uid != null && !_sending,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Send',
                  icon: _sending ? const CircularProgressIndicator() : const Icon(Icons.send),
                  onPressed: (uid == null || _sending) ? null : _send,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple timestamp formatter (keeps it dependency-free).
String _formatTimestamp(DateTime dt) {
  final local = dt.toLocal();
  final two = (int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}
