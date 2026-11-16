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
| `docman` | Storage Access Framework | Escolher pasta, permissão persistente, listar recursivamente, ler arquivos |
| `metadata_audio` | Tags, duração, capa embutida, capítulos de M4B | Port Dart do `music-metadata` (mesma base da versão antiga). **Fallback:** `flutter_taglib` |
| `drift` + `drift_flutter` + `drift_dev` + `build_runner` | Banco SQLite | SQL tipado, migrações versionadas, consultas reativas |
| `path_provider` | Diretório de suporte do app | Onde ficam capas extraídas |
| `image_picker` | Escolher capa personalizada | Galeria do sistema, sem permissão de armazenamento |
| `ionicons` | Ícones | Mantém exatamente o visual da versão anterior |
| `crypto` | Hash para nomes de arquivo de capa | Nome estável a partir do ID do livro |
| `rxdart` | Combinação de streams no player | Já é dependência transitiva do just_audio |

Fontes **Cormorant Garamond** (400, 500, 700) são empacotadas em `assets/fonts/` (sem download em runtime).

> Decisão sob validação na Fase 0: `docman` e `metadata_audio` precisam funcionar com URIs `content://`. Se não funcionarem, ver alternativas em `docs/PLAN.md` → Fase 0.

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
      theme.dart                 → ThemeData
  core/
    database/
      app_database.dart          → definição drift, versão do schema, migrações
      tables.dart                → tabelas
    storage/
      storage_gateway.dart       → interface: pickDirectory, pickAudioFiles, listTree, openRead, hasPermission, releasePermission
      docman_storage_gateway.dart→ implementação SAF
    metadata/
      metadata_reader.dart       → interface: read(uri) → AudioFileMetadata
      metadata_audio_reader.dart → implementação
    files/
      cover_store.dart           → salva/remove capas em <appSupport>/covers/
    utils/
      natural_sort.dart          → comparação natural de nomes
      file_names.dart            → cleanTitle, parseTrackNumber, isAudio, isImage, isPreferredCover
      duration_format.dart       → "1h 05m", "12:34", "-03:21"
  features/
    library/
      domain/                    → Book, Chapter, LibrarySource, BookSummary, SortOrder
      data/library_repository.dart
      presentation/
        library_screen.dart
        widgets/ (book_grid_item, continue_listening_item, search_field, sort_chips, empty_state, book_edit_dialog)
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
        widgets/ (mini_player, player_controls, seek_bar, cover_art)
        player_providers.dart
    chapters/
      presentation/chapters_screen.dart
    bookmarks/
      domain/bookmark.dart
      data/bookmark_repository.dart
      presentation/ (widgets usados em chapters_screen)
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

- `MainActivity` estende `AudioServiceActivity`.
- `AndroidManifest.xml`: `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `WAKE_LOCK`, `POST_NOTIFICATIONS`; service e receiver do audio_service conforme documentação do pacote.
- `applicationId`: `dev.alexandre.echoes`.
- Nome exibido: `Echoes`. Ícone: reaproveitar `assets/images/icon.png` e os ícones adaptativos da versão antiga (`git show main:assets/images/...`).
