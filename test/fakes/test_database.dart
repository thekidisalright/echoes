import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:echoes/core/database/app_database.dart';
import 'package:echoes/features/import/domain/import_mode.dart';
import 'package:echoes/features/import/domain/scanned_source.dart';
import 'package:echoes/features/library/domain/library_source.dart';

/// Banco em memória para testes de repositório.
AppDatabase memoryDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// Relógio controlável: cada chamada a [tick] avança um segundo.
class FakeClock {
  FakeClock([DateTime? start]) : now = start ?? DateTime(2026, 1, 1);

  DateTime now;

  DateTime call() => now;

  void tick([Duration by = const Duration(seconds: 1)]) => now = now.add(by);
}

ScannedChapter chapter(String id, {int? durationMs, String? title}) =>
    ScannedChapter(
      id: id,
      title: title ?? id,
      uri: id,
      duration: durationMs == null ? null : Duration(milliseconds: durationMs),
    );

ScannedBook book(
  String id,
  List<ScannedChapter> chapters, {
  String? title,
  String author = '',
  String? coverPath,
}) => ScannedBook(
  id: id,
  title: title ?? id,
  author: author,
  coverPath: coverPath,
  chapters: chapters,
);

ScannedSource folder(
  String id,
  List<ScannedBook> books, {
  ImportMode mode = ImportMode.booksInFolders,
  String? name,
}) => ScannedSource(
  id: id,
  uri: id,
  name: name ?? id,
  kind: SourceKind.folder,
  importMode: mode,
  books: books,
);
