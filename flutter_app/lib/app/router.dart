import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/library/library_screen.dart';
import '../features/book/book_screen.dart';
import '../features/capture/capture_screen.dart';

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
        final bookId = state.pathParameters['bookId']!;
        return BookScreen(bookId: bookId);
      },
      routes: [
        GoRoute(
          path: 'capture',
          builder: (context, state) {
            final bookId = state.pathParameters['bookId']!;
            return CaptureScreen(bookId: bookId);
          },
        ),
        GoRoute(
          path: 'read/:pageId',
          builder: (context, state) {
            final bookId = state.pathParameters['bookId']!;
            final pageId = state.pathParameters['pageId']!;
            // Placeholder until ReaderScreen is implemented (Task 12)
            return _PlaceholderScreen(
                title: 'Reader (book: $bookId, page: $pageId)');
          },
        ),
      ],
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
