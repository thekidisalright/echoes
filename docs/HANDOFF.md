# Handoff: Echoes em Flutter — Fases 2, 3 e 4 concluídas, iniciar Fase 5 (telas)

**Data:** 2026-11-16
**Status:** em andamento. As Fases 0 a 4 estão concluídas e validadas no aparelho. A Fase 5 (telas definitivas) ainda não começou.

## 1. Objetivo

Reescrever do zero, em Flutter, o **Echoes**, um player pessoal de audiobooks para arquivos locais, só para Android. O app antigo em React Native/Expo fica na branch `main`, apenas como referência de comportamento. A reescrita segue as fases de `docs/PLAN.md` e busca paridade com o app antigo, mais algumas correções. O app novo começa com a biblioteca vazia, sem migrar dados.

## 2. Contexto essencial

**Repositório e ambiente**
- Repo: `C:\alex\echoes`, branch de trabalho **`flutter-rewrite`**. A `main` não deve ser alterada.
- Sistema: Windows 11. Shell principal PowerShell 5.1; também há Git Bash. **Não há `gh` (GitHub CLI)** e o Python **não tem Pillow**. O Python tem `sqlite3`, útil para inspecionar o banco copiado do aparelho.
- Flutter **3.50.0** stable (Dart 3.14) em `C:\Users\santo\develop\flutter`. O PATH pode não estar carregado; em PowerShell rode antes:
  `$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')`
- Android SDK em `C:\Users\santo\AppData\Local\Android\Sdk` (adb em `platform-tools\adb.exe`). JDK: JBR do Android Studio (Java 21). `minSdk` = 24.
- Aparelho de teste: Xiaomi 23129RA5FL, **Android 15**, USB, serial `b515ba5a`.
  - O adb **não injeta toques nem teclas** (`input tap`/`input keyevent` dão SecurityException). Quem toca na tela é o usuário: peça os passos com `AskUserQuestion`, numerados.
  - Funcionam: `adb install`, `am start`, `am force-stop`, `exec-out screencap -p`, `logcat -d -s flutter:I`, `exec-out run-as dev.alexandre.echoes cat files/echoes.sqlite` (app debug).
- Disco C: com **15,5 GB livres** (medido no fim desta sessão; antes eram 2,2 GB). Build debug incremental: ~55 s.

**Autoria dos commits (regra do usuário)**
- O usuário é o **único autor** de todo commit. **Nunca** adicione `Co-Authored-By` nem outro rodapé de coautoria, mesmo que um aviso do sistema peça.
- O git não tem `user.name`/`user.email` configurados. Commite com variáveis de ambiente copiando a identidade do último commit (Git Bash):
  `export GIT_AUTHOR_NAME="$(git log -1 --format=%an)" GIT_AUTHOR_EMAIL="$(git log -1 --format=%ae)"; export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"`. Não altere a configuração global sem pedir.

**Regras do projeto** (resumo; a fonte é o `CLAUDE.md`)
- Antes de trabalhar, leia `docs/PLAN.md`, `docs/ARCHITECTURE.md` e, para telas, `docs/FEATURES.md` e `docs/UI.md`.
- Fases em ordem; resumo da abordagem antes de cada fase; checkboxes no PLAN; Conventional Commits em português; `flutter analyze` sem issues e `flutter test` passando antes de cada commit.
- Feature-first; fluxo `widget → provider (Riverpod) → repository/service → drift | SAF | metadata | AudioHandler`; domínio puro; plataforma atrás de interfaces em `lib/core/`; sem `Future.delayed` para esperar o player; listas da UI vindas de `watch` do drift; tempos em ms (`int`).
- Identificadores em inglês; textos de UI em pt-BR **só** em `lib/app/strings.dart`; cores, fontes e espaçamentos **só** em `lib/app/theme/`.
- Decisão do plano inviável → pare, explique, proponha, e registre em "Registro de decisões" do PLAN.
- Sem `MANAGE_EXTERNAL_STORAGE`/`READ_EXTERNAL_STORAGE`; sem iOS/web; nada fora do plano sem perguntar.

