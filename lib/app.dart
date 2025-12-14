import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/firebase_providers.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/feed/screens/feed_screen.dart';

class BeastModeApp extends ConsumerWidget {
  const BeastModeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp(
      title: 'Beast Mode',
      theme: ThemeData(useMaterial3: true),
      home: authState.when(
        data: (user) => user == null ? const LoginScreen() : const FeedScreen(),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('Auth error: $e'))),
      ),
    );
  }
}
