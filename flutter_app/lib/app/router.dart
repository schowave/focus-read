import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/library/library_screen.dart';
import '../features/book/book_screen.dart';
import '../features/capture/capture_screen.dart';
import '../features/reader/reader_screen.dart';
import '../features/settings/settings_screen.dart';
import '../shared/adaptive/platform_utils.dart';

Page<void> adaptivePage({
  required LocalKey key,
  required Widget child,
}) {
  if (isIOSPlatform) {
    return CupertinoPage(key: key, child: child);
  }
  return MaterialPage(key: key, child: child);
}

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => adaptivePage(
        key: state.pageKey,
        child: const LibraryScreen(),
      ),
    ),
    GoRoute(
      path: '/book/:bookId',
      pageBuilder: (context, state) {
        final bookId = state.pathParameters['bookId']!;
        return adaptivePage(
          key: state.pageKey,
          child: BookScreen(bookId: bookId),
        );
      },
      routes: [
        GoRoute(
          path: 'capture',
          pageBuilder: (context, state) {
            final bookId = state.pathParameters['bookId']!;
            return adaptivePage(
              key: state.pageKey,
              child: CaptureScreen(bookId: bookId),
            );
          },
        ),
        GoRoute(
          path: 'read/:pageId',
          pageBuilder: (context, state) {
            final bookId = state.pathParameters['bookId']!;
            final pageId = state.pathParameters['pageId']!;
            return adaptivePage(
              key: state.pageKey,
              child: ReaderScreen(bookId: bookId, pageId: pageId),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => adaptivePage(
        key: state.pageKey,
        child: const SettingsScreen(),
      ),
    ),
  ],
);
