import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/strings.dart';
import '../../../core/providers.dart';
import '../../../core/storage/storage_gateway.dart';
import '../../library/domain/library_source.dart';
import '../../library/presentation/library_providers.dart';
import '../data/import_service.dart';
import '../data/library_scanner.dart';
import '../domain/import_mode.dart';
import '../domain/import_progress.dart';
import '../domain/import_result.dart';

final importServiceProvider = Provider<ImportService>(
  (ref) => ImportService(
    storage: ref.watch(storageGatewayProvider),
    scanner: LibraryScanner(
      ref.watch(storageGatewayProvider),
      ref.watch(metadataReaderProvider),
    ),
    library: ref.watch(libraryRepositoryProvider),
    covers: ref.watch(coverStoreProvider),
    filesSourceName: AppStrings.selectedFilesSourceName,
    fallbackFolderName: AppStrings.defaultFolderName,
  ),
);

/// Qual mensagem de erro a UI deve mostrar.
enum ImportErrorKind {
  /// "Não foi possível importar a pasta".
  folder,

  /// "Não foi possível adicionar os arquivos".
  files,

  /// "Acesso à pasta expirou".
  accessExpired,
}

sealed class ImportState {
  const ImportState();
}

class ImportIdle extends ImportState {
  const ImportIdle();
}

class ImportRunning extends ImportState {
  const ImportRunning(this.progress);

  final ImportProgress progress;
}

class ImportFailed extends ImportState {
  const ImportFailed(this.kind);

  final ImportErrorKind kind;
}

final importControllerProvider =
    NotifierProvider<ImportController, ImportState>(ImportController.new);

/// Estado da importação para o banner e os alertas.
///
/// Cada ação devolve o [ImportResult] (para a UI mostrar o alerta certo) ou
/// nulo quando falhou ou outra importação já estava em andamento; a falha
/// fica em [ImportFailed] até [clearError].
class ImportController extends Notifier<ImportState> {
  @override
  ImportState build() => const ImportIdle();

  ImportService get _service => ref.read(importServiceProvider);

  bool get isRunning => state is ImportRunning;

  /// Abre o seletor de pasta. Nulo se cancelado ou ocupado.
  Future<PickedDirectory?> pickDirectory() async {
    if (isRunning) return null;
    try {
      return await _service.pickDirectory();
    } on Exception catch (e) {
      _fail(ImportErrorKind.folder, e);
      return null;
    }
  }

  Future<ImportResult?> importFolder(PickedDirectory dir, ImportMode mode) =>
      _run(
        ImportErrorKind.folder,
        const ImportPreparing(),
        () => _service.importFolder(dir, mode, onProgress: _progress),
      );

  Future<ImportResult?> importFiles() => _run(
    ImportErrorKind.files,
    null,
    () => _service.importFiles(onProgress: _progress),
  );

  Future<ImportResult?> rescan(LibrarySource source) => _run(
    ImportErrorKind.accessExpired,
    const ImportPreparing(),
    () => _service.rescan(source, onProgress: _progress),
  );

  Future<void> remove(LibrarySource source) => _service.remove(source);

  Future<void> refreshAvailability() => _service.refreshAvailability();

  void clearError() {
    if (state is ImportFailed) state = const ImportIdle();
  }

  void _progress(ImportProgress progress) => state = ImportRunning(progress);

  Future<ImportResult?> _run(
    ImportErrorKind errorKind,
    ImportProgress? initial,
    Future<ImportResult> Function() action,
  ) async {
    if (isRunning) return null;
    if (initial != null) state = ImportRunning(initial);
    final watch = Stopwatch()..start();
    try {
      final result = await action();
      state = const ImportIdle();
      debugPrint(
        'Importação: ${result.runtimeType}'
        '${result is ImportCompleted ? ' (${result.bookCount} livros)' : ''}'
        ' em ${watch.elapsedMilliseconds} ms',
      );
      return result;
    } on Exception catch (e) {
      _fail(errorKind, e);
      return null;
    }
  }

  void _fail(ImportErrorKind kind, Object error) {
    debugPrint('Importação falhou ($kind): $error');
    state = ImportFailed(kind);
  }
}
