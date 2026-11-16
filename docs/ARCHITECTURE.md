# Arquitetura — Echoes (Flutter)

## Visão geral

```
┌──────────────────────────── presentation ────────────────────────────┐
│  Screens / Widgets  ──ref.watch/ref.read──►  Providers (Riverpod)     │
└───────────────────────────────────┬──────────────────────────────────┘
                                    │
┌──────────────────────────── data / services ─────────────────────────┐
│  LibraryRepository   ImportService   PlaybackController   Progress…  │
└──────┬───────────────────┬───────────────────┬───────────────────────┘
       │                   │                   │
   drift (SQLite)    StorageGateway      EchoesAudioHandler
                     MetadataReader      (audio_service + just_audio)
                     (core/, interfaces)
```

- **presentation** conhece apenas providers e modelos de domínio.
- **data/services** orquestram; são os únicos que falam com banco e plataforma.
- **core** contém infraestrutura compartilhada e as interfaces de plataforma.

## Pacotes

| Pacote | Uso | Por quê |
|---|---|---|
| `flutter_riverpod` | Estado e injeção de dependência | Providers pequenos, testáveis, sem `BuildContext` na lógica; `overrideWith` facilita testes com fakes |
| `go_router` | Navegação | Rotas declarativas; player como rota modal |
| `just_audio` | Motor de reprodução | Playlists de arquivos locais e URIs `content://`, posição inicial ao carregar fonte |
| `audio_service` | Serviço em primeiro plano, notificação, tela de bloqueio, botões de fone | Padrão do ecossistema para áudio em segundo plano |
| `audio_session` | Foco de áudio | Preset `speech`: pausa em ligações, pausa ao desconectar fone |
| `docman` | Storage Access Framework | Seletor de pasta/arquivos e permissões persistidas. **Listagem e leitura de trechos não usam o docman**: são feitas pelo canal nativo `SafChannel` (ver Android) |
| `metadata_audio` | Tags, duração, capa embutida, capítulos de M4B | Port Dart do `music-metadata` (mesma base da versão antiga). Lê `content://` por meio de um `Tokenizer` esparso alimentado por `readRange`. **Fallback:** `flutter_taglib` |
| `material_ui` | Widgets Material | No Flutter 3.50+ o Material saiu do SDK; importar `package:material_ui/material_ui.dart` |
| `drift` + `drift_flutter` + `drift_dev` + `build_runner` | Banco SQLite | SQL tipado, migrações versionadas, consultas reativas |
| `path_provider` | Diretório de suporte do app | Onde ficam capas extraídas |
| `image_picker` | Escolher capa personalizada | Galeria do sistema, sem permissão de armazenamento. Fica atrás de `ImageGateway` (`core/images/`) |
| `package_info_plus` | Versão do app na seção "Sobre" | Lê o `versionName` instalado; atrás de `AppInfo` (`core/app_info/`) |
| `ionicons` | Ícones | Mantém exatamente o visual da versão anterior |
| `crypto` | Hash para nomes de arquivo de capa | Nome estável a partir do ID do livro |
| `rxdart` | Combinação de streams no player | Já é dependência transitiva do just_audio |

Fontes **Cormorant Garamond** (400, 500, 700) são empacotadas em `assets/fonts/` (sem download em runtime).

> Validado na Fase 0 (ver "Registro de decisões" em `docs/PLAN.md`): o `docman` sozinho listava devagar demais, por isso listagem e leitura de trechos usam o canal nativo próprio.

## Estrutura de pastas