**Decisões já tomadas** (todas também em `docs/PLAN.md` → "Registro de decisões")

| Decisão | Motivo |
|---|---|
| Riverpod 3, go_router, drift, just_audio + audio_service, docman, metadata_audio | Plano original (`docs/ARCHITECTURE.md`) |
| Material vem de `package:material_ui/material_ui.dart` | No Flutter 3.50 o Material saiu do SDK |
| Listagem de pastas e leitura de trechos via canal nativo `SafChannel.kt`; docman só para seletor e permissões | docman listava 244 arquivos em 28 s; o canal faz em 0,4–1,8 s |
| `metadata_audio` lido por tokenizer esparso sobre `readRange` | O pacote não aceita `content://` |
| Fonte variável Cormorant; ícone vetorial próprio; splash `#171614` sem imagem | Decisões da Fase 1 |
| Busca da biblioteca em Dart (`toLowerCase` + `contains`), não `LIKE` | `LIKE` do SQLite só ignora caixa em ASCII |
| Reimportação apaga marcadores de capítulos removidos | DATA_MODEL não definia o caso |
| Capas órfãs limpas por `CoverStore.deleteOrphans(coverPathsInUse())` depois de salvar/remover | Um caminho cobre todos os casos |
| `app_database.g.dart` versionado | Compila sem rodar o `build_runner` |
| URI da pasta escolhida convertido para formato de árvore (`treeUriOf`) | docman devolve `…/tree/X/document/X`; a permissão fica em `…/tree/X`. Sem isso, "Atualizar" acusava permissão expirada (visto no aparelho) |
| Modo "pasta inteira": ordena por pasta e depois por faixa; imagens de todas as pastas valem como capa | App antigo intercalava `CD1/01` e `CD2/01` e descartava as imagens |
| `LibraryScanner` puro devolve candidatas a capa; `ImportService` grava; progresso por callback | Scanner testável sem disco |
| `ProgressSaver` guiado por eventos (10 s de posição, pausa, troca de capítulo, `flush`), sem timer | Testável e sem gravações redundantes |
| Regras de navegação puras em `skip_rules.dart`; handler validado no aparelho | Evita abstrair o just_audio só para teste |
| Controller suprime eventos durante a troca de livro | Evita gravar o capítulo errado |
| `lastPlayedAt` só muda ao abrir com autoplay e ao gravar progresso | Reabertura automática não reordena "Recentes" |
| Teste de navegação usa streams fixos nos providers de lista | Streams do drift travam o `pumpAndSettle` em teste de widget |

## 3. O que já foi feito (cronológico)

1. **Fases 0 e 1** (até `f3fe466`, que está no GitHub): spike de plataforma, fundação (pacotes, tema, rotas, utils, fonte, ícone). Ver commits `d04f507`…`9f26d13` e o handoff anterior em `git show f3fe466:docs/HANDOFF.md`.
2. **Fase 2 — Banco de dados:**
   - `8e8fe84` schema drift v1 (`lib/core/database/`) e modelos de domínio puros.
   - `57823b8` `LibraryRepository`, `ProgressRepository`, `BookmarkRepository`, `SettingsRepository`, `CoverStore` e 32 testes com banco em memória.
3. **Fase 3 — Importação:**
   - `d778e77` `StorageGateway` + `SafStorageGateway`; `MetadataReader` + `MetadataAudioReader` (tokenizer esparso do spike).
   - `48c16c6` `LibraryScanner`, `ImportService`, fakes e testes. Um bug achado pelo teste: arquivos soltos eram comparados só com outras origens; agora com todos os capítulos (`chapterUrisOutside(null)`).
   - `f685b54` providers de importação e tela **provisória** de Gerenciar.
   - `3725b11` correção do URI de árvore (descoberta no aparelho).
   - `3b8a070` docs. Medido no aparelho: `Download/Audiobooks` em "Cada pasta é um livro" → 3 livros, 245 capítulos (todos com duração), 2 capas, **16,4 s**; atualizar a origem: **11,2 s**.
