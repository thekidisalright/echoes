import '../../../core/files/cover_store.dart';
import 'library_repository.dart';

/// Edição de título, autor e capa de um livro (diálogo "Editar audiobook").
class BookEditor {
  BookEditor({required this._library, required this._covers});

  final LibraryRepository _library;
  final CoverStore _covers;

  /// Grava a edição. [imagePath] é a imagem escolhida pelo usuário (copiada
  /// para o diretório de capas); nulo mantém a capa atual.
  Future<void> save(
    String bookId, {
    required String title,
    required String author,
    String? imagePath,
  }) async {
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'não pode ser vazio');
    }
    final coverPath = imagePath == null
        ? null
        : await _covers.saveCustom(bookId, imagePath);
    await _library.updateBookDetails(
      bookId,
      title: title,
      author: author,
      coverPath: coverPath,
    );
    await _covers.deleteOrphans(await _library.coverPathsInUse());
  }

  /// Volta aos dados da importação e apaga a capa personalizada.
  Future<void> reset(String bookId) async {
    await _library.resetBookDetails(bookId);
    await _covers.removeCustom(bookId);
  }
}
