import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/library_repository.dart';
import '../domain/book_summary.dart';
import '../domain/library_source.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => LibraryRepository(ref.watch(appDatabaseProvider)),
);

/// Grade da biblioteca. PROVISÓRIO (Fase 4): sem busca nem ordenação, que
/// chegam na Fase 5.2.
final libraryBooksProvider = StreamProvider<List<BookSummary>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchLibrary(),
);

/// Origens com contagem de livros (Gerenciar biblioteca).
final sourcesProvider = StreamProvider<List<LibrarySource>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchSources(),
);
