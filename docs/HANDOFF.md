# Handoff: Echoes em Flutter — Fase 5 aceita com 4 pendências, depois Fase 6

**Data:** 2026-11-16
**Status:** em andamento. As Fases 0 a 5 estão concluídas. O usuário aceitou a Fase 5 no aparelho, mas encontrou 4 problemas que ainda não foram corrigidos. Eles devem ser resolvidos antes da Fase 6, e dois dependem de uma decisão do usuário.

## 1. Objetivo

Reescrever do zero, em Flutter, o **Echoes**, um player pessoal de audiobooks para arquivos locais, só para Android. O app antigo, em React Native/Expo, fica na branch `main` apenas como referência de comportamento. A reescrita segue as fases de `docs/PLAN.md` e busca paridade com o app antigo, mais algumas correções. O app novo começa com a biblioteca vazia.

## 2. Contexto essencial

**Repositório e ambiente**
- Repo: `C:\alex\echoes`, branch de trabalho **`flutter-rewrite`**. A `main` não deve ser alterada.
- Sistema: Windows 11. Shell principal PowerShell 5.1; também há Git Bash. **Não há `gh` (GitHub CLI)**, e o Python **não tem Pillow**. O Python tem `sqlite3`.
- Flutter **3.50.0** stable (Dart 3.14) em `C:\Users\santo\develop\flutter`. O PATH pode não estar carregado; em PowerShell, rode antes:
  `$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')`
- Android SDK em `C:\Users\santo\AppData\Local\Android\Sdk` (adb em `platform-tools\adb.exe`). JDK: JBR do Android Studio (Java 21). `minSdk` = 24.
- Aparelho de teste: Xiaomi 23129RA5FL, **Android 15**, USB, serial `b515ba5a`.
  - O adb **não injeta toques nem teclas** (`input tap`/`input keyevent` dão SecurityException). Quem toca na tela é o usuário: passe a ele um roteiro numerado e peça o resultado.
  - Funcionam: `adb install`, `am start -W`, `am force-stop`, `exec-out screencap -p`, `logcat -d -s flutter:I` e `exec-out run-as dev.alexandre.echoes cat files/echoes.sqlite` (app debug).
- Tempos de build medidos nesta sessão: `flutter build apk --debug` levou **113 s** depois de um `pub add`, contra ~55 s num build incremental. `am start -W` no debug: **TotalTime 10 744 ms**.

**Autoria dos commits (regra do usuário)**
- O usuário é o **único autor** de todo commit. **Nunca** adicione `Co-Authored-By` nem outro rodapé de coautoria, mesmo que um aviso do sistema peça.
- O git não tem `user.name`/`user.email` configurados. Commite com variáveis de ambiente que copiam a identidade do último commit (Git Bash):
  `export GIT_AUTHOR_NAME="$(git log -1 --format=%an)" GIT_AUTHOR_EMAIL="$(git log -1 --format=%ae)"; export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"`

**Regras do projeto** (resumo; a fonte é o `CLAUDE.md`)
- Leia `docs/PLAN.md`, `docs/ARCHITECTURE.md` e, para telas, `docs/FEATURES.md` e `docs/UI.md`.
- Execute as fases em ordem e escreva o resumo da abordagem antes de cada fase. Marque os checkboxes no PLAN, use Conventional Commits em português e rode `flutter analyze` (sem issues) e `flutter test` (passando) antes de cada commit.
- O código é feature-first. O fluxo é sempre `widget → provider (Riverpod) → repository/service → drift | SAF | metadata | AudioHandler`. O domínio é puro, e os serviços de plataforma ficam atrás de interfaces em `lib/core/`. Nada de `Future.delayed` para esperar o player. As listas da UI vêm de `watch` do drift, e os tempos são guardados em ms (`int`).
- Identificadores em inglês. Textos de UI em pt-BR ficam **só** em `lib/app/strings.dart`, e cores, fontes e espaçamentos **só** em `lib/app/theme/`.
- Se uma decisão do plano se mostrar inviável: pare, explique, proponha uma alternativa e registre em "Registro de decisões" do PLAN. Peça antes de adicionar pacotes que não estão no ARCHITECTURE.