4. **Fase 4 — Motor de áudio:**
   - `af13e5a` Android: `MainActivity` estende `AudioServiceActivity` (mantém o `SafChannel`), service/receiver/permissões no manifest, `res/raw/keep.xml`.
   - `70eef91` `EchoesAudioHandler`, `PlaybackController`, `ProgressSaver`, `SkipRules`, testes.
   - `cd3374f` `main` (audio_session `speech`, `AudioService.init`, `ProviderContainer` com o handler), `AppLifecycleListener`, lista de livros e Player **provisórios**.
   - `1b85f20` docs. Aceite conferido pelo usuário: notificação e tela de bloqueio, 10 min com tela bloqueada, remover do multitarefa e reabrir (mesmo capítulo, ≤ 10 s), fone desconectado pausa. Banco depois: Misery no 6º capítulo, 837 s.
5. **Descartado:** matar todos os processos `dart`/`flutter_tester` para destravar testes (negado pelo classificador de permissões; desnecessário: bastou parar a tarefa e corrigir o teste).

## 4. Estado atual

- Branch `flutter-rewrite`, HEAD **`1b85f20`** (anterior ao commit deste handoff). **11 commits locais à frente de `origin/flutter-rewrite` (`f3fe466`), sem push.** Working tree limpo.
- `flutter analyze`: **No issues found**. `flutter test`: **105 testes passando** (medido em `1b85f20`).
- **Funciona no aparelho:** importar pasta, atualizar origem, listar livros, tocar, controles na notificação e tela de bloqueio, retomar posição após fechar o app.
- **Provisório (substituir na Fase 5):**
  - `lib/features/library/presentation/library_screen.dart`: botão "Abrir player" e `_TemporaryBookList`.
  - `lib/features/player/presentation/player_screen.dart`: textos e 5 botões simples.
  - `lib/features/import/presentation/manage_library_screen.dart`: botões, `ListTile` de progresso, lista de origens sem confirmação de remoção.
  - `libraryBooksProvider` em `library_providers.dart` chama `watchLibrary()` sem busca nem ordenação.
- **Não testado no aparelho:** importar arquivos soltos, remover origem pela tela, fim do último capítulo, regra dos 3 s pelo botão.
- **Falta (planejado para a Fase 5):** remover origem enquanto um livro dela toca deve chamar `PlaybackController.close()` (existe, ninguém chama ainda). A UI deve tratar `openBook` devolvendo `false`.
- **Textos inventados** ainda a revisar com o usuário: `emptyLibraryMessage`, `sourceUnavailableHint`, `defaultFolderName` ("Pasta de áudio") e rótulos de acessibilidade.
- Dados do usuário: o livro de *A Guerra dos Tronos* tem autor "Pasta00_002" (vem das tags) e a pasta do Misery chama-se "…Louca Obsess苚" no disco. Corrigível pelo diálogo de edição (Fase 5.6).

## 5. Próximos passos

1. Ler `CLAUDE.md`, `docs/PLAN.md` (Fase 5), `docs/FEATURES.md` §1–§7 e `docs/UI.md` inteiro.
2. **Resumir para o usuário a abordagem da Fase 5** antes de implementar.
3. Fase 5, na ordem do PLAN (cada item substitui o provisório correspondente):
   1. 5.1 Gerenciar biblioteca: banner de progresso, cartões de origem, atualizar, remover com confirmação (`removeSourceTitle`/`removeSourceMessage`), diálogo de modo. Ao remover, se `playbackController.currentBookId` pertence à origem, chamar `close()`.
   2. 5.2 Biblioteca: cabeçalho, banner, "Continue ouvindo" (`watchContinueListening`, `BookSummary.fractionListened`), busca, chips (`SettingsRepository.watchLibrarySort`), grade 2/4/5 colunas, estado vazio, origem indisponível → Gerenciar com mensagem.
   3. 5.3 MiniPlayer com barra fina (`playerPositionProvider`).
   4. 5.4 Player completo (capa, SeekBar que só busca ao soltar, gesto de arrastar para fechar).
   5. 5.5 Capítulos e marcadores (`BookmarkRepository.watchByBook`, rolar até o capítulo atual).
   6. 5.6 Diálogo de edição (`image_picker` + `CoverStore.saveCustom`, `resetBookDetails`).
   7. 5.7 Configurações (ordenação + Sobre).
