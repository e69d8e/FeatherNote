import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/notes/presentation/screens/note_list_screen.dart';
import '../../features/notes/presentation/screens/note_edit_screen.dart';
import '../../features/notes/presentation/screens/note_search_screen.dart';
import '../../features/archive_trash/presentation/screens/archive_screen.dart';
import '../../features/archive_trash/presentation/screens/trash_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

/// 全局路由 Provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const NoteListScreen(),
        routes: [
          GoRoute(
            path: 'edit/:id',
            name: 'note_edit',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'];
              return CustomTransitionPage(
                key: state.pageKey,
                child: NoteEditScreen(noteId: id),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 0.04);
                  const end = Offset.zero;
                  final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: begin, end: end).animate(curve),
                      child: child,
                    ),
                  );
                },
              );
            },
          ),
          GoRoute(
            path: 'search',
            name: 'note_search',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const NoteSearchScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: 'archive',
            name: 'archive',
            builder: (context, state) => const ArchiveScreen(),
          ),
          GoRoute(
            path: 'trash',
            name: 'trash',
            builder: (context, state) => const TrashScreen(),
          ),
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
