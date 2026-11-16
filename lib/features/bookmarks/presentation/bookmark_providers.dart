import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../player/presentation/player_providers.dart';
import '../data/bookmark_repository.dart';
import '../domain/bookmark.dart';

final bookmarkRepositoryProvider = Provider<BookmarkRepository>(
  (ref) => BookmarkRepository(ref.watch(appDatabaseProvider)),
);

/// Marcadores do livro carregado no player, mais recentes primeiro.
final currentBookmarksProvider = StreamProvider<List<Bookmark>>((ref) {
  final bookId = ref.watch(
    playerStateProvider.select((s) => s.value?.book?.id),
  );
  if (bookId == null) return Stream.value(const []);
  return ref.watch(bookmarkRepositoryProvider).watchByBook(bookId);
});