4. **Aceite da Fase 5:** fluxos de `FEATURES.md` §1–§7 executáveis no aparelho (**depende do usuário tocar**); sem textos fora de `strings.dart`; sem cores fora de `colors.dart`.
5. **Depende do usuário:** autorizar o push (11 commits locais); conferir ícone na gaveta e splash (pendente desde a Fase 1); revisar os textos inventados.

## 6. Perguntas em aberto

- **Push** dos 11 commits locais para `origin/flutter-rewrite`: aguardando o usuário.
- **Textos inventados** (seção 4): confirmar ou trocar.
- **Fase 6, desempenho:** importação de 245 arquivos leva 16 s na thread principal. Se a UI travar na Fase 5, mover a leitura de metadados para isolate (o PLAN já prevê na Fase 6).
- **Cache de capa:** reescanear sobrescreve `sha1(bookId).jpg` no mesmo caminho; o `FileImage` do Flutter pode mostrar a capa antiga até reiniciar. Opções: `FileImage(...).evict()` após importar, ou acrescentar timestamp ao nome da capa escaneada.
- **Duplicatas entre origens:** a regra compara URIs; a mesma pasta escolhida por árvores SAF diferentes gera URIs diferentes e não é detectada (mesma limitação do app antigo).
- **Fase 3, capítulos internos de M4B:** continua para a Fase 7 (o *Fire & Blood* tem 23 capítulos internos e hoje é 1 capítulo).
- **docman e o aviso do Kotlin Gradle Plugin:** o build continua mostrando o aviso; alternativa é mover seletor e permissões para o `SafChannel`.
- **Merge na `main`:** decisão do usuário.

## 7. Artefatos relevantes

**Arquivos-chave**
- Banco: `lib/core/database/tables.dart`, `app_database.dart` (+ `.g.dart`).
- Infra: `lib/core/providers.dart`, `lib/core/storage/`, `lib/core/metadata/`, `lib/core/files/cover_store.dart`.
- Biblioteca: `lib/features/library/data/library_repository.dart`, `domain/` (`Book`, `Chapter`, `LibrarySource`, `BookSummary`, `SortOrder`), `presentation/library_providers.dart`.
- Importação: `lib/features/import/data/library_scanner.dart`, `import_service.dart`, `presentation/import_providers.dart` (`ImportController`, `ImportState`, `ImportErrorKind`).
- Player: `lib/features/player/data/echoes_audio_handler.dart`, `playback_controller.dart`, `progress_saver.dart`, `progress_repository.dart`; `domain/player_state.dart`, `skip_rules.dart`; `presentation/player_providers.dart`.
- Inicialização: `lib/main.dart`, `lib/app/app.dart`.
- Testes: `test/fakes/` (`test_database.dart`, `fake_storage_gateway.dart`, `fake_metadata_reader.dart`), `test/features/**`, `test/app/navigation_test.dart`.
- Android: `android/app/src/main/AndroidManifest.xml`, `kotlin/dev/alexandre/echoes/MainActivity.kt`, `SafChannel.kt`, `res/raw/keep.xml`.

