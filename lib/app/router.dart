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

/// Navigator raiz: usado para alertas que não pertencem a uma tela (falha de
/// importação que termina depois de o usuário sair de Gerenciar).
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Argumento opcional de [AppRoutes.manage]: aviso exibido no topo.
class ManageLibraryArgs {
  const ManageLibraryArgs({this.notice});

  final String? notice;
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
  bool opaque = true,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    fullscreenDialog: fullscreenDialog,
    opaque: opaque,
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
    navigatorKey: rootNavigatorKey,
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
          // A biblioteca aparece por baixo enquanto o Player é arrastado.
          opaque: false,
        ),
      ),
      GoRoute(
        path: AppRoutes.chapters,
        pageBuilder: (context, state) =>
            _slidePage(state, const ChaptersScreen(), begin: _fromRight),
      ),
      GoRoute(
        path: AppRoutes.manage,
        pageBuilder: (context, state) => _slidePage(
          state,
          ManageLibraryScreen(
            notice: (state.extra as ManageLibraryArgs?)?.notice,
          ),
          begin: _fromRight,
        ),
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