**Decisões já tomadas** (todas também em `docs/PLAN.md` → "Registro de decisões")

| Decisão | Motivo |
|---|---|
| Riverpod 3, go_router, drift, just_audio + audio_service, docman, metadata_audio | Plano original (`docs/ARCHITECTURE.md`) |
| Material vem de `package:material_ui/material_ui.dart` | No Flutter 3.50 o Material saiu do SDK |
| Listagem de pastas e leitura de trechos via canal nativo `SafChannel.kt` | docman listava 244 arquivos em 28 s; o canal faz em 0,4–1,8 s |
| `metadata_audio` lido por tokenizer esparso sobre `readRange` | O pacote não aceita `content://` |
| Busca da biblioteca em Dart, não `LIKE` | `LIKE` do SQLite só ignora caixa em ASCII |
| URI da pasta convertido para o formato de árvore (`treeUriOf`) | A permissão persistida fica em `…/tree/X` |
| `ProgressSaver` guiado por eventos, sem timer | Testável e sem gravações redundantes |
| **Fase 5:** falhas de importação viram alerta no `EchoesApp` (`rootNavigatorKey`) | A importação pode terminar depois de o usuário sair de Gerenciar |
| **Fase 5:** ao remover uma origem, `ImportController.remove` chama `PlaybackController.close()` se o livro carregado for dela | O MiniPlayer some e o progresso é salvo antes |
| **Fase 5:** livro com origem indisponível leva a Gerenciar com `ManageLibraryArgs(notice)` | FEATURES §2 |
| **Fase 5:** tocar num livro abre o Player **sem tocar** (`autoplay: false`) | Paridade com o app antigo |
| **Fase 5:** o botão de Temporizador do Player fica para a Fase 6 | Não exibir botão sem função |
| **Fase 5:** a rota do Player não é opaca, e o arrasto usa um `Transform` próprio | A biblioteca aparece por baixo durante o gesto |
| **Fase 5:** `AppColors.danger` (`#8C3F35`) e escala `AppSpacing.xs…xxl` | O UI.md não tinha cor destrutiva; nenhum valor solto em widget |
| **Fase 5:** `image_picker` atrás de `ImageGateway`; `package_info_plus` atrás de `AppInfo` (`lib/core/`) | Regra 4 do CLAUDE.md; o `package_info_plus` foi aprovado pelo usuário |
| **Fase 5:** a edição de livro passa pelo `BookEditor`; `PlaybackController.refreshBook` atualiza o livro carregado e a notificação | O Player e a notificação não ficam com dados velhos |
| **Fase 5:** os textos de biblioteca vazia e de busca sem resultado vêm do app antigo | Textos reais em vez de inventados |

## 3. O que já foi feito (cronológico)

1. **Fases 0 a 4** (até `7ffe751`, que já está em `origin/flutter-rewrite`): spike, fundação, banco, importação e motor de áudio. O handoff anterior está em `git show 7ffe751:docs/HANDOFF.md`.
2. **Fase 5 — Telas** (nesta sessão):
   - `247c90b` 5.1 Gerenciar: `ScreenHeader`, `dialogs.dart` (alerta e confirmação), `ImportStatusBanner`, `ImportModeDialog`, `SourceTile`, remoção com confirmação e alertas de falha no app inteiro.
   - `3c59fa7` 5.2 Biblioteca: `librarySearchProvider`, `librarySortProvider`, `continueListeningProvider`, `BookCover` (com `cacheWidth`), `BookGridItem`, `ContinueListeningItem`, `SearchField`, `SortChips`, `EmptyState` e `open_book.dart`.
   - `3c5e99d` 5.3 MiniPlayer com barra fina de progresso do capítulo.
   - `4b98953` 5.4 Player: `SeekBar` (busca só ao soltar), `PlayerControls`, marcador com o aviso "Salvo" por 1,5 s e arrastar para fechar. Também `EchoesAudioHandler.seekInChapter` e `PlaybackController.playAt`/`currentPosition`.
   - `ae5298a` 5.5 Capítulos e marcadores: rola até o capítulo atual (`jumpTo` no primeiro frame com dados) e ganhou o `formatShortDate`.
   - `65d4ee8` 5.6 Diálogo de edição: `BookEditor`, `ImageGateway`/`ImagePickerGateway`, `refreshBook` e `EchoesAudioHandler.updateItems`.
   - `cdd310d` 5.7 Configurações: radios de ordem e "Sobre" com a versão (`package_info_plus` 10.2.2).
   - `eaf1732` docs: ARCHITECTURE e 10 decisões no registro do PLAN.
