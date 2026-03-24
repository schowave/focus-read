import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/library/library_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LibraryScreen(),
    ),
    GoRoute(
      path: '/book/:bookId',
      builder: (context, state) {
        // Placeholder until BookDetailScreen is implemented (Task 10)
        return const _PlaceholderScreen(title: 'Book');
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) =>
          const _PlaceholderScreen(title: 'Settings'),
    ),
  ],
);

/// Temporary placeholder screen until feature screens are implemented.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title — coming soon')),
    );
  }
}
