/// Todos os textos de UI do Echoes (pt-BR). Ver docs/FEATURES.md.
abstract final class AppStrings {
  static const appName = 'Echoes';

  // Comuns
  static const cancel = 'Cancelar';
  static const save = 'Salvar';
  static const remove = 'Remover';
  static const ok = 'OK';
  static const back = 'Voltar';
  static const untitled = 'Sem título';
  static const unknownAuthor = 'Autor desconhecido';

  // 1.1 Adicionar pasta
  static const importModeTitle = 'Como organizar esta pasta?';
  static const importModeMessage =
      'Escolha como os arquivos de áudio devem virar livros.';
  static const importModeOneBook = 'A pasta inteira é um livro';
  static const importModeBooksInFolders = 'Cada pasta é um livro';
  static const importPreparing = 'Preparando leitura da pasta…';
  static String importReadingFolder(int current, int total) =>
      'Lendo pasta $current de $total…';
  static String importReadingFiles(int count) =>
      'Lendo $count arquivo(s) de áudio…';
  static const importSaving = 'Salvando livros na biblioteca…';
  static const defaultFolderName = 'Pasta de áudio';
  static const importNothingNewTitle = 'Nenhum arquivo novo encontrado';
  static const importNothingNewMessage =
      'Esta pasta não contém áudio compatível que ainda não esteja na biblioteca.';
  static const importFolderErrorTitle = 'Não foi possível importar a pasta';
  static const importFolderErrorMessage =
      'Verifique o acesso à pasta e tente selecioná-la novamente.';

  // 1.2 Adicionar arquivos
  static const selectedFilesSourceName = 'Arquivos selecionados';
  static const noAudioSelectedTitle = 'Nenhum áudio selecionado';
  static const noAudioSelectedMessage = 'Escolha arquivos MP3, M4A ou M4B.';
  static const filesAlreadyAddedTitle = 'Arquivos já adicionados';
  static const filesAlreadyAddedMessage =
      'Todos os arquivos selecionados já estão na biblioteca.';
  static const importFilesErrorTitle = 'Não foi possível adicionar os arquivos';
  static const importFilesErrorMessage =
      'Escolha novamente os arquivos de áudio.';

  // 1.4 Atualizar origem
  static const accessExpiredTitle = 'Acesso à pasta expirou';
  static const accessExpiredMessage =
      'Selecione novamente a pasta original para atualizar este audiobook.';

  // 1.5 Remover origem
  static const removeSourceTitle = 'Remover origem?';
  static String removeSourceMessage(String name) =>
      'Remover “$name” e seus livros da biblioteca? '
      'Os arquivos originais não serão apagados.';

  // 2. Biblioteca
  static const manageLibrary = 'Gerenciar biblioteca';
  static const settings = 'Configurações';
  static const continueListening = 'Continue ouvindo';
  static const searchHint = 'Buscar título ou autor';
  static const library = 'Biblioteca';
  static const sortRecent = 'Recentes';
  static const sortTitle = 'Título';
  static String chapterCount(int count) => '$count capítulos';
  static const sourceUnavailable = 'Pasta indisponível';
  static const sourceUnavailableHint =
      'A pasta deste livro está indisponível. Atualize a origem para continuar.';
  static const emptyLibraryTitle = 'Nenhum audiobook';
  static const emptyLibraryMessage =
      'Toque em Gerenciar biblioteca para adicionar uma pasta ou arquivos.';
  static const noResults = 'Nenhum resultado';
  static const noResultsMessage = 'Tente outro título ou autor.';
  static String listenTo(String title) => 'Ouvir $title';
  static const openBookError = 'Não foi possível abrir este audiobook.';
  static const nowPlaying = 'Tocando agora';
  static const recentlyPlayed = 'Ouvido recentemente';

  // 2.1 Editar audiobook
  static const editBook = 'Editar audiobook';
  static const changeCover = 'Alterar capa';
  static const titleLabel = 'Título';
  static const authorLabel = 'Autor';
  static const restoreOriginal = 'Restaurar dados originais';
  static const editBookError = 'Não foi possível salvar as alterações.';

  // 3. Player
  static const closePlayer = 'Fechar player';
  static const audiobookFallback = 'Audiobook';
  static String chapterOf(int current, int total) =>
      'Capítulo $current de $total';
  static const previousChapter = 'Capítulo anterior';
  static const nextChapter = 'Próximo capítulo';
  static const rewind15 = 'Voltar 15 segundos';
  static const forward15 = 'Avançar 15 segundos';
  static const play = 'Tocar';
  static const pause = 'Pausar';
  static const timer = 'Temporizador';
  static const timerActive = 'Timer ativo';
  static String timerRemaining(int minutes) => 'Timer · $minutes min';
  static const bookmark = 'Marcador';
  static const bookmarkSaved = 'Salvo';
  static const chapters = 'Capítulos';
  static const cancelTimer = 'Desligar temporizador';

  // 3.1 Timer de sono
  static const sleepTimerTitle = 'Temporizador';
  static const sleepTimerMessage = 'Quando deseja pausar?';
  static String sleepTimerMinutes(int minutes) => '$minutes minutos';
  static const sleepTimerEndOfChapter = 'Ao fim do capítulo';

  // 4. MiniPlayer
  static const openPlayer = 'Abrir player';

  // 5. Capítulos e marcadores
  static const chaptersAndBookmarks = 'Capítulos e marcadores';
  static const chaptersSection = 'CAPÍTULOS';
  static const bookmarksSection = 'MARCADORES SALVOS';
  static const bookmarksEmpty = 'Os marcadores aparecem aqui.';
  static const chapterRemoved = 'Capítulo removido';
  static const removeBookmark = 'Remover marcador';

  // 6. Gerenciar biblioteca
  static const addFolder = 'Adicionar pasta';
  static const addFiles = 'Adicionar arquivos';
  static const sourcesSection = 'Pastas e arquivos adicionados';
  static const sourcesEmpty =
      'Nenhuma origem adicionada. Escolha uma pasta ou arquivos acima.';
  static String sourceSummary(int books, {required bool available}) =>
      '$books livro(s) · ${available ? 'disponível' : 'acesso indisponível'}';
  static const refreshSource = 'Atualizar origem';
  static const removeSource = 'Remover origem';

  // 7. Configurações
  static const librarySortTitle = 'Ordem da biblioteca';
  static const librarySortMessage =
      'Escolha como os audiobooks aparecem ao abrir o app.';
  static const librarySortRecent = 'Mais recentes';
  static const librarySortTitleOption = 'Título';
  static const about = 'Sobre';
  static String appVersion(String version) => 'Versão $version';

  // 8. Sistema
  static const notificationChannelName = 'Reprodução';
}
