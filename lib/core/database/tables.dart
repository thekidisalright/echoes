import 'package:drift/drift.dart';

// Tabelas do banco (ver docs/DATA_MODEL.md). Tempos em milissegundos e
// timestamps em epoch ms. As classes de linha geradas terminam em `Row` para
// não colidir com os modelos de domínio.

@DataClassName('SourceRow')
class Sources extends Table {
  /// URI da árvore SAF (pasta) ou `files:<epochMs>` (arquivos soltos).
  TextColumn get id => text()();
  TextColumn get uri => text()();
  TextColumn get name => text()();

  /// `folder` | `files`.
  TextColumn get kind => text()();

  /// `oneBook` | `booksInFolders`; só para `folder`.
  TextColumn get importMode => text().nullable()();
  BoolColumn get available => boolean().withDefault(const Constant(true))();
  IntColumn get lastScannedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('BookRow')
class Books extends Table {
  /// URI do diretório do livro; em `oneBook` e `files`, igual ao `sources.id`.
  TextColumn get id => text()();
  TextColumn get sourceId =>
      text().references(Sources, #id, onDelete: KeyAction.cascade)();
  TextColumn get scannedTitle => text()();
  TextColumn get scannedAuthor => text().withDefault(const Constant(''))();
  TextColumn get scannedCoverPath => text().nullable()();
  TextColumn get customTitle => text().nullable()();
  TextColumn get customAuthor => text().nullable()();
  TextColumn get customCoverPath => text().nullable()();
  IntColumn get totalDurationMs => integer().nullable()();
  IntColumn get chapterCount => integer()();
  IntColumn get lastPlayedAt => integer().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ChapterRow')
@TableIndex(name: 'chapters_book_sort', columns: {#bookId, #sortOrder})
class Chapters extends Table {
  /// URI do arquivo; capítulos internos de M4B (Fase 7): `<uri>#<índice>`.
  TextColumn get id => text()();
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get uri => text()();
  IntColumn get sortOrder => integer()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get durationMs => integer().nullable()();
  IntColumn get startMs => integer().nullable()();
  IntColumn get endMs => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Uma linha por livro com o capítulo e a posição atuais.
@DataClassName('ProgressRow')
class ProgressEntries extends Table {
  @override
  String get tableName => 'progress';

  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get chapterId => text()();
  IntColumn get positionMs => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {bookId};
}

@DataClassName('BookmarkRow')
class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get chapterId => text()();
  IntColumn get positionMs => integer()();
  IntColumn get createdAt => integer()();
}

/// Chave/valor: `lastPlayedBookId`, `librarySort`.
@DataClassName('SettingRow')
class SettingsEntries extends Table {
  @override
  String get tableName => 'settings';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