3. **Testes:** passaram de 105 para **131** (26 novos: widgets das 5 telas, `SeekBar`, `MiniPlayer`, `BookEditor`, `formatShortDate`).
4. **Descartado:** nada nesta sessão.

## 4. Estado atual

- Branch `flutter-rewrite`, HEAD **`eaf1732`** (anterior ao commit deste handoff). **8 commits locais à frente de `origin/flutter-rewrite` (`7ffe751`), sem push.** O working tree só tem as mudanças deste handoff e do PLAN.
- `flutter analyze`: **No issues found**. `flutter test`: **131 testes passando** (medidos em `eaf1732`).
- Nenhum `Color(0x…)` fora de `lib/app/theme/` e nenhum `Text('…')` literal em `lib/features` (conferido com grep).
- **Aceite da Fase 5:** o usuário testou no aparelho e aceitou, **sem corrigir** os quatro problemas abaixo.

**Problemas encontrados pelo usuário no aparelho (não corrigidos)**

1. **Tocar num marcador toca no ponto certo, mas não volta ao Player.**
   - Causa provável, não verificada no aparelho: `PlaybackController.playAt` (e também `playChapter`) faz `await play()`. Com o just_audio, o `Future` de `AudioPlayer.play()` só termina quando a reprodução **pausa ou para**, então o `context.pop()` em `ChaptersScreen._openBookmark`/`_playChapter` nunca roda.
   - Tocar num capítulo provavelmente tem o mesmo defeito; o usuário não relatou nem foi conferido. `openBook(autoplay: true)` e `restoreLastBook` também fazem `await play()` (linhas 77 e 112 de `playback_controller.dart`).
   - Correção sugerida: `unawaited(_handler.play())` em `playAt`/`playChapter`, ou não aguardar o `play` na tela. Acrescente um teste que garanta que esses métodos terminam.
2. **Arrastar o Player para baixo não funciona na maioria dos livros**, mas funcionou com o livro de arquivo solto.
   - Causa provável, não verificada: em `player_screen.dart`, o conteúdo está num `SingleChildScrollView` dentro do `GestureDetector(onVerticalDrag…)`. Quando o conteúdo é mais alto que a tela (título em 2 linhas, nomes longos, capa de 45% da altura), o `Scrollable` ganha a disputa pelo arrasto vertical. O livro de arquivo solto provavelmente cabia na tela, sem rolagem.
   - Opções: (a) layout que caiba sem rolar (`NeverScrollableScrollPhysics`, com a capa encolhendo); (b) fechar pelo overscroll no topo (`NotificationListener<OverscrollNotification>` com o offset em 0); (c) aceitar o arrasto só no cabeçalho e na capa.
3. **Em Gerenciar biblioteca não dá para diferenciar as origens de arquivos selecionados.** Todas se chamam "Arquivos selecionados" (`AppStrings.selectedFilesSourceName`, como pede FEATURES §1.2). **Precisa de decisão do usuário** (seção 6).
4. **Não há splash nem tela de carregamento enquanto o app abre.**
   - Hoje a janela fica com o fundo `#171614` sem imagem (decisão da Fase 1), e o `main` aguarda `AudioSession` e `AudioService.init` antes do `runApp`.
   - No debug, `am start -W` mediu 10,7 s, o que inclui a inicialização em modo JIT; o release deve ser bem mais rápido, mas ainda não foi medido. **Precisa de decisão do usuário** (seção 6).

**Outras observações**
- Na grade aparece "1 capítulos" (*Fire & Blood*). O texto `"{n} capítulos"` vem do FEATURES, e o app antigo fazia o mesmo. É uma correção trivial se o usuário quiser.
- **Textos inventados** ainda a revisar com o usuário: `sourceUnavailableHint`, `defaultFolderName` ("Pasta de áudio"), `openBookError`, `editBookError` e os rótulos de acessibilidade.
- **Não testado no aparelho:** importar arquivos soltos funcionou (o usuário adicionou um). Não foram conferidos: remover origem enquanto toca, fim do último capítulo, a regra dos 3 s pelo botão, tocar num capítulo da lista e restaurar dados originais.

