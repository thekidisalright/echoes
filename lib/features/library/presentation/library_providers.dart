import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../settings/presentation/settings_providers.dart';
import '../data/book_editor.dart';
import '../data/library_repository.dart';
import '../domain/book_summary.dart';
import '../domain/library_source.dart';
import '../domain/sort_order.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => LibraryRepository(ref.watch(appDatabaseProvider)),
);

final bookEditorProvider = Provider<BookEditor>(
  (ref) => BookEditor(
    library: ref.watch(libraryRepositoryProvider),
    covers: ref.watch(coverStoreProvider),
  ),
);

/// Texto do campo de busca da biblioteca.
final librarySearchProvider = NotifierProvider<LibrarySearch, String>(
  LibrarySearch.new,
);

class LibrarySearch extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

/// Grade da biblioteca, filtrada pela busca e na ordem salva.
final libraryBooksProvider = StreamProvider<List<BookSummary>>((ref) {
  final query = ref.watch(librarySearchProvider);
  final sort = ref.watch(librarySortProvider).value ?? SortOrder.recent;
  return ref
      .watch(libraryRepositoryProvider)
      .watchLibrary(query: query, sort: sort);
});

/// "Continue ouvindo": até 3 livros tocados recentemente.
final continueListeningProvider = StreamProvider<List<BookSummary>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchContinueListening(),
);

/// Origens com contagem de livros (Gerenciar biblioteca).
final sourcesProvider = StreamProvider<List<LibrarySource>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchSources(),
);
