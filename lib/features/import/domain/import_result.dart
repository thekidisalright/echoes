/// Como terminou uma importação que não deu erro.
sealed class ImportResult {
  const ImportResult();
}

/// O usuário fechou o seletor.
class ImportCancelled extends ImportResult {
  const ImportCancelled();
}

/// Nenhum áudio compatível que ainda não esteja na biblioteca.
class ImportNothingNew extends ImportResult {
  const ImportNothingNew();
}

/// Nenhum dos arquivos escolhidos é MP3, M4A ou M4B.
class ImportNoAudioSelected extends ImportResult {
  const ImportNoAudioSelected();
}

/// Todos os arquivos escolhidos já estão na biblioteca.
class ImportFilesAlreadyAdded extends ImportResult {
  const ImportFilesAlreadyAdded();
}

class ImportCompleted extends ImportResult {
  const ImportCompleted(this.bookCount);

  final int bookCount;
}