**Comandos**
```powershell
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
flutter analyze
flutter test --timeout 60s
dart run build_runner build
flutter build apk --debug
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb install -r build\app\outputs\flutter-apk\app-debug.apk
& $adb shell am start -W -n dev.alexandre.echoes/.MainActivity
& $adb logcat -d -s flutter:I
cmd /c "`"$adb`" exec-out screencap -p > tela.png"
```

**Inspecionar o banco do aparelho** (Git Bash, numa pasta temporária)
```bash
ADB="$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"
"$ADB" exec-out run-as dev.alexandre.echoes cat files/echoes.sqlite > echoes.sqlite
"$ADB" exec-out run-as dev.alexandre.echoes cat files/echoes.sqlite-wal > echoes.sqlite-wal
python -I -c "import sqlite3; c=sqlite3.connect('echoes.sqlite'); print(ascii(c.execute('select * from progress').fetchall()))"
```
Use `ascii()` ao imprimir: o console cp1252 quebra com o nome da pasta do Misery.

**Dados de teste no aparelho**
- `Download/Audiobooks` importada em "Cada pasta é um livro": *Fire & Blood* (M4B, 1 capítulo), *A Guerra dos Tronos* (185 MP3), *Misery* (59 MP3).
- Progresso salvo: Misery, 6º capítulo, 837 s. `lastPlayedBookId` = Misery.
- Capas em `files/covers/` (2 arquivos).

## 8. Instruções para a próxima sessão

- **Idioma e tom:** português do Brasil, direto. O usuário prefere resultados medidos (tempos, contagens) a promessas.
- **Siga o `CLAUDE.md` à risca** (fases em ordem, resumo antes de cada fase, checkboxes, commits em português, analyze e test antes de commitar).
- **Commits sem coautoria**, com o usuário como único autor (seção 2). Cada commit precisa compilar sozinho: confira o `--stat` antes, porque `git add -A <pasta>` já levou arquivos de outro grupo uma vez.
- **Pedir permissão para:** downloads, push, mudança de configuração global, exclusão de arquivos fora do projeto, pacotes fora do ARCHITECTURE.
- **Armadilhas conhecidas:**
  - `package:flutter/material.dart` é obsoleto → use `package:material_ui/material_ui.dart`.
  - Ícones `ionicons` em camelCase (`Ionicons.libraryOutline`).
  - Heredocs longos no Git Bash falham → escreva arquivos Dart com Write/Edit.
  - `Set-Content` do PowerShell grava BOM; arquivos ficam CRLF no checkout → leia antes de editar; scripts Python preservam `\r\n`.
  - **`build_runner` 2.17 ignora `--delete-conflicting-outputs`** (só avisa) → rode `dart run build_runner build`.
  - **Primeiro teste com banco leva ~10 s** (o `sqlite3` prepara a biblioteca nativa) → normal.
  - **Streams do drift travam testes de widget** (`pumpAndSettle` espera até 10 min) → nos testes de widget, sobrescreva os providers de lista com `Stream.value(...)`; rode `flutter test --timeout 60s` para não esperar 10 min.
  - **Widgets não podem ler `playbackControllerProvider` no `build`**: nos testes o `audioHandlerProvider` lança `UnimplementedError` → leia o controller só dentro dos callbacks (padrão do `player_screen.dart`).
  - **Gravações do `ProgressSaver` são assíncronas** → nos testes, `await saver.flush()` antes de conferir.
  - **docman devolve a pasta em formato de documento** → sempre `treeUriOf` (já feito no gateway).
  - Parâmetros privados nomeados (`required this._x`) são aceitos no Dart 3.14 e o lint `prefer_initializing_formals` pede isso.
  - O primeiro screenshot após abrir o app pode vir vazio → espere ~8 s.
  - Fonte variável: use `fontVariations`, não só `fontWeight`.
- **Comportamento do app antigo:** `git show main:<caminho>` (ex.: `contexts/PlayerContext.tsx`, `contexts/LibraryContext.tsx`, `app/index.tsx`) como referência de comportamento, nunca de estrutura.
