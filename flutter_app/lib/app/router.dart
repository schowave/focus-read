import 'package:go_router/go_router.dart';
import '../features/library/library_screen.dart';
import '../features/book/book_screen.dart';
import '../features/capture/capture_screen.dart';
import '../features/reader/reader_screen.dart';
import '../features/settings/settings_screen.dart';

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
            return ReaderScreen(bookId: bookId, pageId: pageId);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
