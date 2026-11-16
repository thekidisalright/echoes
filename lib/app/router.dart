import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/chapters/presentation/chapters_screen.dart';
import '../features/import/presentation/manage_library_screen.dart';
import '../features/library/presentation/library_screen.dart';
import '../features/player/presentation/player_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

abstract final class AppRoutes {
  static const library = '/';
  static const player = '/player';
  static const chapters = '/chapters';
  static const manage = '/manage';
  static const settings = '/settings';
}

const _transitionDuration = Duration(milliseconds: 300);
const _fromRight = Offset(1, 0);
const _fromBottom = Offset(0, 1);

/// Página que entra deslizando a partir de [begin] (ver docs/UI.md → Movimento).
CustomTransitionPage<void> _slidePage(
  GoRouterState state,
  Widget child, {
  required Offset begin,
  bool fullscreenDialog = false,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    fullscreenDialog: fullscreenDialog,
    transitionDuration: _transitionDuration,
    reverseTransitionDuration: _transitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween(begin: begin, end: Offset.zero).animate(curved),
        child: child,
      );
    },
  );
}

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: AppRoutes.library,
    routes: [
      GoRoute(
        path: AppRoutes.library,
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const LibraryScreen()),
      ),
      GoRoute(
        path: AppRoutes.player,
        pageBuilder: (context, state) => _slidePage(
          state,
          const PlayerScreen(),
          begin: _fromBottom,
          fullscreenDialog: true,
        ),
      ),
      GoRoute(
        path: AppRoutes.chapters,
        pageBuilder: (context, state) =>
            _slidePage(state, const ChaptersScreen(), begin: _fromRight),
      ),
      GoRoute(
        path: AppRoutes.manage,
        pageBuilder: (context, state) =>
            _slidePage(state, const ManageLibraryScreen(), begin: _fromRight),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) =>
            _slidePage(state, const SettingsScreen(), begin: _fromRight),
      ),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter();
  ref.onDispose(router.dispose);
  return router;
});
