import 'dart:async';

import '../domain/player_state.dart';
import 'progress_repository.dart';

/// Decide quando gravar o progresso (docs/ARCHITECTURE.md → "Salvar
/// progresso"), guiado pelas atualizações do player, sem timers:
///
/// - a cada [interval] de posição enquanto toca;
/// - ao pausar;
/// - ao mudar de capítulo (grava o novo capítulo na posição 0);
/// - em [flush]: antes de trocar de livro, ao ir para segundo plano e ao
///   parar o serviço.
///
/// O primeiro estado de cada livro é só a referência (o livro acabou de ser
/// carregado na posição salva) e não gera gravação.
class ProgressSaver {
  ProgressSaver(
    this._repository, {
    this.interval = const Duration(seconds: 10),
  });

  final ProgressRepository _repository;
  final Duration interval;

  PlaybackSnapshot? _last;
  PlaybackSnapshot? _saved;
  Future<void> _pending = Future.value();

  /// Recebe cada atualização do player.
  void onSnapshot(PlaybackSnapshot snapshot) {
    final previous = _last;
    _last = snapshot;
    if (previous == null || previous.bookId != snapshot.bookId) {
      _saved = snapshot;
      return;
    }
    if (snapshot.chapterId != previous.chapterId) {
      _save(
        PlaybackSnapshot(
          bookId: snapshot.bookId,
          chapterId: snapshot.chapterId,
          position: Duration.zero,
          playing: snapshot.playing,
        ),
      );
    } else if (previous.playing && !snapshot.playing) {
      _save(snapshot);
    } else if (snapshot.playing && _movedSinceSave(snapshot) >= interval) {
      _save(snapshot);
    }
  }

  /// Grava o estado atual se ele mudou desde a última gravação, e espera
  /// as gravações pendentes.
  Future<void> flush() {
    final last = _last;
    if (last != null && !_sameAsSaved(last)) _save(last);
    return _pending;
  }

  /// Esquece o livro atual (depois de [flush], ao descarregar o livro).
  void reset() {
    _last = null;
    _saved = null;
  }

  Duration _movedSinceSave(PlaybackSnapshot s) {
    final saved = _saved;
    if (saved == null || saved.chapterId != s.chapterId) return interval;
    return (s.position - saved.position).abs();
  }

  bool _sameAsSaved(PlaybackSnapshot s) {
    final saved = _saved;
    return saved != null &&
        saved.bookId == s.bookId &&
        saved.chapterId == s.chapterId &&
        saved.position == s.position;
  }

  void _save(PlaybackSnapshot s) {
    _saved = s;
    _pending = _pending.then((_) async {
      try {
        await _repository.saveProgress(s.bookId, s.chapterId, s.position);
        await _repository.touchLastPlayed(s.bookId);
      } on Exception {
        // Falha ao gravar não pode derrubar a reprodução; a próxima
        // gravação tenta de novo.
        _saved = null;
      }
    });
  }
}