```
lib/
  main.dart                      → inicializa AudioService, banco, ProviderScope
  app/
    app.dart                     → MaterialApp.router
    router.dart                  → rotas go_router
    strings.dart                 → todos os textos de UI (pt-BR)
    theme/
      colors.dart                → tokens de cor (ver docs/UI.md)
      typography.dart            → estilos de texto
      spacing.dart               → espaçamentos e raios
      theme.dart                 → ThemeData
    widgets/
      screen_header.dart         → voltar + título das telas secundárias
      dialogs.dart               → alerta e confirmação no estilo do app
  core/
    database/
      app_database.dart          → definição drift, versão do schema, migrações
      tables.dart                → tabelas
    storage/
      storage_gateway.dart       → interface: pickDirectory, pickAudioFiles, listTree, readRange, persistedUris, releasePermission
      saf_storage_gateway.dart   → implementação SAF (docman para seletor/permissões + canal nativo para listTree/readRange)
    providers.dart               → providers de infraestrutura (banco, storage, metadados, capas)
    metadata/
      metadata_reader.dart       → interface: read(uri) → AudioFileMetadata
      metadata_audio_reader.dart → implementação (com o tokenizer esparso sobre readRange)
    files/
      cover_store.dart           → salva/remove capas em <appSupport>/covers/
    images/
      image_gateway.dart         → interface: pickImage() (capa personalizada)
      image_picker_gateway.dart  → implementação com image_picker
    app_info/
      app_info.dart              → interface: version()
      package_app_info.dart      → implementação com package_info_plus
    utils/
      natural_sort.dart          → comparação natural de nomes
      file_names.dart            → cleanTitle, parseTrackNumber, isAudio, isImage, isPreferredCover
      duration_format.dart       → "1h 05m", "12:34", "-03:21"
  features/
    library/
      domain/                    → Book, Chapter, LibrarySource, BookSummary, SortOrder
      data/library_repository.dart
      data/book_editor.dart      → salva/restaura título, autor e capa (CoverStore)
      presentation/
        library_screen.dart
        open_book.dart           → toque num livro: abre no player ou leva a Gerenciar
        widgets/ (book_cover, book_grid_item, continue_listening_item, search_field, sort_chips, empty_state, book_edit_dialog)
        library_providers.dart
    import/
      domain/                    → ImportMode, ScannedBook, ImportProgress, ImportResult
      data/
        library_scanner.dart     → percorre a árvore e agrupa em livros (puro, usa StorageGateway + MetadataReader)
        import_service.dart      → orquestra scanner + repository + cover_store
      presentation/
        manage_library_screen.dart
        widgets/ (import_mode_dialog, source_tile, import_status_banner)
        import_providers.dart
    player/
      domain/                    → PlayerState (livro atual, índice, posição, duração, tocando)
      data/
        echoes_audio_handler.dart→ BaseAudioHandler + just_audio
        playback_controller.dart → API usada pela UI: openBook, play, pause, seek, skip, playChapter
        progress_saver.dart      → regras de salvamento de progresso
      presentation/
        player_screen.dart
        widgets/ (mini_player, player_controls, seek_bar)
        player_providers.dart
    chapters/
      presentation/chapters_screen.dart
    bookmarks/
      domain/bookmark.dart
      data/bookmark_repository.dart
      presentation/bookmark_providers.dart
    sleep_timer/
      data/sleep_timer_service.dart
      presentation/sleep_timer_sheet.dart
    settings/
      data/settings_repository.dart
      presentation/settings_screen.dart
test/
  (espelha lib/)
  fakes/                         → FakeStorageGateway, FakeMetadataReader, FakeAudioHandler
```

## Fluxos principais

### Importar pasta
1. UI chama `importService.pickDirectory()` → `StorageGateway` abre o seletor SAF e **persiste a permissão**.
2. UI pergunta o `ImportMode` (diálogo) — responsabilidade da UI.
3. `ImportService` chama `LibraryScanner.scan(root, mode, skipUris)`:
   - lista recursivamente; diretórios com ao menos um áudio viram grupos;
   - modo `oneBook`: todos os áudios da árvore → 1 livro; modo `booksInFolders`: cada grupo → 1 livro;
   - ordena faixas (número de faixa no nome → natural sort);
   - lê metadados de cada faixa; extrai capa (preferida da pasta → embutida → primeira imagem da pasta).
   - emite `ImportProgress` ("Lendo pasta 3 de 12…") por stream.
4. `ImportService` grava capas via `CoverStore` e salva tudo via `LibraryRepository.saveScannedSource` numa transação.
5. A UI da biblioteca atualiza sozinha pelo stream do drift.

### Abrir e tocar um livro
1. UI chama `playbackController.openBook(bookId, autoplay: …)`.
2. Controller carrega capítulos + progresso do repositório.
3. `EchoesAudioHandler` recebe a lista de capítulos, publica a `queue` (um `MediaItem` por capítulo) e carrega as fontes no just_audio **já com índice e posição iniciais** — sem seek posterior, sem atraso.
4. `ProgressSaver` passa a observar o player.

### Salvar progresso (`ProgressSaver`)
Grava `(bookId, chapterId, positionMs)` e atualiza `lastPlayedAt` quando:
- a cada 10 s enquanto toca;
- ao pausar;
- ao mudar de capítulo (grava o novo capítulo na posição 0);
- ao trocar de livro (grava o livro anterior antes);
- quando o app vai para segundo plano (`AppLifecycleState.paused`/`detached`);
- ao parar o serviço.

### Reabrir o app
`main` → controller lê `settings.lastPlayedBookId` → abre o livro **sem tocar**, para o MiniPlayer aparecer pronto.

### Disponibilidade de origens
Na inicialização e ao voltar ao primeiro plano, `ImportService.refreshAvailability()` compara as origens salvas com as permissões persistidas do SAF e marca `sources.available`. **Não** há checagem de existência arquivo por arquivo a cada listagem.

## Android

- `MainActivity` estende `AudioServiceActivity` e registra o `SafChannel` (`android/app/src/main/kotlin/dev/alexandre/echoes/SafChannel.kt`): canal `dev.alexandre.echoes/saf` com `listTree(uri)` (uma consulta `ContentResolver` por pasta, em thread própria) e `readRange(uri, start, length)` (leitura com seek via `FileChannel`).
- `AndroidManifest.xml`: `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `WAKE_LOCK`, `POST_NOTIFICATIONS`; service e receiver do audio_service conforme documentação do pacote.
- `applicationId`: `dev.alexandre.echoes`.
- Nome exibido: `Echoes`. Ícone: vetor adaptativo próprio em `res/drawable/ic_launcher_*.xml` + `res/mipmap-anydpi-v26/ic_launcher.xml` (com monocromático); PNGs legados em `res/mipmap-*/` para API 24–25. Os PNGs de `assets/images/` são placeholders do Expo e não são usados.