## 5. Próximos passos

1. Ler `CLAUDE.md`, `docs/PLAN.md` (Fase 6) e este handoff.
2. **Corrigir as pendências da Fase 5**, uma por commit `fix(...)`:
   1. Marcador e capítulo voltam ao Player (problema 1). Aceite: no aparelho, o toque toca e volta ao Player; teste unitário ou de widget cobrindo o retorno.
   2. Arrastar para fechar em qualquer livro (problema 2). Aceite: funciona com *A Guerra dos Tronos* e *Misery*, sem quebrar a rolagem em telas pequenas.
   3. **Depende do usuário:** como diferenciar as origens de arquivos (problema 3).
   4. **Depende do usuário:** splash ou tela de carregamento (problema 4).
3. Reinstalar e pedir ao usuário que confira os itens corrigidos (roteiro numerado).
4. **Fase 6**, na ordem do PLAN: `SleepTimerService` + folha inferior + botão no Player ("Timer ativo"/"Timer · 12 min"), marcadores (já existem; revisar contra FEATURES), animações, acessibilidade, desempenho (importação de 245 arquivos em 16 s na thread principal), build release assinado. Comece pelo resumo da abordagem.
5. **Depende do usuário:** autorizar o push dos 9 commits locais (8 da Fase 5 mais este handoff).

## 6. Perguntas em aberto

- **Origens de arquivos com o mesmo nome:** (a) mostrar o título do livro da origem no lugar de "Arquivos selecionados"; (b) acrescentar a data da importação (`lastScannedAt`) ao subtítulo; (c) usar o nome do primeiro arquivo; (d) permitir renomear a origem. As opções (a) e (c) mudam o que FEATURES §1.2 diz.
- **Splash:** (a) splash nativo do Android 12+ com o ícone vetorial (`windowSplashScreenAnimatedIcon`, mudando a decisão da Fase 1); (b) mostrar logo um primeiro frame Flutter com "Echoes" e um spinner enquanto o áudio inicializa; (c) medir antes no release (Fase 6) e decidir depois.
- **Push** dos commits locais para `origin/flutter-rewrite`: aguardando o usuário.
- **Textos inventados** (seção 4): confirmar ou trocar.
- **Cache de capa:** reescanear sobrescreve `sha1(bookId).jpg` no mesmo caminho, e o `FileImage` pode mostrar a capa antiga até o app reiniciar. Opções: `FileImage(...).evict()` depois de importar, ou um timestamp no nome da capa escaneada. As capas personalizadas já usam timestamp.
- **Duplicatas entre origens**, **capítulos internos de M4B** (Fase 7), **aviso do Kotlin Gradle Plugin do docman** e **merge na `main`**: sem mudança desde o handoff anterior.

## 7. Artefatos relevantes

**Arquivos-chave da Fase 5**
- Compartilhados: `lib/app/widgets/screen_header.dart`, `lib/app/widgets/dialogs.dart`, `lib/app/router.dart` (`rootNavigatorKey`, `ManageLibraryArgs`, Player com `opaque: false`), `lib/app/app.dart` (alertas de importação).
- Gerenciar: `lib/features/import/presentation/manage_library_screen.dart`, `widgets/{import_status_banner,import_mode_dialog,source_tile}.dart`.
- Biblioteca: `lib/features/library/presentation/{library_screen,library_providers,open_book}.dart`, `widgets/{book_cover,book_grid_item,continue_listening_item,search_field,sort_chips,empty_state,book_edit_dialog}.dart`, `data/book_editor.dart`.
- Player: `lib/features/player/presentation/player_screen.dart` (arrasto: `_onDragUpdate`/`_onDragEnd`), `widgets/{mini_player,seek_bar,player_controls}.dart`. Controller: `playAt`, `playChapter`, `refreshBook`, `currentPosition`.
- Capítulos: `lib/features/chapters/presentation/chapters_screen.dart` (`_openBookmark`, `_playChapter`).
- Marcadores: `lib/features/bookmarks/presentation/bookmark_providers.dart` (`currentBookmarksProvider`).
- Configurações: `lib/features/settings/presentation/{settings_screen,settings_providers}.dart` (`librarySortProvider`, `appVersionProvider`).
- Plataforma: `lib/core/images/`, `lib/core/app_info/`, `lib/core/providers.dart`.

