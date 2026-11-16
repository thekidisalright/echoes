import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;
import 'package:rxdart/rxdart.dart';

import '../../library/data/library_repository.dart';
import '../../library/domain/book.dart';
import '../../library/domain/chapter.dart';
import '../../settings/data/settings_repository.dart';
import '../domain/player_state.dart';
import 'echoes_audio_handler.dart';
import 'progress_repository.dart';
import 'progress_saver.dart';

/// API do player para a UI: abrir livro, tocar, pausar, pular.
///
/// Publica [state] (livro, capítulo, tocando…) e [position] separados.
class PlaybackController {
  PlaybackController({
    required this._handler,
    required this._library,
    required this._progress,
    required this._settings,
    required this._saver,
  }) {
    _state = Rx.combineLatest5(
      _book,
      _handler.currentIndexStream,
      _handler.playingStream,
      _handler.processingStateStream,
      _handler.durationStream,
      _buildState,
    ).where((_) => !_loading).shareValueSeeded(PlayerState.empty);

    _snapshots =
        Rx.combineLatest4(
              _book,
              _handler.currentIndexStream,
              _handler.playingStream,
              _handler.positionStream,
              _buildSnapshot,
            )
            .where((s) => s != null && !_loading)
            .cast<PlaybackSnapshot>()
            .listen(_saver.onSnapshot);
    _handler.onBeforeStop = _saver.flush;
  }

  final EchoesAudioHandler _handler;
  final LibraryRepository _library;
  final ProgressRepository _progress;
  final SettingsRepository _settings;
  final ProgressSaver _saver;

  final _book = BehaviorSubject<_LoadedBook?>.seeded(null);
  late final ValueStream<PlayerState> _state;
  late final StreamSubscription<PlaybackSnapshot> _snapshots;

  /// Verdadeiro enquanto um livro novo carrega: os eventos do player ainda
  /// misturam o livro anterior com o novo e não podem ser salvos.
  bool _loading = false;

  Stream<PlayerState> get state => _state;
  PlayerState get currentState => _state.value;
  Stream<Duration> get position => _handler.positionStream;

  String? get currentBookId => _book.value?.book.id;

  /// Posição atual dentro do capítulo (para criar marcadores).
  Duration get currentPosition => _handler.position;

  /// Abre o livro no capítulo e na posição salvos. Se já é o livro atual,
  /// só toca (com [autoplay]). Devolve falso se o livro não existe mais.
  Future<bool> openBook(String bookId, {bool autoplay = false}) async {
    if (currentBookId == bookId) {
      if (autoplay) await play();
      return true;
    }
    final book = await _library.getBook(bookId);
    final chapters = await _library.chaptersOf(bookId);
    if (book == null || chapters.isEmpty) return false;

    final saved = await _progress.getProgress(bookId);
    final savedIndex = saved == null
        ? -1
        : chapters.indexWhere((c) => c.id == saved.chapterId);
    final index = savedIndex < 0 ? 0 : savedIndex;
    final position = savedIndex < 0 ? Duration.zero : saved!.position;

    _loading = true;
    try {
      await _saver.flush();
      _saver.reset();
      await _handler.load(
        [for (final c in chapters) _mediaItem(book, c)],
        index: index,
        position: position,
      );
      _loading = false;
      _book.add(_LoadedBook(book, chapters));
    } catch (_) {
      _loading = false;
      _book.add(null);
      await _handler.unload();
      rethrow;
    }

    await _settings.setLastPlayedBookId(bookId);
    if (autoplay) {
      await _progress.touchLastPlayed(bookId);
      await play();
    }
    return true;
  }

  /// Reabre o último livro tocado, sem tocar (início do app).
  Future<void> restoreLastBook() async {
    final id = await _settings.getLastPlayedBookId();
    if (id == null || currentBookId != null) return;
    if (!await openBook(id)) await _settings.setLastPlayedBookId(null);
  }

  /// Salva e descarrega o livro atual (ex.: a origem dele foi removida).
  Future<void> close() async {
    await _saver.flush();
    _saver.reset();
    _book.add(null);
    await _handler.unload();
  }

  Future<void> play() async {
    if (currentBookId == null) return;
    await _handler.play();
  }

  Future<void> pause() => _handler.pause();

  Future<void> togglePlay() => _handler.playing ? pause() : play();

  Future<void> seek(Duration position) => _handler.seek(position);

  Future<void> rewind() => _handler.rewind();

  Future<void> fastForward() => _handler.fastForward();

  Future<void> nextChapter() => _handler.skipToNext();

  Future<void> previousChapter() => _handler.skipToPrevious();

  /// Vai para o início do capítulo [index] e toca.
  Future<void> playChapter(int index) async {
    await _handler.skipToQueueItem(index);
    await play();
  }

  /// Vai ao capítulo [chapterId] na [position] e toca (marcadores).
  /// Devolve falso se o capítulo não está no livro carregado.
  Future<bool> playAt(String chapterId, Duration position) async {
    final chapters = _book.value?.chapters ?? const <Chapter>[];
    final index = chapters.indexWhere((c) => c.id == chapterId);
    if (index < 0) return false;
    await _handler.seekInChapter(index, position);
    await play();
    return true;
  }

  /// Salva agora (app indo para segundo plano).
  Future<void> saveNow() => _saver.flush();

  Future<void> dispose() async {
    await _snapshots.cancel();
    await _book.close();
  }

  static MediaItem _mediaItem(Book book, Chapter chapter) => MediaItem(
    id: chapter.uri,
    title: chapter.title,
    artist: book.author.isEmpty ? null : book.author,
    album: book.title,
    duration: chapter.duration,
    artUri: book.coverPath == null ? null : Uri.file(book.coverPath!),
  );

  static PlayerState _buildState(
    _LoadedBook? loaded,
    int? index,
    bool playing,
    ProcessingState processing,
    Duration? duration,
  ) {
    if (loaded == null) return PlayerState.empty;
    final i = (index ?? 0).clamp(0, loaded.chapters.length - 1);
    return PlayerState(
      book: loaded.book,
      chapters: loaded.chapters,
      chapterIndex: i,
      duration: duration ?? loaded.chapters[i].duration,
      playing: playing && processing != ProcessingState.completed,
      buffering:
          processing == ProcessingState.loading ||
          processing == ProcessingState.buffering,
      completed: processing == ProcessingState.completed,
    );
  }

  static PlaybackSnapshot? _buildSnapshot(
    _LoadedBook? loaded,
    int? index,
    bool playing,
    Duration position,
  ) {
    if (loaded == null || index == null) return null;
    if (index < 0 || index >= loaded.chapters.length) return null;
    return PlaybackSnapshot(
      bookId: loaded.book.id,
      chapterId: loaded.chapters[index].id,
      position: position,
      playing: playing,
    );
  }
}

class _LoadedBook {
  const _LoadedBook(this.book, this.chapters);

  final Book book;
  final List<Chapter> chapters;
}
