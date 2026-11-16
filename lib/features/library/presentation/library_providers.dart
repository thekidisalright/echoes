import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/library_repository.dart';
import '../domain/library_source.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => LibraryRepository(ref.watch(appDatabaseProvider)),
);

/// Origens com contagem de livros (Gerenciar biblioteca).
final sourcesProvider = StreamProvider<List<LibrarySource>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchSources(),
);