**Comandos**
```powershell
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
dart format lib test
flutter analyze
flutter test --timeout 60s
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

**Dados de teste no aparelho**
- `Download/Audiobooks` em "Cada pasta é um livro": *Fire & Blood* (M4B, 1 capítulo, 26h 24m), *A Guerra dos Tronos* (185 MP3) e *Misery* (59 MP3, 13h 03m, sem capa, autor vazio).
- Uma origem de arquivo solto, adicionada pelo usuário nesta sessão.
- O usuário pode ter editado livros e criado marcadores durante o teste: confira o banco antes de supor o estado.

## 8. Instruções para a próxima sessão

- **Idioma e tom:** português do Brasil, direto. O usuário prefere resultados medidos (tempos, contagens) a promessas, e relata o teste no aparelho em tópicos curtos.
- **Siga o `CLAUDE.md` à risca.** Commits **sem coautoria** (seção 2). Antes de commitar, confira o `git status --short`, porque `dart format lib test` pode reformatar arquivos de commits anteriores.
- **Peça permissão para:** downloads, push, mudança de configuração global, exclusão de arquivos fora do projeto e pacotes que não estão no ARCHITECTURE.
- **Armadilhas conhecidas:**
  - **`AudioPlayer.play()` do just_audio só termina quando a reprodução para**: nunca dê `await` nele antes de navegar ou de continuar um fluxo de UI. Foi a causa provável do problema 1.
  - **`GestureDetector` vertical em volta de um `Scrollable` perde o arrasto** quando há rolagem. Foi a causa provável do problema 2.
  - Os testes de widget **não podem ler `playbackControllerProvider` no `build`**: o `audioHandlerProvider` lança `UnimplementedError`. Leia o controller só nos callbacks.
  - **Os streams do drift travam testes de widget** (`pumpAndSettle`). Sobrescreva com `Stream.value(...)` **todos** os providers de stream que a tela usa: `libraryBooksProvider`, `continueListeningProvider`, `librarySortProvider`, `sourcesProvider`, `playerStateProvider`, `playerPositionProvider`, `currentBookmarksProvider`. Rode `flutter test --timeout 60s`.
  - **Notifier do Riverpod 3 não aceita `..state = x` no `overrideWith`** ("uninitialized state"). Crie uma subclasse com `build()` devolvendo o valor (ver `_FixedSearch` em `library_screen_test.dart`).
  - **Trocar os overrides de um `ProviderScope` com um segundo `pumpWidget` não atualiza o stream**: faça testes separados.
  - **Rolar até um item numa lista que chega por stream**: o `initialScrollOffset` no `initState` não serve, porque o valor ainda não chegou. Role no primeiro `build` com dados, com `addPostFrameCallback` + `jumpTo`.
  - `find.text('Autor')` acha o rótulo do campo e também o valor: use valores distintos nos testes.
  - `package:flutter/material.dart` está obsoleto → use `package:material_ui/material_ui.dart`. Os ícones do `ionicons` são em camelCase.
  - Heredocs longos no Git Bash falham → escreva arquivos Dart com Write/Edit; scripts Python preservam `\r\n`.
  - **`build_runner` 2.17 ignora `--delete-conflicting-outputs`** → rode `dart run build_runner build`.
  - **docman devolve a pasta em formato de documento** → sempre `treeUriOf` (já feito no gateway).
  - O primeiro screenshot após abrir o app pode vir vazio → espere ~8 s.
  - Fonte variável: use `fontVariations`, não só `fontWeight`.
- **Comportamento do app antigo:** use `git show main:<caminho>` (ex.: `app/index.tsx`, `app/directories.tsx`, `components/BookItem.tsx`) como referência de comportamento, nunca de estrutura.
