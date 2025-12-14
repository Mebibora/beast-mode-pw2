import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase_providers.dart';
import '../workout_providers.dart';

class LogWorkoutScreen extends ConsumerStatefulWidget {
  const LogWorkoutScreen({super.key});

  @override
  ConsumerState<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends ConsumerState<LogWorkoutScreen> {
  final _type = TextEditingController(text: 'Strength');
  final _duration = TextEditingController(text: '45');
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _type.dispose();
    _duration.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    final duration = int.tryParse(_duration.text.trim());
    if (duration == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid duration.')));
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(workoutServiceProvider).logWorkout(
            uid: uid,
            type: _type.text.trim(),
            durationMins: duration,
            notes: _notes.text.trim(),
            visibility: 'public', // default
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to log workout: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Workout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _type, decoration: const InputDecoration(labelText: 'Type (e.g., Cardio)')),
            TextField(
              controller: _duration,
              decoration: const InputDecoration(labelText: 'Duration (minutes)'),
              keyboardType: TextInputType.number,
            ),
            TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes (optional)')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const CircularProgressIndicator() : const Text('Post to Feed'),
            ),
          ],
        ),
      ),
    );
  }
}
