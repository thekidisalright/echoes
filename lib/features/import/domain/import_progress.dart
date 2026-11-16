/// Etapa da importação em andamento, para o banner de progresso.
sealed class ImportProgress {
  const ImportProgress();
}

class ImportPreparing extends ImportProgress {
  const ImportPreparing();
}

/// Modo `booksInFolders`: lendo a pasta [current] de [total] (1-based).
class ImportReadingFolder extends ImportProgress {
  const ImportReadingFolder(this.current, this.total);

  final int current;
  final int total;
}

/// Modo `oneBook` e arquivos soltos: lendo [count] arquivos de áudio.
class ImportReadingFiles extends ImportProgress {
  const ImportReadingFiles(this.count);

  final int count;
}

class ImportSaving extends ImportProgress {
  const ImportSaving();
}
